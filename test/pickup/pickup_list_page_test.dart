import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:express_pick/app/app.dart';
import 'package:express_pick/features/pickup/data/pickup_code_repository.dart';
import 'package:express_pick/features/pickup/domain/pickup_code.dart';
import 'package:express_pick/features/pickup/domain/pickup_code_repository.dart';

/// 内存实现的取件码仓库，用于 widget 测试（绕开 sqlite 在 FakeAsync 中的限制）
class MemoryPickupCodeRepository implements PickupCodeRepository {
  final Map<int, PickupCode> _store = {};
  var _nextId = 1;

  @override
  Future<int> upsert(PickupCode code) async {
    final existingId =
        code.id ??
        _store.values
            .where((c) => c.dedupKey == code.dedupKey)
            .map((c) => c.id)
            .firstOrNull;
    final id = existingId ?? _nextId++;
    _store[id] = code.copyWith(id: id);
    return id;
  }

  @override
  Future<List<PickupCode>> getAll({bool includePicked = false}) async {
    final codes =
        _store.values.where((c) => includePicked || !c.isPicked).toList()
          ..sort((a, b) => b.createTime.compareTo(a.createTime));
    return codes;
  }

  @override
  Future<PickupCode?> getById(int id) async => _store[id];

  @override
  Future<int> markPicked(int id, {required bool picked}) async {
    final code = _store[id];
    if (code == null) return 0;
    _store[id] = code.copyWith(
      isPicked: picked,
      pickedAt: picked ? DateTime.now() : null,
    );
    return 1;
  }

  @override
  Future<int> delete(int id) async => _store.remove(id) == null ? 0 : 1;

  @override
  Future<int> clearPicked() async {
    final removed = _store.values.where((c) => c.isPicked).toList();
    for (final code in removed) {
      _store.remove(code.id);
    }
    return removed.length;
  }
}

void main() {
  late MemoryPickupCodeRepository repository;

  setUp(() {
    repository = MemoryPickupCodeRepository();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: ExpressPickApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('空列表展示引导占位', (tester) async {
    await pumpApp(tester);

    expect(find.text('取件助手'), findsOneWidget);
    expect(find.text('暂无取件码'), findsOneWidget);
  });

  testWidgets('录入取件码后列表可见并进入详情', (tester) async {
    await pumpApp(tester);

    // 进入录入页
    await tester.tap(find.text('录入取件码'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('code_field')), '3-1-2088');
    await tester.enterText(find.byKey(const Key('point_field')), '菜鸟驿站（东门店）');
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pumpAndSettle();

    // 回到列表，可见新记录
    expect(find.text('3-1-2088'), findsOneWidget);
    expect(find.text('淘宝 · 菜鸟驿站（东门店）'), findsOneWidget);

    // 进入详情
    await tester.tap(find.text('3-1-2088'));
    await tester.pumpAndSettle();
    expect(find.text('取件码详情'), findsOneWidget);
    expect(find.text('待取件'), findsOneWidget);
  });

  testWidgets('校验：未填取件码/取件点时不允许保存', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('录入取件码'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pumpAndSettle();

    expect(find.text('请输入取件码'), findsOneWidget);
    expect(find.text('请输入取件点'), findsOneWidget);
  });
}
