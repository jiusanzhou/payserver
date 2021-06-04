
import 'package:agent/store/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("create database", () async {
    final db = await DBProvider.instance.database;
    await DBProvider.instance.database;
  });
}