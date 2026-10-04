import 'package:flutter_test/flutter_test.dart';

import 'package:express_pick/core/config/platform_config.dart';
import 'package:express_pick/core/webview/login_state_detector.dart';
import 'package:express_pick/features/pickup/data/pickup_sync_service.dart';
import 'package:express_pick/features/pickup/domain/pickup_platform.dart';

import '../helpers/memory_pickup_code_repository.dart';

void main() {
  group('PickupCodeExtractor.buildScript', () {
    test('未配置选择器时脚本返回空数组', () {
      final script = PickupCodeExtractor.buildScript(null);
      expect(script, contains("if (!selector) { return '[]'; }"));
      expect(script, contains('var selector = null;'));
    });

    test('选择器写入脚本且对引号转义', () {
      final script = PickupCodeExtractor.buildScript(".code'drop");
      expect(script, contains("var selector = '.code\\'drop';"));
    });
  });

  group('PickupCodeExtractor.parse', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1727000000000);

    test('解析 code+point 完整条目并带上平台与时间', () {
      final codes = PickupCodeExtractor.parse(
        platform: PickupPlatform.taobao,
        raw: '[{"code":"3-1-2088","point":"菜鸟驿站（东门店）"},{"code":"7-2-1001","point":"丰巢柜"}]',
        now: now,
      );

      expect(codes, hasLength(2));
      expect(codes.first.code, '3-1-2088');
      expect(codes.first.platform, PickupPlatform.taobao);
      expect(codes.first.pickupPoint, '菜鸟驿站（东门店）');
      expect(codes.first.createTime, now);
    });

    test('缺 code 或 point 的条目跳过，文本自动 trim', () {
      final codes = PickupCodeExtractor.parse(
        platform: PickupPlatform.cainiao,
        raw: '[{"code":"  8-8-8  ","point":""},{"point":"有点位无码"},{"code":"9-9-9","point":" 驿站 "}]',
        now: now,
      );

      expect(codes, hasLength(1));
      expect(codes.first.code, '9-9-9');
      expect(codes.first.pickupPoint, '驿站');
    });

    test('非法 JSON 与非数组输入返回空列表', () {
      expect(
        PickupCodeExtractor.parse(
          platform: PickupPlatform.taobao,
          raw: 'not json',
          now: now,
        ),
        isEmpty,
      );
      expect(
        PickupCodeExtractor.parse(
          platform: PickupPlatform.taobao,
          raw: '{"a":1}',
          now: now,
        ),
        isEmpty,
      );
      expect(
        PickupCodeExtractor.parse(
          platform: PickupPlatform.taobao,
          raw: '',
          now: now,
        ),
        isEmpty,
      );
    });
  });

  group('PickupCodeSyncService', () {
    PlatformConfig buildConfig(Map<String, dynamic> raw) => PlatformConfig(raw);

    test('仅同步已配置 pickupUrl 的平台，结果按去重键入库', () async {
      final repo = MemoryPickupCodeRepository();
      final calledPlatforms = <PickupPlatform>[];
      final service = PickupCodeSyncService(
        config: buildConfig({
          'taobao': {'pickupUrl': 'https://example.com/tb'},
          'cainiao': {'pickupUrl': 'https://example.com/cn'},
        }),
        repository: repo,
        fetcher: (platform, url, script) async {
          calledPlatforms.add(platform);
          expect(script, isNotEmpty);
          if (platform == PickupPlatform.taobao) {
            return '[{"code":"3-1-2088","point":"驿站A"}]';
          }
          return null; // 菜鸟页提取失败
        },
      );

      final result = await service.syncAll();

      expect(calledPlatforms, [PickupPlatform.taobao, PickupPlatform.cainiao]);
      expect(result.fetched, 1);
      expect(
        result.skippedPlatforms,
        unorderedEquals([
          PickupPlatform.pinduoduo,
          PickupPlatform.kuaidi100,
          PickupPlatform.cainiao,
        ]),
      );
      final all = await repo.getAll();
      expect(all.single.code, '3-1-2088');
    });

    test('未配置 pickupUrl 的平台不触发抓取', () async {
      final repo = MemoryPickupCodeRepository();
      var fetchCalled = false;
      final service = PickupCodeSyncService(
        config: buildConfig({
          'taobao': {'loginUrl': 'https://example.com/login'},
        }),
        repository: repo,
        fetcher: (platform, url, script) async {
          fetchCalled = true;
          return '[]';
        },
      );

      final result = await service.syncAll();

      expect(fetchCalled, isFalse);
      expect(result.fetched, 0);
      expect(result.skippedPlatforms, PickupPlatform.values);
    });
  });

  group('WebviewLoginDetector', () {
    test('normalize 识别带引号的 login 标记', () {
      expect(WebviewLoginDetector.normalize("'login'"), LoginState.notLoggedIn);
    });

    test('normalize 识别 ok 为已登录', () {
      expect(WebviewLoginDetector.normalize('ok'), LoginState.loggedIn);
      expect(WebviewLoginDetector.normalize('"ok"'), LoginState.loggedIn);
    });

    test('检测脚本包含未登录提示标记', () {
      expect(WebviewLoginDetector.detectionScript, contains('您需要登录'));
    });
  });
}
