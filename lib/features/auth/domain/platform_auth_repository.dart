/// 平台登录态管理接口（设计文档 5 节 PlatformAuthRepository 的 P1 子集）。
///
/// 登录在 WebView 内完成（手机号+短信验证码），不存储账号密码；
/// 登录态载体为 WebView CookieManager 中的平台会话 Cookie（.taobao.com 域，
/// 淘宝/菜鸟共用）。登录态检测见 core/webview/WebviewLoginDetector。
abstract class PlatformAuthRepository {
  /// 退出登录：清空 WebView Cookie（淘宝/菜鸟共用淘宝域登录态，一次清除全部）
  Future<void> logout();
}
