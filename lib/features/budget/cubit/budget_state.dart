import '../../../core/dao/budget_dao.dart';

class BudgetState {
  final List<Budget> budgets;
  final Map<int, double> spending; // budgetId → current period spending
  final bool loading;
  final String? error;

  const BudgetState({
    this.budgets = const [],
    this.spending = const {},
    this.loading = true,
    this.error,
  });

  BudgetState copyWith({
    List<Budget>? budgets,
    Map<int, double>? spending,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      BudgetState(
        budgets: budgets ?? this.budgets,
        spending: spending ?? this.spending,
        loading: loading ?? this.loading,
        error: clearError ? null : error ?? this.error,
      );
}
