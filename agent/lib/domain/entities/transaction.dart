import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum PayType { alipay, wechat, unknown }

extension PayTypeExtension on PayType {
  String get displayName {
    switch (this) {
      case PayType.alipay:
        return '支付宝';
      case PayType.wechat:
        return '微信';
      case PayType.unknown:
        return '未知';
    }
  }

  String toText() {
    switch (this) {
      case PayType.alipay:
        return 'alipay';
      case PayType.wechat:
        return 'wechat';
      case PayType.unknown:
        return 'unknown';
    }
  }

  String get value => toText();

  String get name => displayName;

  static PayType fromString(String value) {
    switch (value) {
      case 'alipay':
        return PayType.alipay;
      case 'wechat':
        return PayType.wechat;
      default:
        return PayType.unknown;
    }
  }

  static PayType fromPackageName(String packageName) {
    switch (packageName) {
      case 'com.tencent.mm':
        return PayType.wechat;
      case 'com.eg.android.AlipayGphone':
        return PayType.alipay;
      default:
        return PayType.unknown;
    }
  }
}

@freezed
class PayTransaction with _$PayTransaction {
  const PayTransaction._();

  const factory PayTransaction({
    int? id,
    required PayType type,
    required String value,
    required int amount,
    int? timestamp,
    DateTime? createAt,
    @Default(0) int status,
    String? raw,
  }) = _PayTransaction;

  factory PayTransaction.fromJson(Map<String, dynamic> json) =>
      _$PayTransactionFromJson(json);

  /// Parse a notification event into a PayTransaction
  /// Returns null if not a valid payment notification
  static PayTransaction? fromEvent(NotificationEvent event) {
    final type = PayTypeExtension.fromPackageName(event.packageName ?? '');
    if (type == PayType.unknown) return null;

    final text = event.text ?? '';
    final title = event.title ?? '';

    String? parsedValue;

    switch (type) {
      case PayType.alipay:
        if (!text.contains('已转入余额')) return null;
        parsedValue = _parseAmount(title);
        break;
      case PayType.wechat:
        if (title != '微信支付' || !text.contains('微信支付收款')) return null;
        parsedValue = _parseAmount(text);
        break;
      case PayType.unknown:
        return null;
    }

    if (parsedValue == null) return null;

    final amount = (double.tryParse(parsedValue) ?? 0) * 100;
    if (amount <= 0) return null;

    return PayTransaction(
      type: type,
      value: parsedValue,
      amount: amount.round(),
      timestamp: event.timestamp,
      createAt: event.createAt,
      raw: event.toString(),
    );
  }

  static String? _parseAmount(String text) {
    final regex = RegExp(r'[\d.]+');
    return regex.firstMatch(text)?.group(0);
  }
}

@freezed
class TransactionStats with _$TransactionStats {
  const factory TransactionStats({
    @Default(0) int todayCount,
    @Default(0) int todayAmount,
    @Default(0) int total,
  }) = _TransactionStats;
}
