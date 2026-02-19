import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:drift/drift.dart';

import '../../data/api/payserver_api.dart';
import '../../data/datasources/database.dart';
import '../../domain/entities/transaction.dart';
import '../../presentation/providers/server_provider.dart';

/// Background task names
const heartbeatTaskName = 'payserver.heartbeat';
const syncTaskName = 'payserver.sync';
const _isolatePortName = '_payserver_listener_';

/// Initialize background work manager
Future<void> initBackgroundService() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  // Register periodic heartbeat (every 15 minutes)
  await Workmanager().registerPeriodicTask(
    heartbeatTaskName,
    heartbeatTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task: $task');

    switch (task) {
      case heartbeatTaskName:
        // Send heartbeat to server
        // This would need proper initialization in isolate
        return true;
      case syncTaskName:
        // Sync pending transactions
        return true;
      default:
        return true;
    }
  });
}

/// Static callback for notification listener (runs in background isolate)
@pragma('vm:entry-point')
void _notificationCallback(NotificationEvent evt) {
  debugPrint('Notification received in background: ${evt.packageName}');

  // Try to send to UI thread
  final SendPort? send = IsolateNameServer.lookupPortByName(_isolatePortName);
  send?.send(evt);
}

/// Service to manage notification listening and sync
class PaymentListenerService {
  final Ref ref;
  ReceivePort? _receivePort;
  StreamSubscription? _receivePortSubscription;
  StreamSubscription? _pluginPortSubscription;
  Timer? _heartbeatTimer;
  bool _isRunning = false;

  PaymentListenerService(this.ref);

  bool get isRunning => _isRunning;

  /// Start the payment listener service
  Future<bool> start() async {
    if (_isRunning) return true;

    // Check notification permission
    final hasPermission = await NotificationsListener.hasPermission ?? false;
    if (!hasPermission) {
      NotificationsListener.openPermissionSettings();
      return false;
    }

    // Initialize notification listener with static callback
    NotificationsListener.initialize(callbackHandle: _notificationCallback);

    // Clean up existing port mapping and subscriptions
    _cleanupPorts();

    // Setup receive port to get events from background isolate
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      _isolatePortName,
    );

    // Listen to events from our custom isolate port
    _receivePortSubscription = _receivePort!.listen((dynamic evt) {
      if (evt is NotificationEvent) {
        _onNotification(evt);
      }
    });

    // Note: We don't listen to NotificationsListener.receivePort here
    // because it's a single-subscription stream that may already be listened to.
    // The plugin's static callback (_notificationCallback) sends events to our
    // custom isolate port via IsolateNameServer, so we only need to listen there.

    // Start the service
    final isRunning = await NotificationsListener.isRunning ?? false;
    if (!isRunning) {
      await NotificationsListener.startService(
        foreground: true,
        title: '易付收款监听',
        description: '正在监听支付通知',
      );
    }

    // Start heartbeat timer (every 3 minutes)
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 3),
      (_) => _sendHeartbeat(),
    );

    _isRunning = true;
    debugPrint('Payment listener service started');
    return true;
  }

  /// Clean up ports and subscriptions
  void _cleanupPorts() {
    _receivePortSubscription?.cancel();
    _receivePortSubscription = null;
    _pluginPortSubscription?.cancel();
    _pluginPortSubscription = null;
    _receivePort?.close();
    _receivePort = null;
    IsolateNameServer.removePortNameMapping(_isolatePortName);
  }

  /// Stop the service
  void stop() {
    _cleanupPorts();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    NotificationsListener.stopService();
    _isRunning = false;
    debugPrint('Payment listener service stopped');
  }

  /// Handle incoming notification
  Future<void> _onNotification(NotificationEvent event) async {
    debugPrint('Notification received: ${event.packageName}');

    // Parse payment from notification
    final transaction = PayTransaction.fromEvent(event);
    if (transaction == null) {
      debugPrint('Not a payment notification, ignoring');
      return;
    }

    debugPrint('Payment detected: ${transaction.type.displayName} ¥${transaction.value}');

    // Save to local database
    await _saveToDatabase(transaction);

    // Upload to server
    await _uploadToServer(transaction);
  }

  Future<void> _saveToDatabase(PayTransaction transaction) async {
    try {
      final db = ref.read(databaseProvider);
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: transaction.type.toText(),
              value: transaction.value,
              amount: transaction.amount,
              timestamp: Value(transaction.timestamp),
              createAt: Value(transaction.createAt?.millisecondsSinceEpoch),
              status: const Value(0), // Pending
              raw: Value(transaction.raw),
            ),
          );
      debugPrint('Transaction saved to local database');
    } catch (e) {
      debugPrint('Failed to save transaction: $e');
    }
  }

  Future<void> _uploadToServer(PayTransaction transaction) async {
    try {
      final server = ref.read(currentServerProvider);
      if (server == null) {
        debugPrint('No server configured, skipping upload');
        return;
      }

      // Get agent UID from server registration
      final agentUid = server.uid;
      if (agentUid.isEmpty) {
        debugPrint('Agent not registered, skipping upload');
        return;
      }

      final api = PayServerApi(server: server, agentUid: agentUid);
      final result = await api.uploadRecord(transaction);

      if (result.isSuccess) {
        debugPrint('Transaction uploaded successfully');
        // TODO: Update local status to uploaded
      } else {
        debugPrint('Upload failed: ${result.error}');
        // TODO: Mark for retry
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
  }

  Future<void> _sendHeartbeat() async {
    try {
      final server = ref.read(currentServerProvider);
      if (server == null || server.uid.isEmpty) return;

      final api = PayServerApi(server: server, agentUid: server.uid);
      await api.heartbeat();
      debugPrint('Heartbeat sent');
    } catch (e) {
      debugPrint('Heartbeat failed: $e');
    }
  }

  void dispose() {
    stop();
  }
}

/// Provider for PaymentListenerService
final paymentListenerServiceProvider = Provider<PaymentListenerService>((ref) {
  final service = PaymentListenerService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for service running state
final isServiceRunningProvider = StateProvider<bool>((ref) => false);
