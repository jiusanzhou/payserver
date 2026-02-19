# PayServer Agent

**易付** - 个人收款通知监听客户端

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

## 功能

- 📱 后台监听支付宝/微信收款通知
- 🔄 自动上报交易记录到服务端
- 📊 本地数据统计
- 🔗 扫码绑定服务器
- 🌙 深色模式支持

## 截图

| 首页 | 服务器管理 | 统计 | 设置 |
|:---:|:---:|:---:|:---:|
| ![Home](../assets/home.jpg) | ![Servers](../assets/servers.jpg) | ![Analytics](../assets/analytics.jpg) | ![Settings](../assets/settings.jpg) |

## 快速开始

### 环境要求

- Flutter 3.10+
- Android SDK 21+
- Android Studio / VS Code

### 安装依赖

```bash
flutter pub get
```

### 代码生成

项目使用 Drift (数据库) 和 Freezed (模型)，需要先生成代码：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 运行

```bash
# Debug 模式
flutter run

# Release APK (arm64, 推荐)
flutter build apk --release --target-platform android-arm64

# Release APK (全架构, 约73MB)
flutter build apk --release

# App Bundle (Google Play)
flutter build appbundle --release
```

## 项目结构

```
lib/
├── core/                 # 核心功能
│   ├── services/         # 后台服务 (通知监听)
│   ├── theme/            # 主题配置
│   └── utils/            # 工具类
├── data/                 # 数据层
│   ├── api/              # API 客户端
│   └── datasources/      # 本地数据库 (Drift)
├── domain/               # 领域层
│   └── entities/         # 实体模型 (Freezed)
├── presentation/         # 表现层
│   ├── pages/            # 页面
│   └── providers/        # 状态管理 (Riverpod)
└── main.dart             # 入口
```

## 技术栈

| 组件 | 说明 |
|------|------|
| [Riverpod](https://riverpod.dev/) | 状态管理 |
| [Drift](https://drift.simonbinder.eu/) | 本地数据库 |
| [Freezed](https://pub.dev/packages/freezed) | 不可变模型 |
| [fl_chart](https://pub.dev/packages/fl_chart) | 图表组件 |
| [mobile_scanner](https://pub.dev/packages/mobile_scanner) | 二维码扫描 |
| [flutter_notification_listener](https://pub.dev/packages/flutter_notification_listener) | 通知监听 |

## 权限说明

应用需要以下权限：

| 权限 | 用途 |
|------|------|
| 通知访问 | 监听支付通知 |
| 相机 | 扫码绑定 |
| 网络 | 上报数据 |
| 前台服务 | 后台持续监听 |

## 配置

### 绑定服务器

1. 在服务端 Admin 后台创建 Agent
2. 使用 Agent 扫描二维码完成绑定
3. 或手动输入服务器地址和 Ticket

### 二维码格式

```json
{
  "host": "https://pay.example.com",
  "ticket": "xxxxxxxx",
  "name": "服务器名称"
}
```

或 URL 格式：
```
payserver://bind?host=https://pay.example.com&ticket=xxxxxxxx&name=服务器名称
```

## 开发

### 添加新页面

1. 在 `lib/presentation/pages/` 创建页面文件
2. 在 `lib/main.dart` 注册路由
3. 如需状态管理，在 `lib/presentation/providers/` 添加 Provider

### 添加新实体

1. 在 `lib/domain/entities/` 创建 Freezed 模型
2. 运行 `flutter pub run build_runner build`
3. 在 `lib/data/datasources/tables.dart` 添加表定义 (如需持久化)

## 常见问题

### 通知监听不生效？

1. 确认已授予「通知访问」权限
2. 检查电池优化设置，将应用设为「不限制」
3. 部分厂商 ROM 需要额外开启「自启动」权限

### 收不到微信/支付宝通知？

1. 确认微信/支付宝已开启收款到账提醒
2. 确认系统未屏蔽这些应用的通知

## License

MIT - 详见 [LICENSE](../LICENSE)
