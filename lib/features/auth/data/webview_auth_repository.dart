import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../domain/platform_auth_repository.dart';

/// 平台登录态管理提供者
final authRepositoryProvider = Provider<PlatformAuthRepository>(
  (ref) => const WebviewAuthRepository(),
);

/// 基于 WebView Cookie 的登录态管理实现。
///
/// Cookie 由 WebView 在应用沙箱内持久化，App 重启后登录态自动保持；
/// 退出登录即清空 Cookie，下次打开身份码页会重新要求登录。
class WebviewAuthRepository implements PlatformAuthRepository {
  const WebviewAuthRepository();

  @override
  Future<void> logout() async {
    await WebViewCookieManager().clearCookies();
  }
}
