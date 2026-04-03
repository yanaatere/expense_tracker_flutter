class WalletTransactionFilterState {
  final List<Map<String, dynamic>> transactions;
  final bool loading;
  final String? error;
  final bool monthly;
  final String periodFilter;
  final String? categoryFilter;
  final String searchQuery;
  final bool showStats;

  const WalletTransactionFilterState({
    this.transactions = const [],
    this.loading = true,
    this.error,
    this.monthly = true,
    this.periodFilter = 'All time',
    this.categoryFilter,
    this.searchQuery = '',
    this.showStats = false,
  });

  WalletTransactionFilterState copyWith({
    List<Map<String, dynamic>>? transactions,
    bool? loading,
    String? error,
    bool? monthly,
    String? periodFilter,
    String? categoryFilter,
    String? searchQuery,
    bool? showStats,
    bool clearError = false,
    bool clearCategoryFilter = false,
  }) {
    return WalletTransactionFilterState(
      transactions: transactions ?? this.transactions,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      monthly: monthly ?? this.monthly,
      periodFilter: periodFilter ?? this.periodFilter,
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      showStats: showStats ?? this.showStats,
    );
  }

  List<String> get periodOptions =>
      monthly
          ? ['All time', 'This month', 'Last month']
          : ['All time', 'This year', 'Last year'];

  List<Map<String, dynamic>> filteredTransactions() {
    final now = DateTime.now();
    return transactions.where((t) {
      final date = _parseDate(t);
      if (monthly) {
        if (periodFilter == 'This month' &&
            (date.month != now.month || date.year != now.year)) {
          return false;
        }
        if (periodFilter == 'Last month') {
          final last = DateTime(now.year, now.month - 1);
          if (date.month != last.month || date.year != last.year) return false;
        }
      } else {
        if (periodFilter == 'This year' && date.year != now.year) return false;
        if (periodFilter == 'Last year' && date.year != now.year - 1) return false;
      }
      final desc = (t['description'] as String? ?? '').toLowerCase();
      if (searchQuery.isNotEmpty && !desc.contains(searchQuery.toLowerCase())) return false;
      return true;
    }).toList();
  }

  DateTime _parseDate(Map<String, dynamic> t) {
    final s = t['transaction_date'] as String? ?? '';
    try {
      return DateTime.parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }
}
