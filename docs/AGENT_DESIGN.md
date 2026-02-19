# Flutter Agent 升级设计

> Agent 数据采集端升级方案：Flutter 3.x + 现代架构

## 目录

- [升级目标](#升级目标)
- [现有架构分析](#现有架构分析)
- [升级方案](#升级方案)
- [新架构设计](#新架构设计)
- [关键模块升级](#关键模块升级)
- [迁移计划](#迁移计划)
- [测试策略](#测试策略)

---

## 升级目标

1. **Flutter 3.x**: 从 Flutter 2.x 升级到 3.x，支持 Dart 3 空安全
2. **现代状态管理**: 从 Provider 迁移到 Riverpod 2.x
3. **增强可靠性**: 改进后台服务、离线同步、错误恢复
4. **UI 现代化**: Material 3 设计、响应式布局
5. **代码架构**: Clean Architecture + 领域驱动设计
6. **性能优化**: 电池优化、网络效率

---

## 现有架构分析

### 当前技术栈

```yaml
# pubspec.yaml (当前)
environment:
  sdk: ">=2.7.0 <3.0.0"

dependencies:
  flutter: sdk
  velocity_x: ^3.2.0
  qr_code_scanner: ^0.4.0
  qr_flutter: ^4.0.0
  workmanager: ^0.4.0
  sqflite: ^2.0.0+3
  path_provider: ^2.0.2
  provider: ^5.0.0
  shared_preferences: ^2.0.6
  synchronized: ^3.0.0
  flutter_form_builder: ^6.0.1
  flutter_notification_listener: (本地)
  flutter_zoekits: (本地)
```

### 当前架构

```
lib/
|-- main.dart           # 应用入口
|-- models/             # 数据模型 + 业务逻辑混合
|   |-- models.dart     # ModelFactory 单例
|   |-- server.dart     # Server 模型 + ServerModel
|   +-- transaction.dart # PayTransaction + PayTransactionModel
|-- pages/              # UI 页面
|-- views/              # 可复用视图
|-- store/              # SQLite 数据库
+-- styles/             # 样式
```

### 问题分析

| 问题 | 影响 | 优先级 |
|------|------|--------|
| Dart 2.x 不支持空安全 | 编译警告、潜在空指针 | 高 |
| Model 层职责混乱 | 难以测试、维护 | 高 |
| 后台服务不稳定 | 通知遗漏 | 高 |
| 无网络状态处理 | 离线时数据丢失 | 中 |
| UI 组件老旧 | 用户体验差 | 中 |
| 无错误上报 | 难以定位问题 | 中 |

---

## 升级方案

### 技术栈升级

```yaml
# pubspec.yaml (升级后)
environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # 网络
  dio: ^5.4.0
  retrofit: ^4.1.0
  connectivity_plus: ^5.0.0
  
  # 本地存储
  drift: ^2.15.0           # SQLite ORM (替代 sqflite)
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  
  # UI
  flutter_hooks: ^0.20.0
  go_router: ^13.0.0
  flutter_animate: ^4.3.0
  
  # 工具
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  fpdart: ^1.1.0           # 函数式编程
  
  # 通知监听
  flutter_notification_listener: ^3.0.0  # 升级版本
  
  # 后台任务
  workmanager: ^0.5.2
  flutter_background_service: ^5.0.0
  
  # 二维码
  mobile_scanner: ^4.0.0   # 替代 qr_code_scanner
  qr_flutter: ^4.1.0
  
  # 监控
  sentry_flutter: ^7.15.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  retrofit_generator: ^8.1.0
  riverpod_generator: ^2.3.0
  drift_dev: ^2.15.0
  mockito: ^5.4.0
  bloc_test: ^9.1.0
```

### 架构升级

```
lib/
|-- main.dart
|-- app/
|   |-- app.dart           # App 配置
|   +-- router.dart        # 路由配置
|
|-- core/                  # 核心基础设施
|   |-- constants/
|   |-- extensions/
|   |-- errors/
|   |-- network/
|   |   |-- dio_client.dart
|   |   +-- network_info.dart
|   |-- services/
|   |   |-- notification_service.dart
|   |   |-- background_service.dart
|   |   +-- sync_service.dart
|   +-- utils/
|
|-- data/                  # 数据层
|   |-- datasources/
|   |   |-- local/
|   |   |   |-- database.dart
|   |   |   |-- transaction_dao.dart
|   |   |   +-- server_dao.dart
|   |   +-- remote/
|   |       |-- api_client.dart
|   |       +-- api_service.dart
|   |-- models/
|   |   |-- transaction_model.dart
|   |   |-- server_model.dart
|   |   +-- sync_status.dart
|   +-- repositories/
|       |-- transaction_repository_impl.dart
|       +-- server_repository_impl.dart
|
|-- domain/               # 领域层
|   |-- entities/
|   |   |-- transaction.dart
|   |   |-- server.dart
|   |   +-- pay_type.dart
|   |-- repositories/
|   |   |-- transaction_repository.dart
|   |   +-- server_repository.dart
|   +-- usecases/
|       |-- process_notification.dart
|       |-- sync_transactions.dart
|       +-- manage_servers.dart
|
|-- presentation/         # 表现层
|   |-- providers/
|   |   |-- transaction_provider.dart
|   |   |-- server_provider.dart
|   |   +-- sync_provider.dart
|   |-- pages/
|   |   |-- home/
|   |   |-- servers/
|   |   |-- analytics/
|   |   +-- settings/
|   |-- widgets/
|   |   |-- transaction_card.dart
|   | server_card.dart
|   |   +-- stats_panel.dart
|   +-- themes/
|       |-- app_theme.dart
|       +-- colors.dart
|
+-- l10n/                 # 国际化
    +-- app_zh.arb
```

---

## 新架构设计

### 分层架构

```
+------------------------------------------------------------------+
|                      Presentation Layer                           |
|  (Pages, Widgets, Providers)                                      |
|  - Riverpod for state management                                  |
|  - go_router for navigation                                       |
+--------------------------------+---------------------------------+
                                 |
+--------------------------------v---------------------------------+
|                        Domain Layer                               |
|  (Entities, Repositories Interface, Use Cases)                    |
|  - Pure Dart, no Flutter dependencies                             |
|  - Business logic                                                 |
+--------------------------------+---------------------------------+
                                 |
+--------------------------------v---------------------------------+
|                         Data Layer                                |
|  (Models, Data Sources, Repository Implementations)               |
|  - Drift for local database                                       |
|  - Dio + Retrofit for API                                         |
+------------------------------------------------------------------+
```

### 依赖注入

```dart
// lib/main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化服务
  await initServices();
  
  runApp(
    ProviderScope(
      child: PayAgentApp(),
    ),
  );
}

// lib/core/di/providers.dart
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(Dio());
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    localDataSource: ref.read(transactionLocalDataSourceProvider),
    remoteDataSource: ref.read(transactionRemoteDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});
```

---

## 关键模块升级

### 1. 通知监听服务

```dart
// lib/core/services/notification_service.dart
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

@riverpod
class NotificationService extends _$NotificationService {
  late final NotificationsListener _listener;
  
  @override
  Future<void> build() async {
    _listener = NotificationsListener();
    await _initializeListener();
  }
  
  Future<void> _initializeListener() async {
    await NotificationsListener.initialize(
      callbackHandle: _notificationCallback,
    );
    
    // 请求通知权限
    final hasPermission = await _listener.hasPermission ?? false;
    if (!hasPermission) {
      await _listener.openPermissionSettings();
    }
  }
  
  @pragma('vm:entry-point')
  static void _notificationCallback(NotificationEvent event) async {
    // 后台回调 - 在 isolate 中执行
    final transaction = TransactionParser.parse(event);
    if (transaction == null) return;
    
    // 使用后台数据库实例保存
    final db = await BackgroundDatabase.instance;
    await db.transactionDao.insert(transaction);
    
    // 通知主 isolate 更新 UI
    final sendPort = IsolateNameServer.lookupPortByName('notification_port');
    sendPort?.send(transaction.toJson());
  }
}
```

### 2. 交易解析器

```dart
// lib/domain/usecases/process_notification.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'process_notification.freezed.dart';

class ProcessNotification {
  Either<Failure, Transaction> call(NotificationEvent event) {
    try {
      final transaction = _parseTransaction(event);
      if (transaction == null) {
        return left(Failure.invalidNotification());
      }
      return right(transaction);
    } catch (e) {
      return left(Failure.parsingError(e.toString()));
    }
  }
  
  Transaction? _parseTransaction(NotificationEvent event) {
    final payType = _getPayType(event.packageName);
    if (payType == PayType.unknown) return null;
    
    final amount = _parseAmount(event, payType);
    if (amount == null) return null;
    
    return Transaction(
      id: const Uuid().v4(),
      type: payType,
      amount: amount,
      timestamp: DateTime.now(),
      raw: event.toString(),
      syncStatus: SyncStatus.pending,
    );
  }
  
  PayType _getPayType(String? packageName) {
    return switch (packageName) {
      'com.tencent.mm' => PayType.wechat,
      'com.eg.android.AlipayGphone' => PayType.alipay,
      _ => PayType.unknown,
    };
  }
  
  int? _parseAmount(NotificationEvent event, PayType type) {
    final text = type == PayType.wechat ? event.text : event.title;
    if (text == null) return null;
    
    // 提取金额
    final regex = RegExp(r'(\d+\.?\d*)');
    final match = regex.firstMatch(text);
    if (match == null) return null;
    
    final value = double.tryParse(match.group(1)!);
    if (value == null) return null;
    
    return (value * 100).round(); // 转换为分
  }
}
```

### 3. 数据库层 (Drift)

```dart
// lib/data/datasources/local/database.dart
import 'package:drift/drift.dart';

part 'database.g.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text()();
  TextColumn get type => text()(); // wechat, alipay
  IntColumn get amount => integer()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get raw => text().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Servers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get host => text()();
  TextColumn get version => text().withDefault(const Constant('v1'))();
  TextColumn get uid => text().nullable()();
  TextColumn get ticket => text()();
  TextColumn get status => text().withDefault(const Constant('normal'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Transactions, Servers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 2;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // 添加 syncStatus 字段
          await m.addColumn(transactions, transactions.syncStatus);
        }
      },
    );
  }
}

// DAO
@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase> 
    with _$TransactionDaoMixin {
  TransactionDao(super.db);
  
  Future<List<Transaction>> getPendingSync() {
    return (select(transactions)
      ..where((t) => t.syncStatus.equals(0))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();
  }
  
  Future<void> markSynced(String uid) {
    return (update(transactions)..where((t) => t.uid.equals(uid)))
      .write(TransactionsCompanion(syncStatus: const Value(1)));
  }
  
  Stream<List<Transaction>> watchToday() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return (select(transactions)
      ..where((t) => t.createdAt.isBiggerOrEqualValue(startOfDay))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
  }
}
```

### 4. API 客户端 (Retrofit)

```dart
// lib/data/datasources/remote/api_service.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;
  
  @POST('/api/v1/records')
  Future<ApiResponse<void>> createRecord(@Body() CreateRecordRequest request);
  
  @POST('/api/v1/agent/{uid}/heartbeat')
  Future<ApiResponse<void>> heartbeat(@Path('uid') String agentUid);
  
  @POST('/api/v1/agents')
  Future<ApiResponse<AgentResponse>> registerAgent(
    @Body() RegisterAgentRequest request,
  );
  
  @GET('/api/v1/agent/{uid}/apps')
  Future<ApiResponse<List<AppResponse>>> getAgentApps(
    @Path('uid') String agentUid,
  );
}

// lib/data/datasources/remote/api_client.dart
class ApiClient {
  final Dio _dio;
  late final ApiService _service;
  
  ApiClient(this._dio) {
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
      RetryInterceptor(_dio),
    ]);
    _service = ApiService(_dio);
  }
  
  ApiService get service => _service;
  
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }
}
```

### 5. 同步服务

```dart
// lib/core/services/sync_service.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_service.g.dart';

@riverpod
class SyncService extends _$SyncService {
  @override
  SyncState build() => const SyncState.idle();
  
  Future<void> syncPendingTransactions() async {
    state = const SyncState.syncing();
    
    try {
      final repository = ref.read(transactionRepositoryProvider);
      final server = ref.read(currentServerProvider);
      
      if (server == null) {
        state = const SyncState.error('No server configured');
        return;
      }
      
      final pending = await repository.getPendingSync();
      
      for (final transaction in pending) {
        try {
          await repository.syncToServer(transaction, server);
          await repository.markSynced(transaction.uid);
        } catch (e) {
          // 单条失败不影响其他
          debugPrint('Failed to sync ${transaction.uid}: $e');
        }
      }
      
      state = SyncState.success(syncedCount: pending.length);
    } catch (e) {
      state = SyncState.error(e.toString());
    }
  }
}

@freezed
class SyncState with _$SyncState {
  const factory SyncState.idle() = _Idle;
  const factory SyncState.syncing() = _Syncing;
  const factory SyncState.success({required int syncedCount}) = _Success;
  const factory SyncState.error(String message) = _Error;
}
```

### 6. 后台服务

```dart
// lib/core/services/background_service.dart
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundServiceManager {
  static const String syncTaskName = 'sync_transactions';
  static const String heartbeatTaskName = 'heartbeat';
  
  static Future<void> initialize() async {
    // WorkManager 用于定时任务
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    // 注册定时同步任务
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    // 注册心跳任务
    await Workmanager().registerPeriodicTask(
      heartbeatTaskName,
      heartbeatTaskName,
      frequency: const Duration(minutes: 5),
    );
    
    // Flutter Background Service 用于持续监听
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'payagent_channel',
        initialNotificationTitle: '易付收款',
        initialNotificationContent: '正在监听收款通知...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
  
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      switch (task) {
        case syncTaskName:
          await _syncTransactions();
          break;
        case heartbeatTaskName:
          await _sendHeartbeat();
          break;
      }
      return true;
    });
  }
  
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // 后台服务启动
    DartPluginRegistrant.ensureInitialized();
    
    // 初始化通知监听
    NotificationsListener.initialize(
      callbackHandle: NotificationService._notificationCallback,
    );
    
    // 监听停止信号
    service.on('stopService').listen((_) {
      service.stopSelf();
    });
  }
  
  static Future<void> _syncTransactions() async {
    final db = await BackgroundDatabase.instance;
    final api = BackgroundApiClient.instance;
    
    final pending = await db.transactionDao.getPendingSync();
    for (final t in pending) {
      try {
        await api.createRecord(t);
        await db.transactionDao.markSynced(t.uid);
      } catch (e) {
        // 失败后下次重试
      }
    }
  }
  
  static Future<void> _sendHeartbeat() async {
    final prefs = await SharedPreferences.getInstance();
    final agentUid = prefs.getString('agent_uid');
    if (agentUid == null) return;
    
    final api = BackgroundApiClient.instance;
    await api.heartbeat(agentUid);
  }
}
```

---

## UI 升级

### Material 3 主题

```dart
// lib/presentation/themes/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
  );
}
```

### 首页设计

```dart
// lib/presentation/pages/home/home_page.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayStats = ref.watch(todayStatsProvider);
    final transactions = ref.watch(recentTransactionsProvider);
    final syncState = ref.watch(syncServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('易付收款'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(syncServiceProvider.notifier).syncPendingTransactions(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayStatsProvider);
          ref.invalidate(recentTransactionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // 今日统计
            SliverToBoxAdapter(
              child: StatsPanel(stats: todayStats),
            ),
            
            // 同步状态
            SliverToBoxAdapter(
              child: syncState.when(
                idle: () => const SizedBox.shrink(),
                syncing: () => const LinearProgressIndicator(),
                success: (count) => Text('已同步 $count 条记录'),
                error: (msg) => Text('同步失败: $msg'),
              ),
            ),
            
            // 最近交易
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => TransactionCard(
                  transaction: transactions[index],
                ),
                childCount: transactions.length,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/servers'),
        icon: const Icon(Icons.cloud),
        label: const Text('服务器'),
      ),
    );
  }
}
```

---

## 迁移计划

### 阶段 1: 基础升级 (1-2 周)

1. 升级 Flutter SDK 到 3.x
2. 启用 Dart 空安全
3. 更新所有依赖包
4. 修复编译错误

### 阶段 2: 架构重构 (2-3 周)

1. 创建新的目录结构
2. 实现数据层 (Drift + Retrofit)
3. 实现领域层 (Entities + Use Cases)
4. 迁移到 Riverpod

### 阶段 3: 功能增强 (1-2 周)

1. 改进后台服务
2. 实现离线同步
3. 添加错误监控 (Sentry)
4. 添加单元测试

### 阶段 4: UI 现代化 (1-2 周)

1. Material 3 主题
2. 响应式布局
3. 动画效果
4. 无障碍支持

---

## 测试策略

### 单元测试

```dart
// test/domain/usecases/process_notification_test.dart
void main() {
  late ProcessNotification useCase;
  
  setUp(() {
    useCase = ProcessNotification();
  });
  
  group('ProcessNotification', () {
    test('should parse WeChat payment notification', () {
      final event = NotificationEvent(
        packageName: 'com.tencent.mm',
        title: '微信支付',
        text: '微信支付收款0.01元',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      
      final result = useCase(event);
      
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not fail'),
        (r) {
          expect(r.type, PayType.wechat);
          expect(r.amount, 1);
        },
      );
    });
    
    test('should parse Alipay payment notification', () {
      final event = NotificationEvent(
        packageName: 'com.eg.android.AlipayGphone',
        title: '你已成功收款10.50元',
        text: '已转入余额',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      
      final result = useCase(event);
      
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not fail'),
        (r) {
          expect(r.type, PayType.alipay);
          expect(r.amount, 1050);
        },
      );
    });
    
    test('should return failure for unknown package', () {
      final event = NotificationEvent(
        packageName: 'com.unknown.app',
        title: 'Test',
        text: 'Test message',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      
      final result = useCase(event);
      
      expect(result.isLeft(), true);
    });
  });
}
```

### 集成测试

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Full payment flow test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(MockDatabase()),
          apiClientProvider.overrideWithValue(MockApiClient()),
        ],
        child: const PayAgentApp(),
      ),
    );
    
    // 模拟收到通知
    // 验证 UI 更新
    // 验证数据同步
  });
}
```

---

## 下一步

1. [API 规范](./API.md) - RESTful API 接口文档
2. [部署指南](./DEPLOYMENT.md) - 部署和发布流程
