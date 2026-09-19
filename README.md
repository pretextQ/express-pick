# 取件助手 (Express Pick)

聚合多个购物平台和快递服务的取件码，用户无需打开多个App即可快速查看和使用取件码。

## 开发方式

本项目采用 AI Agent 驱动开发：
- **Agent**：OpenCode 桌面端 + MiMo v2.5 Pro
- **职责分工**：Agent 负责编码和自测，人类负责需求评审和验收

## 功能特性

- 取件码聚合：聚合淘宝、拼多多、菜鸟等平台取件码
- 身份码展示：支持各平台身份码直接展示
- 取件提醒：新取件码自动通知（仅Android）
- 历史记录：查看历史取件记录（P2）

## 技术方案

- 淘宝：WebView加载官方H5身份码页面（阶段0已确认页面存在、无UA拦截）
- 拼多多：WebView加载H5取件页（P2可选优化）
- 菜鸟：共用淘宝登录态（阶段0已确认：登录iframe复用.taobao.com域Cookie）
- 快递100 API：补充查询取件码（阶段0结论：企业订阅制个人不可用，已移除）
- 降级方案：若H5路线不可行，取件码以手动录入为主，身份码仍走WebView展示

## 项目结构

```
express-pick/
├── 取件助手需求文档.md    # 完整需求文档
├── 取件助手设计文档.md    # 概要设计文档
├── AGENTS.md              # Agent开发约定
├── README.md              # 项目说明
└── ...                    # 后续开发代码
```

## 开发进度（MVP分期）

### 阶段0：技术验证 Spike（P0 前置）
- [x] 调研淘宝/菜鸟 H5 身份码页面是否存在，回填真实URL到 `assets/platform_config.json`
- [x] 验证淘宝H5登录页可行性（无UA拦截、手机号+验证码流程完整；滑块需真机人工复验）
- [x] 验证菜鸟与淘宝登录态（已确认：登录iframe复用.taobao.com域Cookie）
- [ ] 验证H5页面取件码数据能否通过JS提取（需登录态，遗留至P1前）
- [x] 调研快递100 API能否按单号查询取件码（结论：企业订阅制个人不可用，P2改短信/通知+手动录入）

> 详细结论见 [阶段0技术验证报告.md](阶段0技术验证报告.md)

### P0：核心功能
- [x] WebView聚合展示（淘宝、菜鸟身份码，真实URL来自阶段0验证）
- [x] 取件码手动录入与本地存储（SQLite）
- [x] 取件码列表与详情
- [x] Flutter项目骨架（Riverpod + GoRouter + sqflite + webview_flutter）

### P1：登录与同步
- [x] 登录态保持（WebView Cookie沙箱持久化；身份码页登录状态检测；设置页退出登录）
- [x] 前台自动同步框架（配置驱动H5抓取+解析器，平台未配置时自动跳过）
- [ ] H5取件码抓取上线（选择器待真机登录后回填，见阶段0报告遗留项）

### P2：扩展功能
- [ ] 通知/短信识别（仅Android）
- [x] 快递100补充查询（阶段0结论：企业订阅制个人不可用，已移除，改短信/通知识别+手动录入）
- [ ] 拼多多H5取件页（可选）
- [ ] 历史记录

### 已完成
- [x] 需求文档编写
- [x] 设计文档编写
- [x] README编写
- [x] 文档评审与修订（2026-09-19）
- [x] 阶段0技术验证Spike（2026-09-19）
- [x] P0核心功能开发（2026-09-19）

## 开发环境

- **主要目标平台：Android**（以Android真机验收为准；iOS功能对齐但优先级降低）
- Flutter 3.47.5 stable（本机安装于 `C:\flutter`，未加入PATH）
- 构建时使用中国镜像：`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`、`PUB_HOSTED_URL=https://pub.flutter-io.cn`
- 常用命令：`flutter analyze` / `flutter test` / `flutter run`（需Android SDK）

## 许可证

MIT License