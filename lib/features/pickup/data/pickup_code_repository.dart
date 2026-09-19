import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/pickup_code.dart';
import '../domain/pickup_code_repository.dart';

/// 取件码仓库提供者。
///
/// main() 中构建 SQLite 实现后通过 ProviderScope overrides 注入；
/// 测试中注入内存实现。
final repositoryProvider = Provider<PickupCodeRepository>(
  (ref) => throw UnimplementedError('repositoryProvider 未初始化'),
);

/// 取件码仓库的 SQLite 实现
class SqflitePickupCodeRepository implements PickupCodeRepository {
  SqflitePickupCodeRepository(this._db);

  final Database _db;

  /// 打开应用数据库（App 运行时使用）
  static Future<Database> openAppDatabase() async {
    final dbDir = await getDatabasesPath();
    return openDatabase(
      p.join(dbDir, 'express_pick.db'),
      version: 1,
      onCreate: createSchema,
    );
  }

  /// 建表语句（应用与仓库测试共用）
  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pickup_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        platform TEXT NOT NULL,
        pickup_point TEXT NOT NULL,
        courier_company TEXT,
        estimated_pickup_time INTEGER,
        expire_time INTEGER,
        create_time INTEGER NOT NULL,
        is_picked INTEGER NOT NULL DEFAULT 0,
        picked_at INTEGER,
        UNIQUE(platform, code, pickup_point)
      )
    ''');
  }

  @override
  Future<int> upsert(PickupCode code) async {
    return _db.insert(
      'pickup_codes',
      code.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<PickupCode>> getAll({bool includePicked = false}) async {
    final rows = await _db.query(
      'pickup_codes',
      where: includePicked ? null : 'is_picked = 0',
      orderBy: 'create_time DESC, id DESC',
    );
    return rows.map(PickupCode.fromMap).toList();
  }

  @override
  Future<PickupCode?> getById(int id) async {
    final rows = await _db.query(
      'pickup_codes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PickupCode.fromMap(rows.first);
  }

  @override
  Future<int> markPicked(int id, {required bool picked}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.update(
      'pickup_codes',
      {'is_picked': picked ? 1 : 0, 'picked_at': picked ? now : null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> delete(int id) async {
    return _db.delete('pickup_codes', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> clearPicked() async {
    return _db.delete('pickup_codes', where: 'is_picked = 1');
  }
}
