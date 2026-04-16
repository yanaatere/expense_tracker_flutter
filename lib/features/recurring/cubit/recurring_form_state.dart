import '../../../core/models/recurring_transaction.dart';

class RecurringFormState {
  final String transactionType;
  final bool loading;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> wallets;
  final Map<String, dynamic>? selectedCategory;
  final Map<String, dynamic>? selectedSubCategory;
  final Map<String, dynamic>? selectedWallet;
  final bool submitting;
  final bool submitSuccess;
  final String? submitError;
  /// Non-null when in edit mode — local UUID of the item being edited.
  final String? editLocalId;
  /// Server ID of the item being edited (may be null for unsynced items).
  final String? editServerId;
  /// The created or updated item set on submit success.
  final RecurringTransaction? resultItem;

  const RecurringFormState({
    this.transactionType = 'income',
    this.loading = true,
    this.categories = const [],
    this.wallets = const [],
    this.selectedCategory,
    this.selectedSubCategory,
    this.selectedWallet,
    this.submitting = false,
    this.submitSuccess = false,
    this.submitError,
    this.editLocalId,
    this.editServerId,
    this.resultItem,
  });

  bool get isEditMode => editLocalId != null;

  RecurringFormState copyWith({
    String? transactionType,
    bool? loading,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? wallets,
    Map<String, dynamic>? selectedCategory,
    Map<String, dynamic>? selectedSubCategory,
    Map<String, dynamic>? selectedWallet,
    bool? submitting,
    bool? submitSuccess,
    String? submitError,
    bool clearSelectedCategory = false,
    bool clearSelectedSubCategory = false,
    bool clearSubmitError = false,
    String? editLocalId,
    String? editServerId,
    RecurringTransaction? resultItem,
  }) {
    return RecurringFormState(
      transactionType: transactionType ?? this.transactionType,
      loading: loading ?? this.loading,
      categories: categories ?? this.categories,
      wallets: wallets ?? this.wallets,
      selectedCategory:
          clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedSubCategory:
          clearSelectedSubCategory ? null : (selectedSubCategory ?? this.selectedSubCategory),
      selectedWallet: selectedWallet ?? this.selectedWallet,
      submitting: submitting ?? this.submitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      editLocalId: editLocalId ?? this.editLocalId,
      editServerId: editServerId ?? this.editServerId,
      resultItem: resultItem ?? this.resultItem,
    );
  }
}
