import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/config/platform_config.dart';
import '../domain/pickup_code.dart';
import '../domain/pickup_platform.dart';
import 'pickup_providers.dart';

/// 取件码列表页（P0 首页；P1 起支持前台自动同步）
class PickupListPage extends ConsumerStatefulWidget {
  const PickupListPage({super.key});

  @override
  ConsumerState<PickupListPage> createState() => _PickupListPageState();
}

class _PickupListPageState extends ConsumerState<PickupListPage> {
  @override
  void initState() {
    super.initState();
    // P1：前台打开时自动同步（平台未配置抓取地址时为空操作）
    Future.microtask(() {
      if (mounted) ref.read(pickupListProvider.notifier).syncAndRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(platformConfigProvider);
    final listAsync = ref.watch(pickupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('取件助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => context.pushNamed(Routes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final messenger = ScaffoldMessenger.of(context);
          final message = await ref
              .read(pickupListProvider.notifier)
              .syncAndRefresh();
          if (mounted) {
            messenger.showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            configAsync.maybeWhen(
              data: (config) =>
                  _IdentityCodeBar(platforms: config.identityPlatforms),
              orElse: () => const SizedBox.shrink(),
            ),
            listAsync.when(
              data: (codes) {
                if (codes.isEmpty) {
                  return const _EmptyPlaceholder();
                }
                return Column(
                  children: [
                    for (final code in codes)
                      _PickupCodeTile(
                        code: code,
                        onTap: () => context.pushNamed(
                          Routes.pickupDetail,
                          pathParameters: {'id': '${code.id}'},
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('加载失败：$e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(Routes.pickupAdd),
        icon: const Icon(Icons.add),
        label: const Text('录入取件码'),
      ),
    );
  }
}

/// 身份码快捷入口（阶段0已验证：淘宝/菜鸟共用淘宝登录态）
class _IdentityCodeBar extends StatelessWidget {
  const _IdentityCodeBar({required this.platforms});

  final List<PickupPlatform> platforms;

  @override
  Widget build(BuildContext context) {
    if (platforms.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        children: [
          for (final platform in platforms)
            ActionChip(
              avatar: const Icon(Icons.qr_code_2, size: 18),
              label: Text('${platform.displayName}身份码'),
              onPressed: () => context.pushNamed(
                Routes.identityCode,
                pathParameters: {'platform': platform.name},
              ),
            ),
        ],
      ),
    );
  }
}

/// 空列表占位
class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('暂无取件码'),
          const SizedBox(height: 4),
          Text(
            '点击右下角按钮手动录入，或点上方身份码去平台查看',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// 取件码列表项
class _PickupCodeTile extends StatelessWidget {
  const _PickupCodeTile({required this.code, required this.onTap});

  final PickupCode code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          code.code,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        subtitle: Text(
          '${code.platform.displayName} · ${code.pickupPoint}'
          '${code.courierCompany == null ? '' : ' · ${code.courierCompany}'}',
        ),
        trailing: Text(
          _formatTime(code.createTime),
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final t = time.toLocal();
    return '${t.month}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
