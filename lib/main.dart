import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/pickup/data/pickup_code_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 先打开数据库并构建仓库，通过 overrides 注入全局实例
  final database = await SqflitePickupCodeRepository.openAppDatabase();
  final repository = SqflitePickupCodeRepository(database);
  runApp(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repository)],
      child: ExpressPickApp(),
    ),
  );
}
