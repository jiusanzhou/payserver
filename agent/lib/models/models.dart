
import 'dart:isolate';
import 'dart:ui';

import 'package:agent/models/models_test.dart';
import 'package:agent/models/server.dart';
import 'package:agent/models/transaction.dart';
import 'package:agent/store/database.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:synchronized/synchronized.dart';

class ModelFactory {

  PayTransactionModel trans;
  ServerModel servr;

  static Lock _lock = Lock();
  static ModelFactory _instance;
  
  static ReceivePort port = ReceivePort();

  static ModelFactory get instance => _instance;

  ModelFactory() {
    trans = PayTransactionModel(db: DBProvider.instance);
    servr = ServerModel(db: DBProvider.instance);
  }

  init() async {

    await trans.init();
    await servr.init();

    // this can fix restart<debug> can't handle error
    print("init model factory ...");
    IsolateNameServer.removePortNameMapping("_listener_");
    IsolateNameServer.registerPortWithName(port.sendPort, "_listener_");

    // notify the ui
    port.listen((msg) => trans.insertTrans(msg as PayTransaction, onlyUI: true));

    // init listener service: fix bug can't return
    NotificationsListener.initialize(callbackHandle: _evtCallback);
  }

  static Future<ModelFactory> get() async {
    if (_instance != null) return _instance;
    await _lock.synchronized(() {
      _instance = ModelFactory();
      _instance.init();
    });
    return _instance;
  }

  static void _evtCallback(NotificationEvent evt) async {
    print("send evt to ui from _evtCallback: $evt");
    PayTransaction tran;
    try {tran = PayTransaction.fromEvent(evt);} catch (e) {
      // debug just for
      tran = genTransaction(PayType.WeChat, 0.01);
    }

    if (tran == null) return;

    // notify the ui
    final SendPort send = IsolateNameServer.lookupPortByName("_listener_");
    if (send == null) print("can't find the sender: _listener_");
    send?.send(tran);

    // insert to the database
    (await ModelFactory.get()).trans.insertTrans(tran, onlyStore: true);
  }
}