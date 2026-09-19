import 'package:flutter_test/flutter_test.dart';

import 'package:express_pick/features/pickup/domain/pickup_code.dart';
import 'package:express_pick/features/pickup/domain/pickup_platform.dart';

void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1727000000000);

  PickupCode buildSample() => PickupCode(
    id: 1,
    code: '3-1-2088',
    platform: PickupPlatform.taobao,
    pickupPoint: '菜鸟驿站（东门店）',
    courierCompany: '中通',
    estimatedPickupTime: now,
    expireTime: now.add(const Duration(days: 3)),
    createTime: now,
    isPicked: false,
  );

  test('toMap/fromMap 往返保留全部字段', () {
    final restored = PickupCode.fromMap(buildSample().toMap());

    expect(restored.code, '3-1-2088');
    expect(restored.platform, PickupPlatform.taobao);
    expect(restored.pickupPoint, '菜鸟驿站（东门店）');
    expect(restored.courierCompany, '中通');
    expect(restored.estimatedPickupTime, now);
    expect(restored.expireTime, now.add(const Duration(days: 3)));
    expect(restored.createTime, now);
    expect(restored.isPicked, isFalse);
    expect(restored.pickedAt, isNull);
  });

  test('空值字段与已取件状态往返', () {
    final picked = PickupCode(
      id: 2,
      code: '7-2-1001',
      platform: PickupPlatform.cainiao,
      pickupPoint: '菜鸟驿站（东门店）',
      createTime: now,
      isPicked: true,
      pickedAt: now,
    );
    final restored = PickupCode.fromMap(picked.toMap());

    expect(restored.courierCompany, isNull);
    expect(restored.estimatedPickupTime, isNull);
    expect(restored.isPicked, isTrue);
    expect(restored.pickedAt, now);
  });

  test('dedupKey 由平台+取件码+取件点组成', () {
    expect(buildSample().dedupKey, 'taobao|3-1-2088|菜鸟驿站（东门店）');
  });

  test('copyWith 仅覆盖指定字段', () {
    final updated = buildSample().copyWith(code: '7-2-1001');

    expect(updated.code, '7-2-1001');
    expect(updated.platform, PickupPlatform.taobao);
    expect(updated.pickupPoint, '菜鸟驿站（东门店）');
  });

  test('PickupPlatform.fromName 未知名称回退淘宝', () {
    expect(PickupPlatform.fromName('cainiao'), PickupPlatform.cainiao);
    expect(PickupPlatform.fromName('unknown'), PickupPlatform.taobao);
  });
}
