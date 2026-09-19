import 'package:webview_flutter/webview_flutter.dart';

/// 登录态检测结果
enum LoginState { loggedIn, notLoggedIn }

/// 登录态检测器：加载身份码页后通过 DOM 文本判断是否弹出登录引导。
///
/// 阶段0验证结论：未登录时页面展示「您需要登录才能继续访问」提示层；
/// 已登录时直接渲染身份码。Cookie 由 WebView 持久化，App 重启后保持。
abstract final class WebviewLoginDetector {
  static const _loginPromptMarker = '您需要登录';

  /// 注入已加载页面的检测脚本，返回 'login' 或 'ok'
  static String get detectionScript =>
      '''
(function() {
  var text = (document.body && document.body.innerText) || '';
  return text.indexOf('$_loginPromptMarker') !== -1 ? 'login' : 'ok';
})()
''';

  /// 归一化 runJavaScriptReturningResult 的返回值
  /// （不同平台可能带引号或以其他基础类型包装）
  static LoginState normalize(Object? raw) {
    final text = raw
        .toString()
        .replaceAll("'", '')
        .replaceAll('"', '')
        .toLowerCase();
    return text.contains('login')
        ? LoginState.notLoggedIn
        : LoginState.loggedIn;
  }

  /// 用已加载身份码页的 controller 检测登录态
  static Future<LoginState> detect(WebViewController controller) async {
    final raw = await controller.runJavaScriptReturningResult(detectionScript);
    return normalize(raw);
  }
}
