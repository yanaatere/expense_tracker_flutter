import '../../../core/models/transaction.dart';
import '../../../core/constants/category_definitions.dart';

class TransactionFilterState {
  final List<Transaction> transactions;
  final bool loading;
  final String? error;
  final String dateFilter;
  final String? typeFilter;
  final String? categoryFilter;
  final String searchQuery;

  const TransactionFilterState({
    this.transactions = const [],
    this.loading = true,
    this.error,
    this.dateFilter = 'All time',
    this.typeFilter,
    this.categoryFilter,
    this.searchQuery = '',
  });

  TransactionFilterState copyWith({
    List<Transaction>? transactions,
    bool? loading,
    String? error,
    String? dateFilter,
    String? typeFilter,
    String? categoryFilter,
    String? searchQuery,
    bool clearError = false,
    bool clearTypeFilter = false,
    bool clearCategoryFilter = false,
  }) {
    return TransactionFilterState(
      transactions: transactions ?? this.transactions,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      dateFilter: dateFilter ?? this.dateFilter,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Transaction> get filtered {
    final now = DateTime.now();
    return transactions.where((t) {
      if (dateFilter == 'This month') {
        if (t.date.year != now.year || t.date.month != now.month) return false;
      } else if (dateFilter == 'Last month') {
        final last = DateTime(now.year, now.month - 1);
        if (t.date.year != last.year || t.date.month != last.month) return false;
      }
      if (typeFilter != null && t.type != typeFilter) return false;
      if (categoryFilter != null && t.category != categoryFilter) return false;
      if (searchQuery.isNotEmpty) {
        if (!t.title.toLowerCase().contains(searchQuery) &&
            !t.category.toLowerCase().contains(searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<String> get availableCategories {
    if (typeFilter == 'income') {
      return incomeCategories.map((c) => c['name'] as String).toList();
    }
    if (typeFilter == 'expense') {
      return expenseCategories.map((c) => c['name'] as String).toList();
    }
    return [
      ...incomeCategories.map((c) => c['name'] as String),
      ...expenseCategories.map((c) => c['name'] as String),
    ];
  }
}
