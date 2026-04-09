import '../../../core/dao/budget_dao.dart';

class BudgetState {
  final List<Budget> budgets;
  final bool loading;
  final String? error;

  const BudgetState({
    this.budgets = const [],
    this.loading = true,
    this.error,
  });

  BudgetState copyWith({
    List<Budget>? budgets,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      BudgetState(
        budgets: budgets ?? this.budgets,
        loading: loading ?? this.loading,
        error: clearError ? null : error ?? this.error,
      );
}
