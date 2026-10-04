import 'package:go_router/go_router.dart';

import '../features/auth/presentation/identity_code_page.dart';
import '../features/pickup/domain/pickup_platform.dart';
import '../features/pickup/presentation/pickup_detail_page.dart';
import '../features/pickup/presentation/pickup_edit_page.dart';
import '../features/pickup/presentation/pickup_list_page.dart';
import '../features/settings/presentation/settings_page.dart';

/// 路由名称
abstract final class Routes {
  static const pickupList = 'pickupList';
  static const pickupAdd = 'pickupAdd';
  static const pickupDetail = 'pickupDetail';
  static const identityCode = 'identityCode';
  static const settings = 'settings';
}

/// 构建应用路由（每个应用实例独立持有，避免路由状态跨实例泄漏）
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: Routes.pickupList,
        builder: (context, state) => const PickupListPage(),
      ),
      GoRoute(
        path: '/pickup/add',
        name: Routes.pickupAdd,
        builder: (context, state) => const PickupEditPage(),
      ),
      GoRoute(
        path: '/pickup/:id',
        name: Routes.pickupDetail,
        builder: (context, state) =>
            PickupDetailPage(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/identity/:platform',
        name: Routes.identityCode,
        builder: (context, state) => IdentityCodePage(
          platform: PickupPlatform.fromName(state.pathParameters['platform']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: Routes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
