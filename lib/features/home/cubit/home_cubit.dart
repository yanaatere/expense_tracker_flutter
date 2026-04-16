import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/transaction_repository.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../service_locator.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final TransactionRepository _transactionRepository;

  HomeCubit({TransactionRepository? transactionRepository})
      : _transactionRepository =
            transactionRepository ?? ServiceLocator.transactionRepository,
        super(const HomeState());

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
      final txns = await _transactionRepository.getRecentTransactions(limit: 10);
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
