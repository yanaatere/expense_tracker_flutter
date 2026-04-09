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
      if (!isClosed) emit(state.copyWith(budgets: budgets, loading: false));
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    }
  }

  Future<void> add(String categoryName, double monthlyLimit) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final budget = Budget(
      categoryName: categoryName,
      monthlyLimit: monthlyLimit,
      createdAt: now,
      updatedAt: now,
    );
    await ServiceLocator.budgetDao.upsert(budget);
    await load();
  }

  Future<void> delete(int id) async {
    await ServiceLocator.budgetDao.delete(id);
    await load();
  }
}
