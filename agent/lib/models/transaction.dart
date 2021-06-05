
import 'package:agent/store/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

enum PayType {
  Alipay,
  WeChat,
  Unknown,
}

extension PayTypeMethod on PayType {
  // @override toString???

  String toText() {
    final _keys = <PayType, String>{
      PayType.Alipay: "alipay",
      PayType.WeChat: "wechat",
      PayType.Unknown: "unknown",
    };
    return _keys[this];
  }

  String getName() {
    final _keys = <PayType, String>{
      PayType.Alipay: "支付宝",
      PayType.WeChat: "微信",
      PayType.Unknown: "未知方式",
    };
    return _keys[this];
  }

  PayType apply(String key) {
    final _keys = <String, PayType>{
      "alipay": PayType.Alipay,
      "wechat": PayType.WeChat,
    };
    return _keys[key] ?? PayType.Unknown;
  }

  String get text => toText();

  String get name => getName();
}

class PayTransaction {
  int id;
  PayType type; // alipay / wechat

  String value; // 1.00
  int amount; // 1.00 => 100

  int timestamp;
  int status; // report to server ...

  String raw; // {}

  DateTime createAt;

  PayTransaction({
    this.id,
    this.type,
    this.value,
    this.timestamp,
    this.amount,
    this.createAt,
    this.status: 0,
    this.raw,
  });

  factory PayTransaction.fromEvent(NotificationEvent evt) {
    // set type from packageName
    // parse count from title

    PayTransaction _this = PayTransaction(
      timestamp: evt.timestamp,
      createAt: evt.createAt,
      type: getPayType(evt.packageName),
      raw: evt.toString(),
    );

    assert(evt.text != null || evt.title != null);

    // panic, maybe we need to ignore this?
    // assert(_this.type != PayType.Unknown);

    // set value and num if check success;

    // add more for other
    switch (_this.type) {
      case PayType.Alipay:
        assert(evt.text.contains("已转入余额"));
        _this.value = parseCount(evt.title);
        break;
      case PayType.WeChat:
        assert(evt.title == "微信支付" && evt.text.contains("微信支付收款"));
        _this.value = parseCount(evt.text);
        break;
      default:
    }

    // value can't be null
    assert(_this.value != null);

    // parse from
    _this.amount = (double.parse(_this.value) * 100).round(); // 0.01 => 1

    return _this;
  }

  // current only chinese

  static PayType getPayType(String pkgName) {
    // what about custom package name??? im.zoe.mm.one
    // with auto register???
    // but not a static method handle this???
    // TODO:
    final _keys = <String, PayType>{
      "com.tencent.mm": PayType.WeChat,
      "com.eg.android.AlipayGphone": PayType.Alipay,
    };
    return _keys[pkgName] ?? PayType.Unknown;
  }

  static String parseCount(String text) {
    // alipay text 已转入余额 立即查看余额>>, title 你已成功收款0.01元
    // wechat text 微信支付收款0.01元(朋友到店), title 微信支付
    final _regex = RegExp("[0-9|.]+");
    return _regex.firstMatch(text)?.group(0);
  }

  @override
  String toString() {
    return "${type.text} $value $createAt";
  }


  // DAO

  PayTransaction.fromMap(Map<String, dynamic> res) {
    id = res["id"];
    type = PayType.Unknown.apply(res["type"]);
    value = res["value"];
    timestamp = res["timestamp"];
    amount = res["amount"];
    createAt = DateTime.fromMillisecondsSinceEpoch(res["create_at"]??0);
    status = res["status"];
    raw = res["raw"];
  }

  Map<String, Object> toMap() {
    return {
      "id": id,
      "type": type.text,
      "value": value,
      "timestamp": timestamp,
      "amount": amount,
      "create_at": (createAt ?? DateTime.now()).millisecondsSinceEpoch,
      "status": status,
      "raw": raw,
    };
  }
}

class PayTransactionModel extends ChangeNotifier {

  final DBProvider db;
  // final Backend be;

  List<PayTransaction> _trans = [];
  int _todayCount = 0;
  int _todayAmount = 0;
  int _waitConfirm = 0;
  int _total = 0;

  List<PayTransaction> get trans => _trans;
  int get todayCount => _todayCount;
  int get todayAmount => _todayAmount;
  int get waitConfirm => _waitConfirm;
  int get total => _total;

  bool get hasMore => _total > _trans.length;

  int _limit = 10;

  PayTransactionModel({@required this.db});

  init() async {
    // await loadMoreAllTrans();
    await db.countTrans().then((value) => _total = value);

    var now = DateTime.now();

    await db.countTrans(
      from: DateTime(now.year, now.month, now.day, 0),
      to: DateTime(now.year, now.month, now.day+1, 0),
    ).then((value) => _todayCount = value);

    await db.amountTrans(
      from: DateTime(now.year, now.month, now.day, 0),
      to: DateTime(now.year, now.month, now.day+1, 0),
    ).then((value) => _todayAmount = value);
  }

  insertTrans(PayTransaction tran, { bool disableUI = false, bool disableStore = false }) async {
    // maybe we should insert first and save to db later
    if (!disableUI) {
      _trans.insert(0, tran);

      _total++;
      _todayCount++;
      _todayAmount+=tran.amount;

      notifyListeners();

      print("insert a transaction to ui: $tran");

      return Future.value(null);
    }

    if (!disableStore) {

      print("insert a transaction to store: $tran");
      // save to the db first, and save to remote
      // TODO: send to remote notify and update transaction status.
      return db.insertTrans(tran);
    }
  }

  loadMoreAllTrans() {
    return db.queryTrans(offset: _trans.length, limit: _limit)
      .then((vs) => _trans.addAll(vs))
      .then((_) => notifyListeners());
  }

  cleanTrans() {
    // clean show but don't delete
    _trans.clear();
    notifyListeners();
  }
}
