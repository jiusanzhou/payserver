import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/entities/transaction.dart';
import '../providers/transaction_provider.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 0; // 0: 日, 1: 周, 2: 月

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '统计', icon: Icon(Icons.analytics)),
            Tab(text: '记录', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildRecordsTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final statsAsync = ref.watch(transactionStatsProvider);

    return statsAsync.when(
      data: (stats) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              _buildPeriodSelector(),
              const SizedBox(height: 24),

              // Summary cards
              _buildSummaryCards(stats),
              const SizedBox(height: 24),

              // Chart
              Text(
                '收款趋势',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildChart(),
              const SizedBox(height: 24),

              // Payment type breakdown
              Text(
                '支付方式分布',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildPaymentTypeChart(stats),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  Widget _buildRecordsTab() {
    return const _RecordsListView();
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('日')),
        ButtonSegment(value: 1, label: Text('周')),
        ButtonSegment(value: 2, label: Text('月')),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (selection) {
        setState(() => _selectedPeriod = selection.first);
      },
    );
  }

  Widget _buildSummaryCards(TransactionStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '今日收款',
            '¥${(stats.todayAmount / 100).toStringAsFixed(2)}',
            Icons.payments,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '今日笔数',
            '${stats.todayCount}',
            Icons.receipt_long,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '总计',
            '${stats.total}笔',
            Icons.analytics,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
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

  Widget _buildChart() {
    // Placeholder data - in production, fetch from provider
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 100,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final labels = _selectedPeriod == 0
                          ? ['0', '4', '8', '12', '16', '20', '24']
                          : _selectedPeriod == 1
                              ? ['一', '二', '三', '四', '五', '六', '日']
                              : ['1周', '2周', '3周', '4周'];
                      final idx = value.toInt();
                      if (idx >= 0 && idx < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '¥${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 50),
                    FlSpot(1, 120),
                    FlSpot(2, 80),
                    FlSpot(3, 200),
                    FlSpot(4, 150),
                    FlSpot(5, 300),
                    FlSpot(6, 180),
                  ],
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withAlpha(30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeChart(TransactionStats stats) {
    // TODO: Get actual breakdown from provider
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 25,
                  sections: [
                    PieChartSectionData(
                      value: 60,
                      color: Colors.green,
                      title: '',
                      radius: 25,
                    ),
                    PieChartSectionData(
                      value: 40,
                      color: Colors.blue,
                      title: '',
                      radius: 25,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem('微信支付', Colors.green, '60%'),
                  const SizedBox(height: 8),
                  _buildLegendItem('支付宝', Colors.blue, '40%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Records list view with pagination
class _RecordsListView extends ConsumerStatefulWidget {
  const _RecordsListView();

  @override
  ConsumerState<_RecordsListView> createState() => _RecordsListViewState();
}

class _RecordsListViewState extends ConsumerState<_RecordsListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(transactionNotifierProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionNotifierProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无收款记录',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final notifier = ref.read(transactionNotifierProvider.notifier);

        return RefreshIndicator(
          onRefresh: () async {
            await notifier.refresh();
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: transactions.length + (notifier.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= transactions.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final t = transactions[index];
              return _buildRecordItem(t);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(transactionNotifierProvider.notifier).refresh();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(PayTransaction t) {
    final isWechat = t.type == PayType.wechat;
    final isManual = t.raw == 'manual_input';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isWechat
                ? const Color(0xFF4CAF50).withAlpha(25)
                : const Color(0xFF2196F3).withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isWechat
                ? Icons.chat_bubble_outline
                : Icons.account_balance_wallet_outlined,
            color: isWechat ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
          ),
        ),
        title: Row(
          children: [
            Text(
              '+¥${t.value}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF4CAF50),
              ),
            ),
            if (isManual) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '手动',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          t.type.displayName,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(
          _formatTime(t.createAt),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
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
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.year}/${dt.month}/${dt.day}';
  }
}
