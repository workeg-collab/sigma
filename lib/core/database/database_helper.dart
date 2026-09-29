import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'schema.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Initialize SQLite FFI on desktop platforms (macOS, Windows, Linux)
  static void initializeFfi() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> getDatabasePath() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final docDir = await getApplicationSupportDirectory();
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }
      return p.join(docDir.path, DatabaseSchema.databaseName);
    } else {
      final dbPath = await getDatabasesPath();
      return p.join(dbPath, DatabaseSchema.databaseName);
    }
  }

  Future<Database> _initDatabase() async {
    initializeFfi();
    final path = await getDatabasePath();

    return await openDatabase(
      path,
      version: DatabaseSchema.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        for (final query in DatabaseSchema.createTablesQueries) {
          await db.execute(query);
        }
        await DatabaseSeedData.seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Handle future schema migrations if any
      },
    );
  }

  /// In-memory database initialization for unit testing
  static Future<Database> createInMemoryDatabase() async {
    sqfliteFfiInit();
    final dbFactory = databaseFactoryFfi;
    final db = await dbFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseSchema.version,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          for (final query in DatabaseSchema.createTablesQueries) {
            await db.execute(query);
          }
          await DatabaseSeedData.seed(db);
        },
      ),
    );
    return db;
  }

  /// Backup current database to destination path
  Future<File> backupDatabase(String destinationPath) async {
    final currentPath = await getDatabasePath();
    final sourceFile = File(currentPath);
    if (!await sourceFile.exists()) {
      throw Exception('ملف قاعدة البيانات غير موجود على المسار المحدد.');
    }
    // Checkpoint SQLite WAL before copy
    final db = await database;
    try {
      await db.rawQuery('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}

    return await sourceFile.copy(destinationPath);
  }

  /// Restore database from backup path
  Future<bool> restoreDatabase(String backupPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw Exception('ملف النسخة الاحتياطية غير موجود.');
    }

    // Close active db connection
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }

    final targetPath = await getDatabasePath();
    await backupFile.copy(targetPath);

    // Reopen and check integrity
    _database = await _initDatabase();
    final integrity = await _database!.rawQuery('PRAGMA integrity_check;');
    final result = integrity.isNotEmpty ? integrity.first.values.first.toString() : '';
    if (result.toLowerCase() != 'ok') {
      throw Exception('فحص سلامة قاعدة البيانات المستعادة فشل: $result');
    }
    return true;
  }

  /// Database statistics (size in bytes, formatted string, last modified)
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final path = await getDatabasePath();
      final file = File(path);
      if (await file.exists()) {
        final length = await file.length();
        final stat = await file.stat();
        final sizeFormatted = (length < 1024 * 1024)
            ? '${(length / 1024).toStringAsFixed(1)} KB'
            : '${(length / (1024 * 1024)).toStringAsFixed(2)} MB';
        return {
          'path': path,
          'size': length,
          'sizeFormatted': sizeFormatted,
          'lastModified': stat.modified,
        };
      }
    } catch (_) {}
    return {
      'path': '',
      'size': 0,
      'sizeFormatted': '0 KB',
      'lastModified': DateTime.now(),
    };
  }

  /// Closes database
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
