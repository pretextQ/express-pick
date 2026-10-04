import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pickup_code_repository.dart';
import '../data/pickup_sync_service.dart';
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

  /// 同步平台取件码后刷新列表，返回用于提示的文案。
  /// 同步失败不影响本地刷新（静默降级为 P0 行为）。
  Future<String> syncAndRefresh() async {
    var message = '已刷新';
    try {
      final sync = await ref.read(syncServiceProvider.future);
      final result = await sync.syncAll();
      if (result.fetched > 0) {
        message = '同步到 ${result.fetched} 条取件码';
      }
    } catch (_) {
      // 配置加载失败或抓取异常时降级为本地刷新
    }
    await refresh();
    return message;
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
