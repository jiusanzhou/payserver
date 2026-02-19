import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:agent/data/datasources/database.dart';
import 'package:agent/domain/entities/transaction.dart';

final transactionListProvider = FutureProvider.autoDispose
    .family<List<PayTransaction>, TransactionQuery>((ref, query) async {
  final db = ref.watch(databaseProvider);
  final result = await (db.select(db.transactions)
        ..orderBy([(t) => OrderingTerm.desc(t.createAt)])
        ..limit(query.limit, offset: query.offset))
      .get();

  return result
      .map(
        (row) => PayTransaction(
          id: row.id,
          type: PayTypeExtension.fromString(row.type),
          value: row.value,
          amount: row.amount,
          timestamp: row.timestamp,
          createAt: row.createAt != null
              ? DateTime.fromMillisecondsSinceEpoch(row.createAt!)
              : null,
          status: row.status,
          raw: row.raw,
        ),
      )
      .toList();
});

final transactionStatsProvider = FutureProvider.autoDispose<TransactionStats>((
  ref,
) async {
  final db = ref.watch(databaseProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day + 1);

  final todayStartMs = todayStart.millisecondsSinceEpoch;
  final todayEndMs = todayEnd.millisecondsSinceEpoch;

  final allTransactions = await db.select(db.transactions).get();
  final todayTransactions = allTransactions
      .where(
        (t) =>
            t.createAt != null &&
            t.createAt! >= todayStartMs &&
            t.createAt! < todayEndMs,
      )
      .toList();

  final todayAmount = todayTransactions.fold<int>(
    0,
    (sum, t) => sum + t.amount,
  );

  return TransactionStats(
    todayCount: todayTransactions.length,
    todayAmount: todayAmount,
    total: allTransactions.length,
  );
});

class TransactionQuery {
  final int limit;
  final int offset;
  final PayType? type;

  const TransactionQuery({this.limit = 20, this.offset = 0, this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionQuery &&
          limit == other.limit &&
          offset == other.offset &&
          type == other.type;

  @override
  int get hashCode => Object.hash(limit, offset, type);
}

class TransactionNotifier
    extends StateNotifier<AsyncValue<List<PayTransaction>>> {
  final Ref ref;
  final List<PayTransaction> _transactions = [];
  bool _hasMore = true;
  static const _pageSize = 20;

  TransactionNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadMore();
  }

  bool get hasMore => _hasMore;
  List<PayTransaction> get transactions => _transactions;

  Future<void> loadMore() async {
    if (!_hasMore) return;

    try {
      final db = ref.read(databaseProvider);
      final result = await (db.select(db.transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.createAt)])
            ..limit(_pageSize, offset: _transactions.length))
          .get();

      final newTransactions = result
          .map(
            (row) => PayTransaction(
              id: row.id,
              type: PayTypeExtension.fromString(row.type),
              value: row.value,
              amount: row.amount,
              timestamp: row.timestamp,
              createAt: row.createAt != null
                  ? DateTime.fromMillisecondsSinceEpoch(row.createAt!)
                  : null,
              status: row.status,
              raw: row.raw,
            ),
          )
          .toList();

      _transactions.addAll(newTransactions);
      _hasMore = newTransactions.length >= _pageSize;
      state = AsyncValue.data(List.from(_transactions));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _transactions.clear();
    _hasMore = true;
    state = const AsyncValue.loading();
    await loadMore();
  }

  Future<void> insert(PayTransaction transaction) async {
    final db = ref.read(databaseProvider);
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            type: transaction.type.value,
            value: transaction.value,
            amount: transaction.amount,
            timestamp: Value(transaction.timestamp),
            createAt: Value(transaction.createAt?.millisecondsSinceEpoch),
            status: Value(transaction.status),
            raw: Value(transaction.raw),
          ),
        );

    _transactions.insert(0, transaction);
    state = AsyncValue.data(List.from(_transactions));
    ref.invalidate(transactionStatsProvider);
  }
}

final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier,
    AsyncValue<List<PayTransaction>>>((ref) {
  return TransactionNotifier(ref);
});
