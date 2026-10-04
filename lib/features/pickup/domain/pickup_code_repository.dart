import 'pickup_code.dart';

/// 取件码仓库接口（设计文档 5 节核心接口）。
///
/// 数据层提供 SQLite 实现，测试提供内存实现。
abstract class PickupCodeRepository {
  /// 新增取件码；platform+code+pickupPoint 相同则整行替换，返回记录 id
  Future<int> upsert(PickupCode code);

  /// 查询取件码列表，默认只看未取件，按创建时间倒序
  Future<List<PickupCode>> getAll({bool includePicked = false});

  /// 查询单条详情，不存在返回 null
  Future<PickupCode?> getById(int id);

  /// 标记取件状态；已取件时记录 pickedAt
  Future<int> markPicked(int id, {required bool picked});

  /// 删除单条记录
  Future<int> delete(int id);

  /// 清空已取件记录
  Future<int> clearPicked();
}
