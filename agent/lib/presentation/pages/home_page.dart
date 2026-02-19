import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/payment_listener_service.dart';
import '../../domain/entities/transaction.dart' as tx;
import '../providers/transaction_provider.dart' as tp;
import '../providers/server_provider.dart';
import '../widgets/animated_ring.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tp.transactionStatsProvider);
            ref.invalidate(tp.transactionListProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 顶部状态区域
                _buildStatusHeader(context, isRunning, server, statsAsync),
                const SizedBox(height: 24),
                
                // 统计卡片区
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: statsAsync.when(
                    data: (stats) => _buildStatsCards(context, stats),
                    loading: () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('加载统计失败: $e'),
                  ),
                ),
                const SizedBox(height: 24),

                // 最近收款
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '最近收款',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: 跳转到收款记录
                            },
                            child: const Text('查看全部'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRecentTransactions(),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // 底部留白
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
    BuildContext context,
    bool isRunning,
    ServerEntity? server,
    AsyncValue<tx.TransactionStats> statsAsync,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isRunning ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
            isRunning ? const Color(0xFF66BB6A) : const Color(0xFFBDBDBD),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // 顶部栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.dns_outlined, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/servers'),
                ),
                Text(
                  '易付',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 中心圆环状态区
          GestureDetector(
            onTap: () => _toggleService(),
            child: AnimatedRing(
              isRunning: isRunning,
              size: 200,
              strokeWidth: 6,
              activeColor: Colors.white,
              inactiveColor: Colors.white.withOpacity(0.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 今日金额
                  statsAsync.when(
                    data: (stats) => Text(
                      '¥${(stats.todayAmount / 100).toStringAsFixed(2)}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    loading: () => Text(
                      '¥0.00',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    error: (_, __) => Text(
                      '¥--',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '今日收款',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 服务状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isRunning ? Colors.white : Colors.white54,
                    shape: BoxShape.circle,
                    boxShadow: isRunning
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isRunning ? '监听中' : '已停止',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '点击${isRunning ? '关闭' : '开启'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 服务器信息
          if (server != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    server.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/servers'),
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                label: Text(
                  '配置服务器',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleService() async {
    final service = ref.read(paymentListenerServiceProvider);
    final isRunning = ref.read(isServiceRunningProvider);
    
    if (isRunning) {
      // 停止监听需要确认
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('停止监听'),
          content: const Text('确定要停止监听支付通知吗？\n停止后将无法自动记录收款。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('停止'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        service.stop();
        ref.read(isServiceRunningProvider.notifier).state = false;
      }
    } else {
      final started = await service.start();
      ref.read(isServiceRunningProvider.notifier).state = started;
      if (!started) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要通知权限，请在设置中开启')),
          );
        }
      }
    }
  }

  Widget _buildStatsCards(BuildContext context, tx.TransactionStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFF2196F3),
            label: '今日笔数',
            value: '${stats.todayCount}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.analytics_outlined,
            iconColor: const Color(0xFF9C27B0),
            label: '总笔数',
            value: '${stats.total}',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactionsAsync = ref.watch(
      tp.transactionListProvider(const tp.TransactionQuery(limit: 5)),
    );

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '暂无收款记录',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final t = transactions[index];
              return _buildTransactionItem(t);
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildTransactionItem(tx.PayTransaction t) {
    final isWechat = t.type == tx.PayType.wechat;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isWechat
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : const Color(0xFF2196F3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isWechat ? Icons.chat_bubble_outline : Icons.account_balance_wallet_outlined,
          color: isWechat ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
        ),
      ),
      title: Text(
        '+¥${t.value}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xFF4CAF50),
        ),
      ),
      subtitle: Text(
        t.type.displayName,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Text(
        _formatTime(t.createAt),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
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
