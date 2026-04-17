import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/category_definitions.dart';
import '../../../core/models/wallet.dart';
import '../../../core/services/wallet_service.dart';
import '../../../service_locator.dart';
import 'wallet_transaction_filter_state.dart';

class WalletTransactionFilterCubit extends Cubit<WalletTransactionFilterState> {
  final String transactionType; // 'income' or 'expense'
  int? _walletServerId;
  String? _walletLocalId; // fallback when not synced

  WalletTransactionFilterCubit({required this.transactionType})
      : super(const WalletTransactionFilterState());

  void initialize(Wallet wallet) {
    final serverId =
        wallet.serverId != null ? int.tryParse(wallet.serverId!) : null;
    if (serverId == null) {
      // Not synced yet — load from local SQLite.
      _walletLocalId = wallet.id;
      _loadLocal();
      return;
    }
    load(serverId);
  }

  Future<void> load(int walletServerId) async {
    _walletServerId = walletServerId;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final data = await WalletService.getWalletTransactions(
        walletServerId,
        type: transactionType,
        categoryId: _selectedCategoryId(),
      );
      if (!isClosed) emit(state.copyWith(transactions: data, loading: false));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: 'Failed to load', loading: false));
    }
  }

  Future<void> _loadLocal() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final entry = await ServiceLocator.authCacheDao.get();
      final userId = entry?.userId ?? '';
      final all = await ServiceLocator.expenseDao.getAll(userId);
      final filtered = all
          .where((e) =>
              e.type == transactionType &&
              e.walletId == _walletLocalId &&
              !e.isDeleted)
          .map((e) {
        final date = DateTime.fromMillisecondsSinceEpoch(e.expenseDate);
        return <String, dynamic>{
          'transaction_date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'amount': e.amount,
          'description': e.title,
          'category_name': e.category.isNotEmpty ? e.category : null,
          'category_id': e.categoryId,
          'sub_category_id': e.subCategoryId,
          'receipt_image_url': e.receiptImageUrl,
          'id': e.id,
        };
      }).toList();
      if (!isClosed) emit(state.copyWith(transactions: filtered, loading: false));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: 'Failed to load', loading: false));
    }
  }

  Future<void> reload() async {
    if (_walletServerId != null) {
      await load(_walletServerId!);
    } else if (_walletLocalId != null) {
      await _loadLocal();
    }
  }

  void setMonthly(bool v) =>
      emit(state.copyWith(monthly: v, periodFilter: 'All time'));

  void setPeriodFilter(String v) => emit(state.copyWith(periodFilter: v));

  void setSearch(String v) => emit(state.copyWith(searchQuery: v));

  void toggleStats() => emit(state.copyWith(showStats: !state.showStats));

  Future<void> setCategoryFilter(String? v) async {
    emit(v == null
        ? state.copyWith(clearCategoryFilter: true)
        : state.copyWith(categoryFilter: v));
    await reload();
  }

  // ── Computed aggregations (called from UI with the current filtered list) ──

  double totalAmount(List<Map<String, dynamic>> filtered) {
    return filtered.fold(0.0, (sum, t) {
      final raw = t['amount'];
      return sum + (raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0);
    });
  }

  Map<String, double> categoryTotals(List<Map<String, dynamic>> filtered) {
    final map = <String, double>{};
    for (final t in filtered) {
      final cat = _resolveCategoryName(t);
      final raw = t['amount'];
      final amt =
          raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0;
      map[cat] = (map[cat] ?? 0) + amt;
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  double avgDaily(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty) return 0;
    DateTime parseDate(Map<String, dynamic> t) {
      final s = t['transaction_date'] as String? ?? '';
      try {
        return DateTime.parse(s);
      } catch (_) {
        return DateTime.now();
      }
    }

    final dates = filtered.map(parseDate).toList()..sort();
    final days = dates.last.difference(dates.first).inDays + 1;
    return totalAmount(filtered) / days;
  }

  int? _selectedCategoryId() {
    if (state.categoryFilter == null) return null;
    final cats = transactionType == 'income' ? incomeCategories : expenseCategories;
    final match =
        cats.firstWhere((c) => c['name'] == state.categoryFilter, orElse: () => {});
    return match['id'] as int?;
  }

  String _resolveCategoryName(Map<String, dynamic> t) {
    final name = t['category_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final rawId = t['category_id'];
    if (rawId != null) {
      final id = rawId is int ? rawId : int.tryParse(rawId.toString());
      if (id != null) {
        final cats = transactionType == 'income' ? incomeCategories : expenseCategories;
        final match = cats.firstWhere((c) => c['id'] == id, orElse: () => {});
        final resolved = match['name'] as String?;
        if (resolved != null) return resolved;
      }
    }
    return 'Other';
  }
}
