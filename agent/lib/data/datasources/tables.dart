import 'package:drift/drift.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get value => text()();
  IntColumn get timestamp => integer().nullable()();
  IntColumn get amount => integer()();
  IntColumn get createAt => integer().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get raw => text().nullable()();
}

class Servers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get host => text()();
  TextColumn get version => text().withDefault(const Constant('v1'))();
  TextColumn get types => text().withDefault(const Constant(''))();
  TextColumn get uid => text().withDefault(const Constant(''))();
  TextColumn get ticket => text()();
  IntColumn get createAt => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('normal'))();
}
