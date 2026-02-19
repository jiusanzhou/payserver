import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../data/datasources/database.dart';
import '../data/api/payserver_api.dart';
import 'entities/transaction.dart';
import 'entities/server.dart';

/// Service to handle notification listening and payment detection
class NotificationService {
  final Ref ref;
  StreamSubscription<NotificationEvent>? _subscription;
  bool _isListening = false;

  NotificationService(this.ref);

  bool get isListening => _isListening;

  /// Start listening to notifications
  Future<bool> startListening() async {
    if (_isListening) return true;

    // Check permission
    final hasPermission =
        await NotificationsListener.hasPermission ?? false;
    if (!hasPermission) {
      // Request permission - this will open settings
      await NotificationsListener.openPermissionSettings();
      return false;
    }

    // Initialize listener
    await NotificationsListener.initialize(callbackHandle: _notificationCallback);

    // Subscribe to events
    _subscription = NotificationsListener.receiveNotification?.listen(
      _handleNotification,
      onError: (e) => debugPrint('Notification error: $e'),
    );

    _isListening = true;
    return true;
  }

  /// Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  /// Handle incoming notification
  Future<void> _handleNotification(NotificationEvent event) async {
    debugPrint('Received notification: ${event.packageName} - ${event.title}');

    // Try to parse as payment
    final transaction = PayTransaction.fromEvent(event);
    if (transaction == null) {
      debugPrint('Not a payment notification');
      return;
    }

    debugPrint('Detected payment: ${transaction.type.name} ¥${transaction.value}');

    // Save to local database
    await _saveTransaction(transaction);

    // Upload to server
    await _uploadTransaction(transaction);
  }

  Future<void> _saveTransaction(PayTransaction transaction) async {
    try {
      final db = ref.read(databaseProvider);
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: transaction.type.toText(),
              value: transaction.value,
              amount: transaction.amount,
              timestamp: Value(transaction.timestamp),
              createAt: Value(transaction.createAt?.millisecondsSinceEpoch),
              status: Value(0),
              raw: Value(transaction.raw),
            ),
          );
      debugPrint('Transaction saved to local DB');
    } catch (e) {
      debugPrint('Failed to save transaction: $e');
    }
  }

  Future<void> _uploadTransaction(PayTransaction transaction) async {
    try {
      // Get current server and agent UID
      // This would come from your provider setup
      // For now, we'll just log it
      debugPrint('Would upload transaction to server');

      // TODO: Get server and agentUid from providers
      // final server = ref.read(currentServerProvider);
      // final agentUid = ref.read(agentUidProvider);
      // if (server != null && agentUid != null) {
      //   final api = PayServerApi(server: server, agentUid: agentUid);
      //   final result = await api.uploadRecord(transaction);
      //   if (result.isSuccess) {
      //     // Update status to uploaded
      //   }
      // }
    } catch (e) {
      debugPrint('Failed to upload transaction: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
  }
}

/// Background callback for notification listener
@pragma('vm:entry-point')
void _notificationCallback() {
  // This runs in isolate, minimal work here
  debugPrint('Notification callback triggered');
}

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for listening state
final isListeningProvider = StateProvider<bool>((ref) => false);
