import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:express_pick/app/app.dart';
import 'package:express_pick/features/pickup/data/pickup_code_repository.dart';

import '../helpers/memory_pickup_code_repository.dart';

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
