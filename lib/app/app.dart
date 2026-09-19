import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import 'theme.dart';

/// 应用根组件
class ExpressPickApp extends StatelessWidget {
  ExpressPickApp({super.key, GoRouter? routerConfig})
    : routerConfig = routerConfig ?? buildAppRouter();

  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '取件助手',
      theme: AppTheme.light(),
      routerConfig: routerConfig,
      debugShowCheckedModeBanner: false,
    );
  }
}
