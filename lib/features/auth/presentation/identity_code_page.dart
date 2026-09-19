import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/platform_config.dart';
import '../../pickup/domain/pickup_platform.dart';

/// 身份码页面：WebView 加载平台官方 H5（阶段0已验证真实地址）。
///
/// 登录在页面内完成（手机号+短信验证码），登录态由 WebView CookieManager
/// 持久化；仅允许 HTTPS 导航。
class IdentityCodePage extends ConsumerStatefulWidget {
  const IdentityCodePage({super.key, required this.platform});

  final PickupPlatform platform;

  @override
  ConsumerState<IdentityCodePage> createState() => _IdentityCodePageState();
}

class _IdentityCodePageState extends ConsumerState<IdentityCodePage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (e) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = e.description;
            });
          },
          onNavigationRequest: (request) {
            // 安全设计：仅允许 HTTPS 页面
            final url = request.url;
            if (url == 'about:blank' || url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('about:blank'));
    _loadIdentityUrl();
  }

  Future<void> _loadIdentityUrl() async {
    final config = await ref.read(platformConfigProvider.future);
    final url = config.identityUrl(widget.platform);
    if (!mounted) return;
    if (url == null) {
      setState(() {
        _loading = false;
        _error = '未配置 ${widget.platform.displayName} 身份码地址';
      });
      return;
    }
    await _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platform.displayName}身份码'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '如未登录，请在页面内完成登录（手机号+短信验证码），'
                      '登录态将自动保持',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const LinearProgressIndicator(),
                if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('页面加载失败：$_error'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _reload,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
