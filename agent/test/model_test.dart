
import 'package:agent/models/transaction.dart';
import 'package:agent/models/models_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("parseCount", () {
    expect(PayTransaction.parseCount("微信支付收款0.01元(朋友到店)"), "0.01");
    expect(PayTransaction.parseCount("你已成功收款0.01元"), "0.01");
  });

  test("测试事件解析", () {
    var cases = [
      [genAlipayPayEvent(0.01), genTransaction(PayType.Alipay, 0.01)],
      [genAlipayPayEvent(100.99), genTransaction(PayType.Alipay, 100.99)],
      [genWeChatPayEvent(0.01), genTransaction(PayType.WeChat, 0.01)],
      [genWeChatPayEvent(100.99), genTransaction(PayType.WeChat, 100.99)],
    ];
    
    cases.forEach((e) {
      var t = PayTransaction.fromEvent(e[0]);
      if (e[1] == null) {
        expect(t, null);
        return;
      }

      expect(t.type, (e[1] as PayTransaction).type);
      expect(t.value, (e[1] as PayTransaction).value);
      expect(t.amount, (e[1] as PayTransaction).amount);
    });
  });
}