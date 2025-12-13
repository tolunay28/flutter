import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'explorez_votre_ville.db');

    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lieux (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titre TEXT NOT NULL,
        categorie TEXT NOT NULL,
        cleVille TEXT NOT NULL,
        imageUrl TEXT,
        adresse TEXT,
        latitude REAL,
        longitude REAL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE commentaires (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lieuId INTEGER NOT NULL,
        texte TEXT NOT NULL,
        note REAL NOT NULL,
        date INTEGER NOT NULL,
        FOREIGN KEY (lieuId) REFERENCES lieux(id) ON DELETE CASCADE
      )
    ''');
  }
}
