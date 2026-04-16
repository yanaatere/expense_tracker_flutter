import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/dao/budget_dao.dart';
import '../../../service_locator.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit() : super(const BudgetState());

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final budgets = await ServiceLocator.budgetDao.getAll();

      // Fetch current-period spending for every budget in parallel.
      final entry = await ServiceLocator.authCacheDao.get();
      final userId = entry?.userId ?? '';

      final spendingList = await Future.wait(
        budgets.map((b) => ServiceLocator.budgetDao.getCurrentSpending(b, userId)),
      );

      final spendingMap = <int, double>{};
      for (int i = 0; i < budgets.length; i++) {
        if (budgets[i].id != null) {
          spendingMap[budgets[i].id!] = spendingList[i];
        }
      }

      if (!isClosed) {
        emit(state.copyWith(budgets: budgets, spending: spendingMap, loading: false));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    }
  }

  Future<void> add(String categoryName, double monthlyLimit, {
    int? categoryId,
    String period = 'monthly',
    String? title,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final budget = Budget(
      categoryName: categoryName,
      categoryId: categoryId,
      monthlyLimit: monthlyLimit,
      period: period,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    await ServiceLocator.budgetDao.upsert(budget);
    await load();
  }

  Future<void> update(Budget budget) async {
    final updated = budget.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    await ServiceLocator.budgetDao.upsert(updated);
    await load();
  }

  Future<void> toggleNotification(Budget budget) async {
    final updated = budget.copyWith(
      notificationEnabled: !budget.notificationEnabled,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await ServiceLocator.budgetDao.upsert(updated);
    await load();
  }

  Future<void> delete(int id) async {
    await ServiceLocator.budgetDao.delete(id);
    await load();
  }
}
