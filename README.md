# 取件助手 (Express Pick)

聚合多个购物平台的身份码与取件码，用户无需打开多个 App 即可快速查看和使用取件码。

> **当前状态**（2026-09-19）：P0 核心功能与 P1 登录态/同步框架已完成并通过全部测试（25 个用例、analyze 零问题）；Android APK 构建环境已就绪，首次构建待完成。
> 接手开发前请先阅读 [docs/项目现状交接.md](docs/项目现状交接.md)。

## 核心路线

**WebView 加载平台官方 H5 页面**（阶段0已验证可行），不做平台逆向、不存储账号密码：
- 身份码：淘宝入口页自动跳转至菜鸟身份码 H5，登录态为 `.taobao.com` 域 Cookie
- 取件码：P0/P1 以手动录入为主，H5 抓取框架已就绪（选择器待真机登录后回填）
- 快递100 路线已否决（企业订阅制，个人不可用）

## 功能特性

- ✅ 身份码聚合：WebView 加载淘宝/菜鸟官方 H5 身份码页（仅允许 HTTPS 导航）
- ✅ 取件码管理：手动录入（表单校验）、SQLite 存储、列表/详情、标记已取件
- ✅ 登录态保持：Cookie 沙箱持久化、页面内登录状态检测、设置页一键退出
- ✅ 同步框架：配置驱动 H5 抓取编排 + 解析器（平台未配置时自动跳过）
- 🔲 P2 规划：Android 短信/通知识别取件码、历史记录

## 技术栈

| 组件 | 选型 |
|------|------|
| 框架 | Flutter 3.47 · Dart 3.13 |
| 状态管理 | Riverpod（AsyncNotifier） |
| 路由 | GoRouter |
| 本地存储 | sqflite |
| WebView | webview_flutter 4.14 |

**主要目标平台：Android 8.0+**（用户真机为安卓；iOS 功能对齐但优先级降低）

## 快速开始

本机环境与网络限制（Google/GitHub 被墙，需走国内镜像）详见[交接文档第 3、7 节](docs/项目现状交接.md)。核心命令：

```bash
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export ANDROID_HOME="C:\Android\Sdk"

/c/flutter/bin/flutter analyze          # 必须零问题
/c/flutter/bin/flutter test             # 全部通过
/c/flutter/bin/flutter build apk --release
```

## 文档索引

| 文档 | 说明 |
|------|------|
| [docs/项目现状交接.md](docs/项目现状交接.md) | ⭐ **当前进度、环境地图、踩坑记录、接手提示词** |
| [docs/AGENTS.md](docs/AGENTS.md) | 开发约定（代码规范/目录结构/提交规范） |
| [docs/取件助手需求文档.md](docs/取件助手需求文档.md) | 需求规格说明书与验收表 |
| [docs/取件助手设计文档.md](docs/取件助手设计文档.md) | 概要设计（架构/接口/数据结构） |
| [docs/阶段0技术验证报告.md](docs/阶段0技术验证报告.md) | H5 路线可行性验证结论 |
| [assets/platform_config.json](assets/platform_config.json) | 平台 URL 与选择器配置（H5 方案单一事实来源） |

## 开发进度（MVP 分期）

### 阶段0：技术验证 Spike ✅
- [x] 淘宝/菜鸟 H5 身份码页面存在性调研，真实 URL 已回填 `assets/platform_config.json`
- [x] 淘宝 H5 登录页可行性（无 UA 拦截；滑块需真机人工复验）
- [x] 菜鸟与淘宝登录态打通机制确认（登录 iframe 复用淘宝域 Cookie）
- [x] 快递100 API 调研（结论：企业订阅制个人不可用，路线移除）
- [ ] H5 取件码数据 JS 提取（需登录态，遗留至真机登录后）

### P0：核心功能 ✅
- [x] WebView 聚合展示（淘宝、菜鸟身份码）
- [x] 取件码手动录入与本地存储（SQLite）
- [x] 取件码列表与详情
- [x] Flutter 项目骨架

### P1：登录与同步 ✅（抓取上线待条件）
- [x] 登录态保持（Cookie 持久化、登录检测、退出登录）
- [x] 前台自动同步框架（配置驱动，未配置自动跳过）
- [ ] H5 取件码抓取上线（选择器待真机登录后回填）

### P2：扩展功能 🔲
- [x] 快递100 补充查询（已否决，改短信/通知+手动录入）
- [ ] 通知/短信识别（仅 Android）
- [ ] 拼多多 H5 取件页（可选）
- [ ] 历史记录

### 人工验收待办
- [ ] APK 安装到 Android 真机，验收 P0 功能
- [ ] 淘宝身份码 WebView 内登录，验证滑块可通过、身份码正常渲染

## 许可证

MIT License
