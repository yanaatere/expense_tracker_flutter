import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/transaction.dart';
import '../../../core/services/transaction_service.dart';
import 'transaction_filter_state.dart';

class TransactionFilterCubit extends Cubit<TransactionFilterState> {
  TransactionFilterCubit() : super(const TransactionFilterState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final raw = await TransactionService.getRecentTransactions(limit: 200);
      if (!isClosed) {
        emit(state.copyWith(
          transactions: raw.map(Transaction.fromApi).toList(),
          loading: false,
        ));
      }
    } catch (e) {
      if (!isClosed) emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  void setDateFilter(String v) => emit(state.copyWith(dateFilter: v));

  void setTypeFilter(String? v) {
    if (v == null) {
      emit(state.copyWith(clearTypeFilter: true));
    } else {
      final next = state.copyWith(typeFilter: v);
      // Reset category if it no longer belongs to the newly selected type
      if (state.categoryFilter != null &&
          !next.availableCategories.contains(state.categoryFilter)) {
        emit(next.copyWith(clearCategoryFilter: true));
      } else {
        emit(next);
      }
    }
  }

  void setCategoryFilter(String? v) {
    emit(v == null
        ? state.copyWith(clearCategoryFilter: true)
        : state.copyWith(categoryFilter: v));
  }

  void setSearch(String v) =>
      emit(state.copyWith(searchQuery: v.toLowerCase().trim()));
}
