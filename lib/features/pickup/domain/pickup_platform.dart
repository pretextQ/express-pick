/// 平台枚举（避免与 dart:io Platform / Flutter TargetPlatform 重名）
enum PickupPlatform {
  taobao('淘宝'),
  pinduoduo('拼多多'),
  cainiao('菜鸟'),
  kuaidi100('快递100');

  const PickupPlatform(this.displayName);

  /// 平台中文名
  final String displayName;

  /// 按枚举名解析，未知名称回退淘宝
  static PickupPlatform fromName(String name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => PickupPlatform.taobao,
  );
}
