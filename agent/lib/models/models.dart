
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
  bool inited = false;
  ReceivePort port = ReceivePort();

  static final ModelFactory _instance = ModelFactory._();
  
  static ModelFactory get instance => _instance;

  factory ModelFactory() {
    return _instance;
  }

  ModelFactory._() {
    trans = PayTransactionModel(db: DBProvider.instance);
    servr = ServerModel(db: DBProvider.instance);
  }

  init() async {
    // TODO: use lock
    if (inited) return;
    inited = true;


    await trans.init();
    await servr.init();

    // this can fix restart<debug> can't handle error
    print("init model factory ...");
    IsolateNameServer.removePortNameMapping("_listener_");
    IsolateNameServer.registerPortWithName(port.sendPort, "_listener_");

    // notify the ui
    port.listen((msg) => {
      trans.insertTrans(msg as PayTransaction, disableStore: true)
    });

    // init listener service: fix bug can't return
    NotificationsListener.initialize(callbackHandle: _evtCallback);
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
    ModelFactory().trans.insertTrans(tran, disableUI: true);
  }
}