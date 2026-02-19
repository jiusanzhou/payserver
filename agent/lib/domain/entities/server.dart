import 'package:freezed_annotation/freezed_annotation.dart';
import 'transaction.dart';

part 'server.freezed.dart';
part 'server.g.dart';

enum ServerStatus { normal, warning, error, unknown }

extension ServerStatusExtension on ServerStatus {
  String get value {
    switch (this) {
      case ServerStatus.normal:
        return 'normal';
      case ServerStatus.warning:
        return 'warning';
      case ServerStatus.error:
        return 'error';
      case ServerStatus.unknown:
        return 'unknown';
    }
  }

  static ServerStatus fromString(String value) {
    switch (value) {
      case 'normal':
        return ServerStatus.normal;
      case 'warning':
        return ServerStatus.warning;
      case 'error':
        return ServerStatus.error;
      default:
        return ServerStatus.unknown;
    }
  }
}

@freezed
class Server with _$Server {
  const factory Server({
    int? id,
    required String name,
    required String host,
    @Default('v1') String version,
    @Default([]) List<PayType> types,
    @Default('') String uid,
    required String ticket,
    @Default(ServerStatus.normal) ServerStatus status,
    DateTime? createAt,
  }) = _Server;

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);

  factory Server.empty() => const Server(name: '', host: '', ticket: '');
}
