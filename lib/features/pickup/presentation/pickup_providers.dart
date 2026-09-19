import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pickup_code_repository.dart';
import '../domain/pickup_code.dart';
import '../domain/pickup_code_repository.dart';

/// 取件码列表控制器：负责列表加载、手动刷新与增删改后的列表同步
class PickupListController extends AsyncNotifier<List<PickupCode>> {
  @override
  Future<List<PickupCode>> build() {
    return ref.watch(repositoryProvider).getAll();
  }

  PickupCodeRepository get _repo => ref.read(repositoryProvider);

  /// 手动刷新（P0 从本地库重载，P1 接入平台同步）
  Future<void> refresh() async {
    state = await AsyncValue.guard(_repo.getAll);
  }

  /// 新增/更新取件码
  Future<void> add(PickupCode code) async {
    await _repo.upsert(code);
    await refresh();
  }

  /// 标记取件状态
  Future<void> markPicked(int id, {required bool picked}) async {
    await _repo.markPicked(id, picked: picked);
    await refresh();
  }

  /// 删除取件码
  Future<void> remove(int id) async {
    await _repo.delete(id);
    await refresh();
  }

  /// 清空已取件记录
  Future<void> clearPicked() async {
    await _repo.clearPicked();
    await refresh();
  }
}

/// 取件码列表提供者
final pickupListProvider =
    AsyncNotifierProvider<PickupListController, List<PickupCode>>(
      PickupListController.new,
    );

/// 取件码详情提供者
final pickupDetailProvider = FutureProvider.family<PickupCode?, int>((ref, id) {
  return ref.watch(repositoryProvider).getById(id);
});
