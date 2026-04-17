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
      final entry = await ServiceLocator.authCacheDao.get();
      final userId = entry?.userId ?? '';
      final isPremium = await LocalStorage.isPremium();

      Map<String, dynamic>? data;

      if (isPremium) {
        try {
          data = await TransactionService.getHomeSummary();
        } catch (_) {
          // API failed — fall through to local computation
        }
      }

      data ??= await _computeLocalSummary(userId);

      if (!isClosed) emit(state.copyWith(summary: data, loadingSummary: false));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loadingSummary: false));
    }
  }

  Future<Map<String, dynamic>> _computeLocalSummary(String userId) async {
    final now = DateTime.now();
    final currentMonthStart =
        DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final prevMonthStart =
        DateTime(now.year, now.month - 1, 1).millisecondsSinceEpoch;

    final all = await ServiceLocator.expenseDao.getAll(userId);
    final wallets = await ServiceLocator.walletDao.getAll(userId);

    double totalExpense = 0;
    double prevMonthExpense = 0;
    double totalIncome = 0;

    for (final e in all) {
      if (e.type == 'expense' && e.expenseDate >= currentMonthStart) {
        totalExpense += e.amount.abs();
      }
      if (e.type == 'expense' &&
          e.expenseDate >= prevMonthStart &&
          e.expenseDate < currentMonthStart) {
        prevMonthExpense += e.amount.abs();
      }
      if (e.type == 'income' && e.expenseDate >= currentMonthStart) {
        totalIncome += e.amount.abs();
      }
    }

    final pctChange = prevMonthExpense > 0
        ? ((totalExpense - prevMonthExpense) / prevMonthExpense) * 100
        : 0.0;

    final totalBalance =
        wallets.fold<double>(0, (sum, w) => sum + w.balance);

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return {
      'total_expense': totalExpense,
      'prev_month_expense': prevMonthExpense,
      'expense_percent_change': pctChange,
      'current_month_label': '${months[now.month - 1]} ${now.year}',
      'total_balance': totalBalance,
      'total_income': totalIncome,
    };
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
