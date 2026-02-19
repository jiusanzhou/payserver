import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/payment_listener_service.dart';
import '../../domain/entities/transaction.dart' as tx;
import '../providers/transaction_provider.dart' as tp;
import '../providers/server_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Try to start service on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryStartService();
    });
  }

  Future<void> _tryStartService() async {
    final service = ref.read(paymentListenerServiceProvider);
    if (!service.isRunning) {
      final started = await service.start();
      if (started) {
        ref.read(isServiceRunningProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = ref.watch(isServiceRunningProvider);
    final statsAsync = ref.watch(tp.transactionStatsProvider);
    final server = ref.watch(currentServerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('易付'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => Navigator.pushNamed(context, '/servers'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tp.transactionStatsProvider);
          ref.invalidate(tp.transactionListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Status Card
              _buildServiceCard(context, isRunning),
              const SizedBox(height: 16),

              // Server Info
              _buildServerCard(context, server),
              const SizedBox(height: 16),

              // Stats Cards
              statsAsync.when(
                data: (stats) => _buildStatsSection(context, stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('加载统计失败: $e'),
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              Text(
                '最近收款',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildRecentTransactions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, bool isRunning) {
    return Card(
      color: isRunning ? Colors.green.shade50 : Colors.orange.shade50,
      child: ListTile(
        leading: Icon(
          isRunning ? Icons.check_circle : Icons.warning,
          color: isRunning ? Colors.green : Colors.orange,
        ),
        title: Text(isRunning ? '监听服务运行中' : '监听服务未启动'),
        subtitle: Text(isRunning ? '正在监听支付通知' : '点击启动监听'),
        trailing: Switch(
          value: isRunning,
          onChanged: (value) async {
            final service = ref.read(paymentListenerServiceProvider);
            if (value) {
              final started = await service.start();
              ref.read(isServiceRunningProvider.notifier).state = started;
              if (!started) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('需要通知权限，请在设置中开启')),
                );
              }
            } else {
              service.stop();
              ref.read(isServiceRunningProvider.notifier).state = false;
            }
          },
        ),
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, ServerEntity? server) {
    if (server == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.dns_outlined, color: Colors.grey),
          title: const Text('未配置服务器'),
          subtitle: const Text('点击添加服务器'),
          onTap: () => Navigator.pushNamed(context, '/servers'),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.cloud_done, color: Colors.blue),
        title: Text(server.name),
        subtitle: Text(server.host),
        trailing: server.uid.isNotEmpty
            ? const Icon(Icons.link, color: Colors.green)
            : const Icon(Icons.link_off, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, '/servers'),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, tx.TransactionStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            '今日收款',
            '¥${(stats.todayAmount / 100).toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            '今日笔数',
            '${stats.todayCount}',
            Icons.receipt_long,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            '总笔数',
            '${stats.total}',
            Icons.analytics,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactionsAsync = ref.watch(
      tp.transactionListProvider(const tp.TransactionQuery(limit: 10)),
    );

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('暂无收款记录', style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = transactions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: t.type == tx.PayType.wechat
                      ? Colors.green.shade100
                      : Colors.blue.shade100,
                  child: Icon(
                    t.type == tx.PayType.wechat
                        ? Icons.chat_bubble
                        : Icons.account_balance_wallet,
                    color: t.type == tx.PayType.wechat
                        ? Colors.green
                        : Colors.blue,
                    size: 20,
                  ),
                ),
                title: Text(
                  '+¥${t.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                subtitle: Text(t.type.displayName),
                trailing: Text(
                  _formatTime(t.createAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('加载失败: $e'),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
