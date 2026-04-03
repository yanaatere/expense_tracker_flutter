import '../../../core/models/recurring_transaction.dart';

class RecurringState {
  final bool loading;
  final List<RecurringTransaction> items;
  final String? error;
  final bool deleting;

  const RecurringState({
    this.loading = true,
    this.items = const [],
    this.error,
    this.deleting = false,
  });

  RecurringState copyWith({
    bool? loading,
    List<RecurringTransaction>? items,
    String? error,
    bool clearError = false,
    bool? deleting,
  }) {
    return RecurringState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      deleting: deleting ?? this.deleting,
    );
  }
}
