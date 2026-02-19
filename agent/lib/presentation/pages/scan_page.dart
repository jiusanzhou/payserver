import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/api/payserver_api.dart';
import '../../domain/entities/server.dart';
import '../../domain/entities/transaction.dart';
import '../providers/server_provider.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  String? _lastScanned;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫码绑定'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, _) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              '扫描服务端二维码以绑定',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                shadows: [
                  const Shadow(blurRadius: 4, color: Colors.black54),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      '正在绑定...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final value = barcode.rawValue!;
    if (value == _lastScanned) return;
    _lastScanned = value;

    _processQRCode(value);
  }

  Future<void> _processQRCode(String data) async {
    setState(() => _isProcessing = true);

    try {
      // Expected format: payserver://bind?host=xxx&ticket=xxx&name=xxx
      // Or JSON: {"host": "xxx", "ticket": "xxx", "name": "xxx"}
      
      Map<String, dynamic>? parsed;

      if (data.startsWith('payserver://')) {
        final uri = Uri.parse(data);
        parsed = {
          'host': uri.queryParameters['host'],
          'ticket': uri.queryParameters['ticket'],
          'name': uri.queryParameters['name'] ?? '新服务器',
        };
      } else if (data.startsWith('{')) {
        parsed = jsonDecode(data);
      }

      if (parsed == null || parsed['host'] == null || parsed['ticket'] == null) {
        throw '无效的二维码格式';
      }

      final host = parsed['host'] as String;
      final ticket = parsed['ticket'] as String;
      final name = parsed['name'] as String? ?? '新服务器';

      // Register with server
      final result = await PayServerApi.registerAgent(
        host: host,
        ticket: ticket,
        deviceId: 'flutter_${DateTime.now().millisecondsSinceEpoch}',
        deviceInfo: 'PayAgent Flutter',
        payTypes: [PayType.wechat, PayType.alipay],
      );

      if (!result.isSuccess) {
        throw result.error ?? '绑定失败';
      }

      final agentInfo = result.data!;

      // Save server
      final server = ServerEntity(
        name: name,
        host: host,
        ticket: ticket,
        uid: agentInfo.uid,
        status: ServerStatus.normal,
        types: [PayType.wechat, PayType.alipay],
        createAt: DateTime.now(),
      );

      await ref.read(serverListNotifierProvider.notifier).addServer(server);
      await ref.read(currentServerProvider.notifier).setCurrentServer(server);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已绑定到 $name'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('绑定失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Reset to allow retry
        _lastScanned = null;
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
