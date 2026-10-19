# 取件助手（Express Pick）

将分散的取件信息整理为本地清单，快速查看取件码、确认已取，并打开官方身份码入口。主要面向 Android，使用 Flutter 开发。

> 更新于 2026-10-19：已完成参考 Parcel 的需求、设计和 M0—M5 实施计划，功能实现仍处于现有手动录入与 H5 框架阶段。文本解析、通知／短信识别、地址分组和小组件尚未实现。
>
> 唯一远端：[GitHub · pretextQ/express-pick](https://github.com/pretextQ/express-pick)。接手开发请先读 [开发约定](docs/AGENTS.md) 和 [项目交接](docs/项目现状交接.md)。

## 当前能力

| 功能 | 实际状态 |
| --- | --- |
| 手动录入取件码 | 已有表单校验与 SQLite 存储 |
| 列表与详情 | 已有待取列表、详情、标记已取和恢复操作；独立历史页面待开发 |
| 设置 | 已有清空已取记录和清除 WebView Cookie 入口 |
| 淘宝／菜鸟身份码 | 已有官方 H5 WebView 页面；完整登录、会话保持和正式包联网仍待修复／真机验证 |
| H5 取件码同步 | 仅有编排、提取脚本和解析器；未配置取件页及选择器，当前不能自动抓取 |

现有代码需要先修复重复写入覆盖、WebView 错误处理等问题，详见 [设计文档的审查问题清单](docs/取件助手设计文档.md#7-本轮-review-问题与前置修复)。本轮文档更新未修复这些问题，也未重新运行 Flutter 测试或构建。

## 开发路线

参考 [Parcel](https://github.com/shareven/parcel) 的本地解析、柜号／格口识别、地址分组、自定义规则及桌面卡片体验，继续使用本项目 Flutter 架构。

取件码采集按“主动粘贴／手动录入 → Android 通知 → 可选短信”逐步实现，所有来源共用解析和去重流程。H5 身份码继续保留，官方 App 身份码跳转为计划功能；H5 自动抓取在条件成熟后独立启用。

| 阶段 | 计划内容 | 状态 |
| --- | --- | --- |
| M0 基础可靠性 | 正式包联网、WebView 登录与错误处理、稳定 ID 合并、状态一致性 | 待实施 |
| M1 本地识别闭环 | 数据迁移、文本解析、粘贴预览、待确认、幂等去重与历史 | 待实施 |
| M2 通知入口 | 来源白名单、权限状态、原生持久暂存、App 恢复后导入 | 待实施 |
| M3 Parcel 常用体验 | 可选短信、自定义规则、地址标签、备注分享、官方 App 跳转 | 待实施 |
| M4 桌面与后台 | 标准小组件、大字／暗色适配、受系统调度的后台解析 | 待实施 |
| M5 平台扩展 | 通过真机登录和 DOM 验证后的可选 H5 抓取 | 待条件 |

首个可用版本以 M0—M2 为出口。M2 的后台目标是可靠暂存已收到的候选，恢复 App 后解析；后台解析与小组件更新属于 M4，受系统调度限制。详细任务和验收见 [实施计划](docs/取件助手设计文档.md#8-实施计划)。

## 平台与数据边界

- **Android 8.0+ 优先**：通知和短信入口按需授权，拒绝权限不影响已有本地录入和查看功能。
- **iOS**：沿用本地功能方向，不支持读取系统短信或其他 App 通知；部署下限以后续实际构建验证为准。
- **本地优先**：计划中的规则解析离线运行；官方 H5 页面仍需联网，不能将整个应用描述为完全离线。
- **身份码**：只展示官方页面或跳转官方 App，不生成、提取或缓存身份码；登录由用户本人完成。
- **范围**：当前不计划物流追踪、寄件、快递100取件码接口、云端 AI 或 OCR 截图识别。

## 技术栈

| 组件 | 当前选型 |
| --- | --- |
| 应用框架 | Flutter / Dart（pubspec 要求 Dart `^3.13.4`） |
| 状态管理 | flutter_riverpod |
| 路由 | go_router |
| 本地数据库 | sqflite |
| 官方 H5 页面 | webview_flutter |
| Android 系统接入 | 计划使用 Kotlin 与 Flutter 平台通道 |

依赖约束及锁定版本以 [pubspec.yaml](pubspec.yaml) 和 [pubspec.lock](pubspec.lock) 为准。

## 本地开发

先安装满足 Dart 版本约束的 Flutter SDK，以及 Android SDK、与当前 Gradle 配置匹配的 JDK，并将 Flutter 加入 PATH。旧交接中的 `C:\flutter` 路径在当前机器上不存在，使用前应确认实际工具链，不能直接沿用历史环境。

```powershell
git clone https://github.com/pretextQ/express-pick.git
cd express-pick
flutter --version
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter run
```

网络需要镜像时，可在当前 PowerShell 会话按需设置：

```powershell
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
# ANDROID_HOME 使用本机实际 Android SDK 路径。
```

Android 开发验收包：

```powershell
flutter build apk --release
```

预期产物：`build/app/outputs/flutter-apk/app-release.apk`。当前 release 配置使用 debug 签名，用于开发验收；完整真机验收仍待执行。

每个代码任务须运行 `flutter analyze` 与 `flutter test`；平台通道和 WebView 还需 mock 与真机验收。旧环境曾记录25个测试通过，本 README 不将历史结果作为当前分支的验证结论。

## 文档索引

| 文档 | 内容 |
| --- | --- |
| [开发约定](docs/AGENTS.md) | 编码、测试、小步提交及 GitHub 唯一推送约定 |
| [需求规格](docs/取件助手需求文档.md) | R01—R14 功能、平台边界与验收要求 |
| [设计与实施计划](docs/取件助手设计文档.md) | Parcel 固定源码依据、架构、迁移、去重与 M0—M5 任务 |
| [项目现状交接](docs/项目现状交接.md) | 实际进度、已知问题、环境与下一步 |
| [阶段0验证报告](docs/阶段0技术验证报告.md) | 历史浏览器调研，不等同于真机 WebView 登录通过 |
| [平台配置](assets/platform_config.json) | H5 URL 与选择器；未验证的抓取保持关闭 |

## 参考项目

[Parcel－取件码](https://github.com/shareven/parcel) 是本项目当前的主要参考。已核实的源码、固定提交与复用方式列于 [设计文档第2节](docs/取件助手设计文档.md#2-parcel-源码依据与复用边界)。目前只完成方案设计；后续实际移植代码时记录来源并保留原项目的 MIT 版权及许可文本。
