import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:totp/classes/totp.dart';

class DatabaseWrapper {
  static final DatabaseWrapper _instance = DatabaseWrapper._internal();
  final storage = FlutterSecureStorage();

  factory DatabaseWrapper() => _instance;

  DatabaseWrapper._internal();

  Database? _database;

  Database get db {
    if (_database == null) {
      throw Exception();
    }
    return _database!;
  }

  Future<void> initDatabase() async {
    if (_database != null) return;
    String? key = await storage.read(key: "key");

    if (key == null) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64Url.encode(values);

      await storage.write(key: "key", value: key);
    }

    _database = await openDatabase(
      join(await getDatabasesPath(), "totps.db"),
      password: key,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE totps(id INTEGER PRIMARY KEY, issuer TEXT, secret TEXT, label TEXT, digits INTEGER, period INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<int> addTotp(Totp totp) async {
    if (_database == null) {
      throw Exception();
    }

    final int id = await _database!.insert(
      "totps",
      totp.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  Future<void> removeTotp(int id) async {
    if (_database == null) {
      throw Exception();
    }

    await _database!.delete("totps", where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Totp>> getAllTotps() async {
    if (_database == null) {
      throw Exception("Databáze není inicializována!");
    }

    final List<Map<String, Object?>> totps = await _database!.query("totps");

    final List<Totp> seznamTotp = [];

    for (final radek in totps) {
      seznamTotp.add(
        Totp(
          id: radek['id'] as int,
          issuer: radek['issuer'] as String,
          secret: radek['secret'] as String,
          label: radek['label'] as String,
          digits: radek['digits'] as int,
          period: radek['period'] as int,
        ),
      );
    }

    return seznamTotp;
  }

  Future<Totp> getOneTotp(int id) async {
    if (_database == null) {
      throw Exception();
    }

    final List<Map<String, Object?>> totp = await _database!.query(
      "totps",
      where: 'id = ?',
      whereArgs: [id],
    );

    if (totp.isEmpty) {
      throw Exception("TOTP with $id was not found");
    }

    final Totp totpConverted = Totp(
      id: totp[0]['id'] as int,
      issuer: totp[0]['issuer'] as String,
      secret: totp[0]['secret'] as String,
      label: totp[0]['label'] as String,
      digits: totp[0]['digits'] as int,
        period: totp[0]['period'] as int
    );

    return totpConverted;
  }
}
