import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:agent/data/datasources/database.dart';
import 'package:agent/domain/entities/server.dart' as entity;
import 'package:agent/domain/entities/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Re-export for convenience - avoid name collision with Drift-generated Server
typedef ServerEntity = entity.Server;

const _currentServerIdKey = 'current_server_id';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

final serverListProvider = FutureProvider<List<ServerEntity>>((ref) async {
  final db = ref.watch(databaseProvider);
  final result = await db.select(db.servers).get();

  final servers = <ServerEntity>[
    const ServerEntity(
      id: -1,
      name: '官方云',
      host: 'https://pay.zoe.im',
      ticket: '',
    ),
  ];

  servers.addAll(
    result.map(
      (row) => ServerEntity(
        id: row.id,
        name: row.name,
        host: row.host,
        version: row.version,
        types: row.types
            .split(',')
            .where((s) => s.isNotEmpty)
            .map((e) => PayTypeExtension.fromString(e))
            .toList(),
        uid: row.uid,
        ticket: row.ticket,
        status: entity.ServerStatusExtension.fromString(row.status),
        createAt: row.createAt != null
            ? DateTime.fromMillisecondsSinceEpoch(row.createAt!)
            : null,
      ),
    ),
  );

  return servers;
});

class CurrentServerNotifier extends StateNotifier<ServerEntity?> {
  final Ref ref;

  CurrentServerNotifier(this.ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final servers = await ref.read(serverListProvider.future);
    final savedId = prefs.getInt(_currentServerIdKey);

    if (savedId != null) {
      state = servers.firstWhere(
        (s) => s.id == savedId,
        orElse: () => servers.first,
      );
    } else {
      state = servers.isNotEmpty ? servers.first : null;
    }
  }

  Future<void> setCurrentServer(ServerEntity server) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_currentServerIdKey, server.id ?? -1);
    state = server;
  }
}

final currentServerProvider =
    StateNotifierProvider<CurrentServerNotifier, ServerEntity?>((ref) {
  return CurrentServerNotifier(ref);
});

class ServerListNotifier extends StateNotifier<AsyncValue<List<ServerEntity>>> {
  final Ref ref;

  ServerListNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final servers = await ref.read(serverListProvider.future);
      state = AsyncValue.data(servers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addServer(ServerEntity server) async {
    final db = ref.read(databaseProvider);
    await db.into(db.servers).insert(
          ServersCompanion.insert(
            name: server.name,
            host: server.host,
            ticket: server.ticket,
            version: Value(server.version),
            types: Value(server.types.map((t) => t.value).join(',')),
            uid: Value(server.uid),
            status: Value(server.status.value),
            createAt: Value(server.createAt?.millisecondsSinceEpoch),
          ),
        );
    ref.invalidate(serverListProvider);
    await _load();
  }

  Future<void> updateServer(ServerEntity server) async {
    if (server.id == null) return;
    final db = ref.read(databaseProvider);
    await (db.update(db.servers)..where((t) => t.id.equals(server.id!))).write(
      ServersCompanion(
        name: Value(server.name),
        host: Value(server.host),
        ticket: Value(server.ticket),
        version: Value(server.version),
        types: Value(server.types.map((t) => t.value).join(',')),
        uid: Value(server.uid),
        status: Value(server.status.value),
      ),
    );
    ref.invalidate(serverListProvider);
    await _load();
  }

  Future<void> deleteServer(ServerEntity server) async {
    if (server.id == null) return;
    final db = ref.read(databaseProvider);
    await (db.delete(db.servers)..where((t) => t.id.equals(server.id!))).go();
    ref.invalidate(serverListProvider);
    await _load();
  }
}

final serverListNotifierProvider =
    StateNotifierProvider<ServerListNotifier, AsyncValue<List<ServerEntity>>>(
        (ref) {
  return ServerListNotifier(ref);
});
