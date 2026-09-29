import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
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

  /// Initialize SQLite FFI on desktop platforms or web
  static void initializeFfi() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
    if (kIsWeb) {
      return DatabaseSchema.databaseName;
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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

    if (kIsWeb) {
      return await databaseFactoryFfiWeb.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: DatabaseSchema.version,
          onCreate: (db, version) async {
            for (final query in DatabaseSchema.createTablesQueries) {
              await db.execute(query);
            }
            await DatabaseSeedData.seed(db);
          },
        ),
      );
    }

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
    if (kIsWeb) {
      return await databaseFactoryFfiWeb.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DatabaseSchema.version,
          onCreate: (db, version) async {
            for (final query in DatabaseSchema.createTablesQueries) {
              await db.execute(query);
            }
            await DatabaseSeedData.seed(db);
          },
        ),
      );
    }
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
    if (kIsWeb) {
      throw UnsupportedError('النسخ الاحتياطي لقواعد البيانات متاح على أنظمة سطح المكتب فقط.');
    }
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
    if (kIsWeb) {
      throw UnsupportedError('استعادة قواعد البيانات متاحة على أنظمة سطح المكتب فقط.');
    }
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
      if (kIsWeb) {
        return {
          'size': 1024 * 1024,
          'sizeFormatted': '1.0 MB (IndexedDB)',
          'lastModified': DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '),
          'path': 'متصفح الويب (IndexedDB)',
        };
      }
      final path = await getDatabasePath();
      final file = File(path);
      if (await file.exists()) {
        final stat = await file.stat();
        return {
          'size': stat.size,
          'sizeFormatted': _formatFileSize(stat.size),
          'lastModified': stat.modified.toIso8601String().substring(0, 19).replaceAll('T', ' '),
          'path': path,
        };
      }
    } catch (e) {
      debugPrint('Error getting db info: $e');
    }
    return {
      'size': 0,
      'sizeFormatted': 'غير متوفر',
      'lastModified': 'غير متوفر',
      'path': 'غير معروف',
    };
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
