import 'package:express_pick/features/pickup/domain/pickup_code.dart';
import 'package:express_pick/features/pickup/domain/pickup_code_repository.dart';

/// 内存实现的取件码仓库，用于测试
/// （sqlite 在 widget 测试的 FakeAsync 环境中无法返回结果，见 P0 记录）。
class MemoryPickupCodeRepository implements PickupCodeRepository {
  final Map<int, PickupCode> _store = {};
  var _nextId = 1;

  @override
  Future<int> upsert(PickupCode code) async {
    final existingId =
        code.id ??
        _store.values
            .where((c) => c.dedupKey == code.dedupKey)
            .map((c) => c.id)
            .firstOrNull;
    final id = existingId ?? _nextId++;
    _store[id] = code.copyWith(id: id);
    return id;
  }

  @override
  Future<List<PickupCode>> getAll({bool includePicked = false}) async {
    final codes =
        _store.values.where((c) => includePicked || !c.isPicked).toList()
          ..sort((a, b) => b.createTime.compareTo(a.createTime));
    return codes;
  }

  @override
  Future<PickupCode?> getById(int id) async => _store[id];

  @override
  Future<int> markPicked(int id, {required bool picked}) async {
    final code = _store[id];
    if (code == null) return 0;
    _store[id] = code.copyWith(
      isPicked: picked,
      pickedAt: picked ? DateTime.now() : null,
    );
    return 1;
  }

  @override
  Future<int> delete(int id) async => _store.remove(id) == null ? 0 : 1;

  @override
  Future<int> clearPicked() async {
    final removed = _store.values.where((c) => c.isPicked).toList();
    for (final code in removed) {
      _store.remove(code.id);
    }
    return removed.length;
  }
}
