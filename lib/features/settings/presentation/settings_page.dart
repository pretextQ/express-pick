import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/platform_config.dart';
import '../../auth/data/webview_auth_repository.dart';
import '../../pickup/presentation/pickup_providers.dart';

/// 设置页（平台配置展示 + 账号管理 + 已取件记录清理）
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(platformConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader(title: '平台配置'),
          configAsync.maybeWhen(
            data: (config) => Column(
              children: [
                for (final platform in config.identityPlatforms)
                  ListTile(
                    leading: const Icon(Icons.qr_code_2),
                    title: Text('${platform.displayName}身份码'),
                    subtitle: Text(config.identityUrl(platform)!),
                  ),
              ],
            ),
            orElse: () => const ListTile(
              leading: Icon(Icons.qr_code_2),
              title: Text('平台配置加载中…'),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: '账号'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            subtitle: const Text('清除淘宝/菜鸟登录态（WebView Cookie），不影响本地取件码'),
            onTap: () => _confirmLogout(context, ref),
          ),
          const Divider(),
          const _SectionHeader(title: '数据'),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('清空已取件记录'),
            onTap: () => _confirmClear(context, ref),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('取件助手 v0.1.0 · P0'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('将清除所有平台的登录态，下次使用需重新登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).logout();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已清除登录态，请重新登录')));
    }
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空已取件记录'),
        content: const Text('已取件的历史记录将被删除，且不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(pickupListProvider.notifier).clearPicked();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已清空已取件记录')));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
