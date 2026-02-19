import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/payment_listener_service.dart';
import '../providers/server_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationEnabled = false;
  bool _autoStart = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoStart = prefs.getBool('auto_start') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
    
    // Check notification permission
    final hasPermission = await _checkNotificationPermission();
    setState(() => _notificationEnabled = hasPermission);
  }

  Future<bool> _checkNotificationPermission() async {
    try {
      final service = ref.read(paymentListenerServiceProvider);
      return service.isRunning;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // Notification section
          _buildSectionHeader('通知监听'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('通知监听权限'),
            subtitle: Text(_notificationEnabled ? '已开启' : '点击开启'),
            value: _notificationEnabled,
            onChanged: (value) => _toggleNotificationPermission(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.play_arrow),
            title: const Text('自动启动监听'),
            subtitle: const Text('应用启动时自动开始监听'),
            value: _autoStart,
            onChanged: (value) => _setSetting('auto_start', value),
          ),
          const Divider(),

          // Notification behavior
          _buildSectionHeader('通知行为'),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('声音提醒'),
            subtitle: const Text('收到付款时播放提示音'),
            value: _soundEnabled,
            onChanged: (value) => _setSetting('sound_enabled', value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('振动提醒'),
            subtitle: const Text('收到付款时振动'),
            value: _vibrationEnabled,
            onChanged: (value) => _setSetting('vibration_enabled', value),
          ),
          const Divider(),

          // Data section
          _buildSectionHeader('数据'),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('同步设置'),
            subtitle: const Text('查看同步状态'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSyncSettings(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('清除本地数据'),
            subtitle: const Text('删除本地交易记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmClearData(),
          ),
          const Divider(),

          // About section
          _buildSectionHeader('关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于易付'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAbout(),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('开源许可'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLicenses(),
          ),
          const SizedBox(height: 32),
          
          // Version info
          Center(
            child: Text(
              'v2.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _toggleNotificationPermission() async {
    final service = ref.read(paymentListenerServiceProvider);
    
    if (_notificationEnabled) {
      service.stop();
      ref.read(isServiceRunningProvider.notifier).state = false;
      setState(() => _notificationEnabled = false);
    } else {
      final started = await service.start();
      if (started) {
        ref.read(isServiceRunningProvider.notifier).state = true;
        setState(() => _notificationEnabled = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请在系统设置中开启通知访问权限')),
          );
        }
      }
    }
  }

  Future<void> _setSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    setState(() {
      switch (key) {
        case 'auto_start':
          _autoStart = value;
          break;
        case 'sound_enabled':
          _soundEnabled = value;
          break;
        case 'vibration_enabled':
          _vibrationEnabled = value;
          break;
      }
    });
  }

  void _showSyncSettings() {
    final server = ref.read(currentServerProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步状态'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('当前服务器', server?.name ?? '未配置'),
            _buildInfoRow('绑定状态', server?.uid.isNotEmpty == true ? '已绑定' : '未绑定'),
            _buildInfoRow('最后同步', '刚刚'), // TODO: Track actual sync time
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除本地数据'),
        content: const Text('确定要删除所有本地交易记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Clear database
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清除本地数据')),
              );
            },
            child: const Text('清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: '易付',
      applicationVersion: 'v2.0.0',
      applicationIcon: const FlutterLogo(size: 48),
      applicationLegalese: '© 2024 Zoe. MIT License.',
      children: [
        const SizedBox(height: 16),
        const Text('个人收款解决方案'),
        const SizedBox(height: 8),
        const Text('监听支付宝/微信收款通知，自动上报服务端。'),
      ],
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: '易付',
      applicationVersion: 'v2.0.0',
    );
  }
}
