import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/platform_config.dart';
import '../domain/pickup_code.dart';
import '../domain/pickup_code_repository.dart';
import '../domain/pickup_platform.dart';
import 'pickup_code_repository.dart';

/// 同步结果统计
class SyncResult {
  const SyncResult({required this.fetched, required this.skippedPlatforms});

  /// 本次抓取并入库的条数
  final int fetched;

  /// 被跳过的平台（未配置抓取地址，或页面加载/提取失败）
  final List<PickupPlatform> skippedPlatforms;
}

/// 抓取执行器：加载平台取件页并注入提取脚本，返回脚本原始输出。
///
/// 独立成函数类型以便测试注入假实现（WebView 无法在单元测试中运行）。
typedef ExtractionFetcher = Future<String?> Function(
  PickupPlatform platform,
  String url,
  String script,
);

/// 取件码同步服务（P1）：配置驱动的 H5 抓取编排。
///
/// - 平台配置缺少 pickupUrl 时跳过（阶段0结论：真实取件页待登录后回填）
/// - 抓取结果按去重键 upsert，调用方负责刷新 UI
class PickupCodeSyncService {
  PickupCodeSyncService({
    required this.config,
    required this.repository,
    this.fetcher = webviewExtractionFetcher,
    this.pageLoadTimeout = const Duration(seconds: 10),
  });

  final PlatformConfig config;
  final PickupCodeRepository repository;
  final ExtractionFetcher fetcher;
  final Duration pageLoadTimeout;

  static final _supportedPlatforms = PickupPlatform.values;

  /// 同步所有已配置平台
  Future<SyncResult> syncAll() async {
    var fetched = 0;
    final skipped = <PickupPlatform>[];

    for (final platform in _supportedPlatforms) {
      final url = config.pickupUrl(platform);
      if (url == null) {
        skipped.add(platform);
        continue;
      }
      final selector = config.pickupCodeSelector(platform);
      final raw = await fetcher(
        platform,
        url,
        PickupCodeExtractor.buildScript(selector),
      );
      if (raw == null) {
        skipped.add(platform);
        continue;
      }
      final codes = PickupCodeExtractor.parse(
        platform: platform,
        raw: raw,
        now: DateTime.now(),
      );
      for (final code in codes) {
        await repository.upsert(code);
        fetched++;
      }
    }
    return SyncResult(fetched: fetched, skippedPlatforms: skipped);
  }
}

/// 取件码同步服务提供者
final syncServiceProvider = FutureProvider<PickupCodeSyncService>((ref) async {
  final config = await ref.watch(platformConfigProvider.future);
  return PickupCodeSyncService(
    config: config,
    repository: ref.watch(repositoryProvider),
  );
});

/// WebView 实现的抓取执行器：离屏加载页面，完成后注入脚本提取。
Future<String?> webviewExtractionFetcher(
  PickupPlatform platform,
  String url,
  String script,
) async {
  final pageReady = Completer<void>();
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          if (!pageReady.isCompleted) pageReady.complete();
        },
        onWebResourceError: (_) {
          // 子资源加载失败也会触发；仍尝试执行脚本，失败由调用方兜底
          if (!pageReady.isCompleted) pageReady.complete();
        },
      ),
    );

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.isScheme('HTTPS')) return null;
  final load = controller.loadRequest(uri);
  try {
    await pageReady.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
    final raw = await controller.runJavaScriptReturningResult(script);
    return raw.toString();
  } catch (_) {
    return null;
  } finally {
    await load;
  }
}

/// H5 取件码提取：脚本构建与结果解析。
///
/// 阶段0遗留项：真实选择器待真机登录后回填 assets/platform_config.json，
/// 当前配置为 null，脚本返回空数组，同步为空操作。
abstract final class PickupCodeExtractor {
  /// 注入取件页的提取脚本；未配置选择器时脚本恒返回 '[]'
  static String buildScript(String? selector) {
    final selectorLiteral = selector == null
        ? 'null'
        : "'${selector.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
    return '''
(function() {
  var selector = $selectorLiteral;
  if (!selector) { return '[]'; }
  var out = [];
  var nodes = document.querySelectorAll(selector);
  for (var i = 0; i < nodes.length; i++) {
    var el = nodes[i];
    var card = el.closest('li,div,section,article') || el;
    out.push({
      code: (el.innerText || '').trim(),
      point: (card.getAttribute('data-point') || '').trim()
    });
  }
  return JSON.stringify(out);
})()
''';
  }

  /// 解析脚本返回的 JSON 数组。
  ///
  /// 容错：非法 JSON、非数组输入返回空列表；缺 code 或 point 的条目跳过
  /// （pickupPoint 是去重键的组成部分，不能为空）。
  static List<PickupCode> parse({
    required PickupPlatform platform,
    required String raw,
    required DateTime now,
  }) {
    List<dynamic>? decoded;
    try {
      final value = jsonDecode(raw);
      if (value is List) decoded = value;
    } catch (_) {
      return const [];
    }
    if (decoded == null) return const [];

    final codes = <PickupCode>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final code = (item['code'] ?? '').toString().trim();
      final point = (item['point'] ?? '').toString().trim();
      if (code.isEmpty || point.isEmpty) continue;
      codes.add(
        PickupCode(
          code: code,
          platform: platform,
          pickupPoint: point,
          createTime: now,
        ),
      );
    }
    return codes;
  }
}
