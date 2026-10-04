import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../domain/pickup_code.dart';
import 'pickup_providers.dart';

/// 取件码详情页
class PickupDetailPage extends ConsumerWidget {
  const PickupDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(pickupDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('取件码详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (code) {
          if (code == null) {
            return const Center(child: Text('记录不存在或已删除'));
          }
          return _DetailView(code: code);
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除取件码'),
        content: const Text('确定要删除这条取件码吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(pickupListProvider.notifier).remove(id);
    if (context.mounted) context.goNamed(Routes.pickupList);
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.code});

  final PickupCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  code.code,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    code.isPicked ? '已取件' : '待取件',
                    style: TextStyle(
                      color: code.isPicked
                          ? theme.colorScheme.outline
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _InfoRow(label: '平台', value: code.platform.displayName),
              _InfoRow(label: '取件点', value: code.pickupPoint),
              if (code.courierCompany != null)
                _InfoRow(label: '快递公司', value: code.courierCompany!),
              if (code.estimatedPickupTime != null)
                _InfoRow(
                  label: '预计取件时间',
                  value: _format(code.estimatedPickupTime!),
                ),
              if (code.expireTime != null)
                _InfoRow(label: '有效期至', value: _format(code.expireTime!)),
              _InfoRow(label: '录入时间', value: _format(code.createTime)),
              if (code.pickedAt != null)
                _InfoRow(label: '取件时间', value: _format(code.pickedAt!)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!code.isPicked)
          FilledButton.icon(
            onPressed: () async {
              await ref
                  .read(pickupListProvider.notifier)
                  .markPicked(code.id!, picked: true);
              ref.invalidate(pickupDetailProvider(code.id!));
            },
            icon: const Icon(Icons.check),
            label: const Text('标记为已取件'),
          )
        else
          OutlinedButton.icon(
            onPressed: () async {
              await ref
                  .read(pickupListProvider.notifier)
                  .markPicked(code.id!, picked: false);
              ref.invalidate(pickupDetailProvider(code.id!));
            },
            icon: const Icon(Icons.undo),
            label: const Text('恢复为待取件'),
          ),
      ],
    );
  }

  static String _format(DateTime t) {
    final local = t.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
