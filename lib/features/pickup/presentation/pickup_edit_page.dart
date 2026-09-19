import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../domain/pickup_code.dart';
import '../domain/pickup_platform.dart';
import 'pickup_providers.dart';

/// 取件码手动录入页（P0 不做 H5 抓取，取件码来源为用户手动录入）
class PickupEditPage extends ConsumerStatefulWidget {
  const PickupEditPage({super.key});

  @override
  ConsumerState<PickupEditPage> createState() => _PickupEditPageState();
}

class _PickupEditPageState extends ConsumerState<PickupEditPage> {
  final _formKey = GlobalKey<FormState>();
  PickupPlatform _platform = PickupPlatform.taobao;
  DateTime? _estimatedPickupTime;

  final _codeController = TextEditingController();
  final _pointController = TextEditingController();
  final _courierController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _pointController.dispose();
    _courierController.dispose();
    super.dispose();
  }

  Future<void> _pickEstimatedTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _estimatedPickupTime ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_estimatedPickupTime ?? now),
    );
    if (time == null) return;
    setState(() {
      _estimatedPickupTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final code = PickupCode(
      code: _codeController.text.trim(),
      platform: _platform,
      pickupPoint: _pointController.text.trim(),
      courierCompany: _courierController.text.trim().isEmpty
          ? null
          : _courierController.text.trim(),
      estimatedPickupTime: _estimatedPickupTime,
      createTime: DateTime.now(),
    );
    await ref.read(pickupListProvider.notifier).add(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已保存取件码')));
    context.goNamed(Routes.pickupList);
  }

  static String _format(DateTime t) {
    final local = t.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('录入取件码')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<PickupPlatform>(
              key: const Key('platform_field'),
              initialValue: _platform,
              decoration: const InputDecoration(
                labelText: '平台',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final platform in PickupPlatform.values)
                  DropdownMenuItem(
                    value: platform,
                    child: Text(platform.displayName),
                  ),
              ],
              onChanged: (v) => setState(() => _platform = v ?? _platform),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('code_field'),
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: '取件码 *',
                hintText: '如：3-1-2088',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入取件码' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('point_field'),
              controller: _pointController,
              decoration: const InputDecoration(
                labelText: '取件点 *',
                hintText: '如：菜鸟驿站（东门店）',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入取件点' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _courierController,
              decoration: const InputDecoration(
                labelText: '快递公司（选填）',
                hintText: '如：中通',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(
                _estimatedPickupTime == null
                    ? '预计取件时间（选填）'
                    : '预计取件时间：${_format(_estimatedPickupTime!)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickEstimatedTime,
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('save_button'),
              onPressed: _save,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
