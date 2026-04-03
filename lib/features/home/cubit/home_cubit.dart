import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/transaction.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/storage/local_storage.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  Future<void> load() async {
    await Future.wait([_loadUser(), _loadTransactions(), _loadSummary()]);
  }

  Future<void> refresh() => load();

  Future<void> _loadUser() async {
    final username = await LocalStorage.getUsername();
    if (!isClosed) emit(state.copyWith(username: username ?? 'User'));
  }

  Future<void> _loadSummary() async {
    try {
      final data = await TransactionService.getHomeSummary();
      if (!isClosed) emit(state.copyWith(summary: data, loadingSummary: false));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loadingSummary: false));
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final data = await TransactionService.getRecentTransactions(limit: 10);
      final txns = data.map(Transaction.fromApi).toList();
      if (!isClosed) {
        emit(state.copyWith(
          transactions: txns,
          loadingTransactions: false,
          clearTransactionError: true,
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          transactionError: 'Failed to load transactions',
          loadingTransactions: false,
        ));
      }
    }
  }
}
