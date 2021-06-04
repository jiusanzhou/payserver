import 'package:agent/models/server.dart';
import 'package:agent/models/transaction.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider instance = DBProvider._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // if _database is null we instantiate it
    _database = await initializeDB();
    return _database;
  }

  initializeDB() async {
    var dbDir = await getDatabasesPath();
    String dbFile = join(dbDir, "easypay.db");
    return await openDatabase(
      dbFile,
      onCreate: _onCreate,
      version: 1,
    );
  }

  final String _TT = "transactions";
  final String _TS = "servers";
  final String _TO = "orders";

  void _onCreate(Database db, int version) async {
    await db.execute(
      "CREATE TABLE $_TT ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "type TEXT NOT NULL,"
      "value TEXT NOT NULL,"
      "timestamp INTEGER,"
      "amount INTEGER NOT NULL,"
      "create_at INTEGER,"
      "status INTEGER,"
      "raw TEXT)"
    );
    await db.execute(
      "CREATE TABLE $_TS("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "name TEXT NOT NULL,"
      "host TEXT NOT NULL,"
      "version TEXT NOT NULL,"
      "types TEXT NOT NULL,"
      "uid TEXT NOT NULL,"
      "ticket TEXT NOT NULL,"
      "create_at INTEGER,"
      "status TEXT)"
      // TODO: last_active
    );
  }

  Future<int> insertTrans(PayTransaction tran) async {
    return await (await database).insert(_TT, tran.toMap());
  }

  Future<List<PayTransaction>> queryTrans({
    int limit, int offset,
    PayType type, DateTime from, DateTime to
  }) async {
    if (from==null) from = DateTime(0);
    if (to==null) to = DateTime(99999);
    final List<Map<String, Object>> qr = await (await database).query(
      _TT, limit: limit, offset: offset, orderBy: "create_at DESC",
      where: "type LIKE ? AND create_at > ? AND create_at < ?",
      whereArgs: [type?.text ?? "%", from.millisecondsSinceEpoch, to.millisecondsSinceEpoch]
    ).catchError((e) => <Map<String, Object>>[]);

    // TODO: fuck todo

    return qr.map((e) => PayTransaction.fromMap(e)).toList();
  }

  Future<int> countTrans({PayType type, DateTime from, DateTime to}) async {
    if (from==null) from = DateTime(0);
    if (to==null) to = DateTime(99999);
    return Sqflite.firstIntValue(
      await (await database).rawQuery(
              "SELECT COUNT(id)"
              " FROM $_TT"
              " WHERE type LIKE ?"
              " AND create_at > ?"
              " AND create_at < ?",
              [type?.text ?? "%", from.millisecondsSinceEpoch, to.millisecondsSinceEpoch])
    );
  }

  Future<int> amountTrans({PayType type, DateTime from, DateTime to}) async {
    var trs = await queryTrans(type: type, from: from, to: to);
    var ams = trs.map((e) => e.amount).toList();
    ams.add(0); // for reduce
    return ams.reduce((value, element) => value + element);
  }

  Future<int> insertServer(Server server) async {
    return await (await database).insert(_TS, server.toMap());
  }

  Future<List<Server>> queryServers() async {
    final List<Map<String, Object>> qr =  await (await database).query(_TS);
    return qr.map((e) => Server.fromMap(e)).toList();
  }

  Future<void> deleteServer(Server server) async {
    return await (await database).delete(_TS, where: "id = ?", whereArgs: [server.id]);
  }
}