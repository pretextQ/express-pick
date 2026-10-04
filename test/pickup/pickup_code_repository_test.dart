import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:express_pick/features/pickup/data/pickup_code_repository.dart';
import 'package:express_pick/features/pickup/domain/pickup_code.dart';
import 'package:express_pick/features/pickup/domain/pickup_platform.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late SqflitePickupCodeRepository repo;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: SqflitePickupCodeRepository.createSchema,
      ),
    );
    repo = SqflitePickupCodeRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  PickupCode buildCode(String code, {PickupPlatform? platform, String? point}) {
    return PickupCode(
      code: code,
      platform: platform ?? PickupPlatform.taobao,
      pickupPoint: point ?? '菜鸟驿站（东门店）',
      createTime: DateTime.fromMillisecondsSinceEpoch(1727000000000),
    );
  }

  test('upsert 后可查询到记录', () async {
    await repo.upsert(buildCode('3-1-2088'));

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.first.code, '3-1-2088');
    expect(all.first.platform, PickupPlatform.taobao);
    expect(all.first.isPicked, isFalse);
  });

  test('相同 platform+code+pickupPoint 去重（整行替换）', () async {
    await repo.upsert(buildCode('3-1-2088'));
    await repo.upsert(buildCode('3-1-2088'));
    await repo.upsert(buildCode('3-1-2088', platform: PickupPlatform.cainiao));

    final all = await repo.getAll();
    expect(all, hasLength(2));
  });

  test('getAll 默认不含已取件记录', () async {
    final id = await repo.upsert(buildCode('3-1-2088'));
    await repo.upsert(buildCode('7-2-1001'));
    await repo.markPicked(id, picked: true);

    final pending = await repo.getAll();
    expect(pending.map((c) => c.code), ['7-2-1001']);

    final history = await repo.getAll(includePicked: true);
    expect(history, hasLength(2));
  });

  test('getById 返回详情，不存在时返回 null', () async {
    final id = await repo.upsert(buildCode('3-1-2088'));

    final found = await repo.getById(id);
    expect(found, isNotNull);
    expect(found!.code, '3-1-2088');

    expect(await repo.getById(9999), isNull);
  });

  test('markPicked 记录取件时间，恢复时清空', () async {
    final id = await repo.upsert(buildCode('3-1-2088'));

    await repo.markPicked(id, picked: true);
    var code = await repo.getById(id);
    expect(code!.isPicked, isTrue);
    expect(code.pickedAt, isNotNull);

    await repo.markPicked(id, picked: false);
    code = await repo.getById(id);
    expect(code!.isPicked, isFalse);
    expect(code.pickedAt, isNull);
  });

  test('delete 删除单条记录', () async {
    final id = await repo.upsert(buildCode('3-1-2088'));

    await repo.delete(id);
    expect(await repo.getById(id), isNull);
    expect(await repo.getAll(), isEmpty);
  });

  test('clearPicked 只清理已取件记录', () async {
    final pickedId = await repo.upsert(buildCode('3-1-2088'));
    await repo.upsert(buildCode('7-2-1001'));
    await repo.markPicked(pickedId, picked: true);

    await repo.clearPicked();

    final remaining = await repo.getAll(includePicked: true);
    expect(remaining.map((c) => c.code), ['7-2-1001']);
  });
}
