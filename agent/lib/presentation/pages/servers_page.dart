import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/server_provider.dart';
import 'server_detail_page.dart';
import 'scan_page.dart';

class ServersPage extends ConsumerWidget {
  const ServersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(serverListProvider);
    final currentServer = ref.watch(currentServerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('服务器管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _scanToAdd(context),
            tooltip: '扫码添加',
          ),
        ],
      ),
      body: serversAsync.when(
        data: (servers) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: servers.length,
          itemBuilder: (context, index) {
            final server = servers[index];
            final isSelected = currentServer?.id == server.id;

            return Card(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  child: Icon(
                    server.id == -1 ? Icons.cloud : Icons.dns,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                title: Text(
                  server.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(server.host),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (server.uid.isNotEmpty)
                      const Icon(Icons.link, color: Colors.green, size: 20),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                  ],
                ),
                onTap: () {
                  ref.read(currentServerProvider.notifier).setCurrentServer(server);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已切换到 ${server.name}')),
                  );
                },
                onLongPress: server.id != -1
                  ? () => _showServerOptions(context, ref, server)
                    : null,
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addServer(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _scanToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
  }

  void _addServer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServerDetailPage()),
    );
  }

  void _showServerOptions(BuildContext context, WidgetRef ref, ServerEntity server) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServerDetailPage(server: server),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, server);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ServerEntity server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定要删除 "${server.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(serverListNotifierProvider.notifier).deleteServer(server);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
