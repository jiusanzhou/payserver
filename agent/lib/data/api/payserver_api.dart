import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/transaction.dart';
import '../../domain/entities/server.dart';

/// API client for PayServer backend
class PayServerApi {
  final Server server;
  final String agentUid;

  PayServerApi({required this.server, required this.agentUid});

  String get _baseUrl => '${server.host}/api/v1';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Agent-UID': agentUid,
      };

  /// Upload a pay record to the server
  Future<ApiResult> uploadRecord(PayTransaction transaction) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/records'),
        headers: _headers,
        body: jsonEncode({
          'agent_uid': agentUid,
          'type': transaction.type.toText(),
          'number': '', // Platform order number if available
          'amount': transaction.amount,
          'timestamp': transaction.createAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'external': transaction.raw ?? '',
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResult.success(data);
      } else {
        return ApiResult.error('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResult.error('Network error: $e');
    }
  }

  /// Heartbeat to let server know agent is alive
  Future<ApiResult> heartbeat() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/agent/$agentUid/heartbeat'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(null);
      } else {
        return ApiResult.error('Heartbeat failed: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResult.error('Network error: $e');
    }
  }

  /// Prepare agent registration (get ticket)
  static Future<ApiResult<RegisterTicket>> prepareAgent({
    required String host,
    required String deviceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$host/api/v1/agent/prepare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResult.success(RegisterTicket.fromJson(data['data'] ?? data));
      } else {
        return ApiResult.error('Prepare failed: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResult.error('Network error: $e');
    }
  }

  /// Register agent with ticket
  static Future<ApiResult<AgentInfo>> registerAgent({
    required String host,
    required String ticket,
    required String deviceId,
    required String deviceInfo,
    required List<PayType> payTypes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$host/api/v1/agents'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ticket': ticket,
          'device_id': deviceId,
          'device_info': deviceInfo,
          'pay_types': payTypes.map((e) => e.toText()).join(','),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResult.success(AgentInfo.fromJson(data['data'] ?? data));
      } else {
        return ApiResult.error('Register failed: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResult.error('Network error: $e');
    }
  }
}

class ApiResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  ApiResult.success(this.data)
      : isSuccess = true,
        error = null;

  ApiResult.error(this.error)
      : isSuccess = false,
        data = null;
}

class RegisterTicket {
  final String name;
  final String host;
  final String version;
  final String ticket;

  RegisterTicket({
    required this.name,
    required this.host,
    required this.version,
    required this.ticket,
  });

  factory RegisterTicket.fromJson(Map<String, dynamic> json) {
    return RegisterTicket(
      name: json['name'] ?? '',
      host: json['host'] ?? '',
      version: json['version'] ?? '',
      ticket: json['ticket'] ?? '',
    );
  }
}

class AgentInfo {
  final String uid;
  final String deviceId;
  final int status;

  AgentInfo({
    required this.uid,
    required this.deviceId,
    required this.status,
  });

  factory AgentInfo.fromJson(Map<String, dynamic> json) {
    return AgentInfo(
      uid: json['uid'] ?? '',
      deviceId: json['device_id'] ?? '',
      status: json['status'] ?? 0,
    );
  }
}
