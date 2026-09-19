import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pickup/domain/pickup_platform.dart';

/// 平台配置提供者
final platformConfigProvider = FutureProvider<PlatformConfig>(
  (ref) => PlatformConfig.load(),
);

/// 平台配置（assets/platform_config.json）。
///
/// URL 来自阶段0技术验证结论，选择器待真机登录后回填；
/// 平台页面路径可能随版本更新失效，需保持配置文件化。
class PlatformConfig {
  PlatformConfig(this._raw);

  final Map<String, dynamic> _raw;

  static Future<PlatformConfig> load() async {
    final content = await rootBundle.loadString('assets/platform_config.json');
    return PlatformConfig(jsonDecode(content) as Map<String, dynamic>);
  }

  Map<String, dynamic>? _node(PickupPlatform platform) {
    final node = _raw[platform.name];
    return node is Map<String, dynamic> ? node : null;
  }

  /// 登录页地址（淘宝/菜鸟共用淘宝 H5 登录）
  String? loginUrl(PickupPlatform platform) =>
      _node(platform)?['loginUrl'] as String?;

  /// 身份码页面地址
  String? identityUrl(PickupPlatform platform) =>
      _node(platform)?['identityUrl'] as String?;

  /// 取件码页地址（P2 可选）
  String? pickupUrl(PickupPlatform platform) =>
      _node(platform)?['pickupUrl'] as String?;

  /// 支持身份码展示的平台（配置中存在 identityUrl 的）
  List<PickupPlatform> get identityPlatforms =>
      PickupPlatform.values.where((p) => identityUrl(p) != null).toList();
}
