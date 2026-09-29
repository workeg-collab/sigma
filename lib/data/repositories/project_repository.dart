import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/project.dart';

class ProjectRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  ProjectRepository({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  Future<List<Project>> getAllProjects({String? status, String? search}) async {
    final db = await _db;
    String where = '';
    List<dynamic> args = [];

    if (status != null && status.isNotEmpty && status != 'all') {
      where = 'WHERE status = ?';
      args.add(status);
    }

    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      if (where.isEmpty) {
        where = 'WHERE (code LIKE ? OR name LIKE ? OR client LIKE ?)';
      } else {
        where += ' AND (code LIKE ? OR name LIKE ? OR client LIKE ?)';
      }
      args.addAll([s, s, s]);
    }

    final result = await db.rawQuery('SELECT * FROM projects $where ORDER BY code ASC', args);
    return result.map((e) => Project.fromMap(e)).toList();
  }

  Future<Project?> getProjectById(int id) async {
    final db = await _db;
    final result = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Project.fromMap(result.first);
  }

  Future<int> createProject(Project project) async {
    final db = await _db;
    return await db.insert('projects', project.toMap());
  }

  Future<int> updateProject(Project project) async {
    final db = await _db;
    return await db.update('projects', project.toMap(), where: 'id = ?', whereArgs: [project.id]);
  }

  Future<void> deleteProject(int projectId) async {
    final db = await _db;
    // Check if project has journal lines
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM journal_lines WHERE project_id = ?', [projectId]);
    final count = Sqflite.firstIntValue(res) ?? 0;
    if (count > 0) {
      throw Exception('لا يمكن حذف المشروع لوجود قيود وتكاليف مسجلة عليه. يمكنك تعديل حالته إلى منتهي أو ملغي.');
    }
    await db.delete('projects', where: 'id = ?', whereArgs: [projectId]);
  }
}
