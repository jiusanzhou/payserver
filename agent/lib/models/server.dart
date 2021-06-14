
import 'dart:convert';

import 'package:agent/models/models_test.dart';
import 'package:agent/models/transaction.dart';
import 'package:agent/store/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoekits/flutter_zoekits.dart';

enum ServerStatus {
  Normal,
  Warning,
  Error,
  Unknown,
}

extension ServerStatusMethod on ServerStatus {

  String toText() {
    final _keys = <ServerStatus, String> {
      ServerStatus.Normal: "normal",
      ServerStatus.Warning: "warning",
      ServerStatus.Error: "error",
      ServerStatus.Unknown: "unknown",
    };
    return _keys[this];
  }

  String get text => toText();

  ServerStatus apply(String key) {
    final _keys = <String, ServerStatus> {
      "normal": ServerStatus.Normal,
      "warning": ServerStatus.Warning,
      "error": ServerStatus.Error,
    };
    return _keys[key] ?? ServerStatus.Unknown;
  }
}

class Server {
  int id;

  String name; // name of the server
  String host; // host of the server
  String version; // api server ::ignore

  List<PayType> types;

  // uid and token
  String uid;
  String ticket;

  ServerStatus status;

  DateTime createAt;

  bool isDefault;

  Server({
    this.id,
    this.name,
    this.host,
    this.version = "v1",
    this.types = const [],
    this.uid = "",
    this.ticket,
    this.status = ServerStatus.Normal,
    this.createAt,
  }) : assert(name != null && host != null && ticket != null);

  factory Server.empty() {
    return Server(
      name: "", host: "", ticket: "", types: [],
      createAt: DateTime.now(),
    );
  }

  bool invalid() {
    return true;
  }

  @override
  String toString() {
    return json.encode(this.toMap());
  }


  // DAO
  Server.fromMap(Map<String, dynamic> res) {
    id = res["id"];
    name = res["name"];
    host = res["host"];
    version = res["versin"];
    types = (res["types"] as String).split(",").map(
      (e) => PayType.Unknown.apply(e)).toList();
    uid = res["uid"]; // what's this?
    ticket = res["ticket"];
    status = ServerStatus.Unknown.apply(res["status"]);
    createAt = DateTime.fromMillisecondsSinceEpoch(res["create_at"]??0);
  }

  Map<String, Object> toMap() {
    return {
      "id": id,
      "name": name,
      "host": host,
      "version": version,
      "types": types.map((e) => e.text).join(","),
      "uid": uid,
      "ticket": ticket,
      "status": status?.text,
      "create_at": createAt?.millisecondsSinceEpoch,
    };
  }
}

class ServerModel extends ChangeNotifier {

  final _curServerIDKey = "current_server_id";

  final DBProvider db;

  Server _currentServer;

  // all servers at here
  List<Server> _servers = [];

  Server get currentServer => _currentServer;

  List<Server> get servers  => _servers;

  ServerModel({@required this.db});

  init() async {
    // TODO: load default from remote config

    _servers.add(genServer(-1, name: "官方云"));

    _currentServer = _servers[0]; // defualt

    // must add default server
    // load servers from db
    await db.queryServers().then((value) => _servers.addAll(value));

    // _servers.addAll(List<Server>.generate(4, (index) => genServer(index)));

    // set current with id
    var xid = ZSharedPreferences.instance.getInt(_curServerIDKey);
    if (xid == null) return;

    // filter to find the server or default one
    _currentServer = servers.firstWhere((e) => e.id == xid, orElse: () => _servers[0]);
  }

  setCurrentServer(Server ser) {
    _currentServer = ser;
    notifyListeners();
    ZSharedPreferences.instance.putInt(_curServerIDKey, ser.id ?? -1);
  }

  insertServer(Server server) async {
    // TODO: post to remote, and with error.
    await db.insertServer(server);
    servers.add(server);
    notifyListeners();
  }

  updateServer(Server server) async {
    await db.updateServer(server);
    for (var i = 0; i < servers.length; i++) {
      if (servers[i].id == server.id) {
        servers[i] = server;
        break;
      }
    }
    notifyListeners();
  }

  deleteServer(Server server) async {
    await db.deleteServer(server);
    servers.remove(server);
    notifyListeners();
  }
}