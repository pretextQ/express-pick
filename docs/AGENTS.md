# Agent 开发约定

## 项目概述

取件助手（Express Pick）- 聚合多个购物平台和快递服务的取件码App。

## 开发环境

- **Agent**：OpenCode 桌面端 + MiMo v2.5 Pro
- **框架**：Flutter 3.x + Dart 3.x
- **IDE**：Android Studio / VS Code

## 代码规范

### 命名规范
- 避免与SDK保留名冲突：平台枚举使用 `PickupPlatform`，不使用 `Platform`（与 dart:io / TargetPlatform 冲突）
- 类名：PascalCase（如 `PickupCodeRepository`）
- 变量/函数名：camelCase（如 `pickupCode`、`fetchPickupCodes`）
- 常量：camelCase（如 `defaultTimeout`）
- 文件名：snake_case（如 `pickup_code_repository.dart`）

### 格式规范
- 使用 `dart format` 格式化代码
- 行宽限制：80字符
- 缩进：2空格

### 注释规范
- 公开API必须添加文档注释
- 复杂逻辑添加行内注释
- 注释使用中文

## 目录结构

```
lib/
├── main.dart                # 应用入口
├── app/                     # 应用配置
│   ├── routes.dart          # 路由配置
│   └── theme.dart           # 主题配置
├── features/                # 功能模块
│   ├── auth/                # 认证模块
│   │   ├── data/            # 数据层
│   │   ├── domain/          # 领域层
│   │   └── presentation/    # 表现层
│   ├── pickup/              # 取件码模块
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/            # 设置模块
│       ├── data/
│       ├── domain/
│       └── presentation/
└── core/                    # 核心模块
    ├── network/             # 网络请求
    ├── storage/             # 存储
    └── utils/               # 工具类

assets/                      # 资源文件（项目根目录，需在 pubspec.yaml 的 flutter.assets 中声明）
└── platform_config.json     # 平台配置
```

## 常用命令

### 代码检查
```bash
# 静态分析
flutter analyze

# 格式化
dart format .
```

### 测试
```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/auth/taobao_login_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage
```

### 构建
```bash
# Android构建
flutter build apk

# iOS构建
flutter build ios
```

## 任务拆分原则

1. **小步迭代**：单个任务改动不超过3个文件（例外：`flutter create` 初始化、全局重命名等机械性任务不受限，但需在任务说明中注明）
2. **单一职责**：每个任务只解决一个问题
3. **可测试性**：每个任务必须有对应的测试用例（WebView/平台通道代码以mock层测试+人工验收替代）
4. **完成标准**：通过 `flutter analyze` 和 `flutter test`

## 提交规范

### Commit Message 格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型
- `feat`：新功能
- `fix`：修复bug
- `docs`：文档更新
- `style`：代码格式（不影响功能）
- `refactor`：重构
- `test`：测试相关
- `chore`：构建/工具相关

### 示例
```
feat(pickup): 添加取件码列表功能

- 实现取件码列表页面
- 添加取件码数据模型
- 集成Riverpod状态管理

Closes #123
```

## 分支管理

### 唯一远端与推送约定

- 自2026-10-19起，本项目只推送到 [GitHub 仓库](https://github.com/pretextQ/express-pick)。
- 本地唯一远端为 `origin`，指向 `https://github.com/pretextQ/express-pick.git`；`main` 跟踪 `origin/main`。
- 不向 Gitee 推送，不自动恢复旧远端或执行多远端同步；以后变更目标须由用户明确指定。
- 默认使用 `git push origin main`；功能分支使用 `git push -u origin <branch>`。
- 远端 URL 不包含令牌；凭证由本机 Git 凭证管理器处理，不写入文档或提交。

- `main`：主分支，稳定版本
- `develop`：开发分支
- `feature/*`：功能分支
- `fix/*`：修复分支

## 注意事项

1. **平台优先级**：以Android为主（用户真机为安卓），iOS功能对齐但验收以Android为准
2. **平台兼容性**：注意Android和iOS的差异
3. **权限处理**：仅Android支持短信和通知栏监听
4. **WebView安全**：使用HTTPS，注意JS注入安全
5. **数据安全**：登录态使用安全存储，不存储敏感信息
