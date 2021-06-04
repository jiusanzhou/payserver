import 'package:agent/models/server.dart';
import 'package:agent/models/transaction.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

NotificationEvent genAlipayPayEvent(double count) {
  return NotificationEvent(
    packageName: "com.eg.android.AlipayGphone",
    title: "你已成功收款$count元",
    text: "已转入余额 立即查看余额>>",
    createAt: DateTime.now(),
  );
}

NotificationEvent genWeChatPayEvent(double count) {
  return NotificationEvent(
    packageName: "com.tencent.mm",
    title: "微信支付",
    text: "微信支付收款$count元(朋友到店)",
    createAt: DateTime.now(),
  );
}

PayTransaction genTransaction(PayType type, double count) {
  return PayTransaction(
    type: type,
    value: "$count",
    amount: (count * 100).round(),
    createAt: DateTime.now(),
  );
}

Server genServer(String name) {
  return Server(
    name: name,
    host: "https://example.com/$name",
    ticket: "xxx",
    types: [PayType.Alipay, PayType.WeChat],
  );
}