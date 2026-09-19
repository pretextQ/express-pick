import 'pickup_platform.dart';

/// 取件码数据模型。
///
/// 合并去重唯一键：platform + code + pickupPoint。
/// isPicked 流转：同步/手动确认后标记已取件并记录 pickedAt，P2 历史记录基于此。
class PickupCode {
  const PickupCode({
    this.id,
    required this.code,
    required this.platform,
    required this.pickupPoint,
    this.courierCompany,
    this.estimatedPickupTime,
    this.expireTime,
    required this.createTime,
    this.isPicked = false,
    this.pickedAt,
  });

  final int? id;
  final String code;
  final PickupPlatform platform;

  /// 取件点（驿站/快递柜名称）
  final String pickupPoint;

  /// 快递公司
  final String? courierCompany;

  /// 预计取件时间
  final DateTime? estimatedPickupTime;

  /// 取件码有效期（如快递柜）
  final DateTime? expireTime;
  final DateTime createTime;
  final bool isPicked;

  /// 标记已取时间（isPicked=true 时有值）
  final DateTime? pickedAt;

  /// 合并去重唯一键
  String get dedupKey => '${platform.name}|$code|$pickupPoint';

  PickupCode copyWith({
    int? id,
    String? code,
    PickupPlatform? platform,
    String? pickupPoint,
    String? courierCompany,
    DateTime? estimatedPickupTime,
    DateTime? expireTime,
    DateTime? createTime,
    bool? isPicked,
    DateTime? pickedAt,
  }) {
    return PickupCode(
      id: id ?? this.id,
      code: code ?? this.code,
      platform: platform ?? this.platform,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      courierCompany: courierCompany ?? this.courierCompany,
      estimatedPickupTime: estimatedPickupTime ?? this.estimatedPickupTime,
      expireTime: expireTime ?? this.expireTime,
      createTime: createTime ?? this.createTime,
      isPicked: isPicked ?? this.isPicked,
      pickedAt: pickedAt ?? this.pickedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'platform': platform.name,
      'pickup_point': pickupPoint,
      'courier_company': courierCompany,
      'estimated_pickup_time': estimatedPickupTime?.millisecondsSinceEpoch,
      'expire_time': expireTime?.millisecondsSinceEpoch,
      'create_time': createTime.millisecondsSinceEpoch,
      'is_picked': isPicked ? 1 : 0,
      'picked_at': pickedAt?.millisecondsSinceEpoch,
    };
  }

  factory PickupCode.fromMap(Map<String, dynamic> map) {
    return PickupCode(
      id: map['id'] as int?,
      code: map['code'] as String,
      platform: PickupPlatform.fromName(map['platform'] as String),
      pickupPoint: map['pickup_point'] as String,
      courierCompany: map['courier_company'] as String?,
      estimatedPickupTime: _fromMillis(map['estimated_pickup_time'] as int?),
      expireTime: _fromMillis(map['expire_time'] as int?),
      createTime: DateTime.fromMillisecondsSinceEpoch(
        map['create_time'] as int,
      ),
      isPicked: (map['is_picked'] as int? ?? 0) == 1,
      pickedAt: _fromMillis(map['picked_at'] as int?),
    );
  }

  static DateTime? _fromMillis(int? millis) {
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
