class TransactionFormState {
  final String transactionType;
  final bool loading;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> wallets;
  final Map<String, dynamic>? selectedCategory;
  final Map<String, dynamic>? selectedSubCategory;
  final Map<String, dynamic>? selectedWallet;
  final bool uploadingReceipt;
  final String? receiptUrl;
  final bool submitting;
  final bool submitSuccess;
  final String? submitError;

  const TransactionFormState({
    this.transactionType = 'income',
    this.loading = true,
    this.categories = const [],
    this.wallets = const [],
    this.selectedCategory,
    this.selectedSubCategory,
    this.selectedWallet,
    this.uploadingReceipt = false,
    this.receiptUrl,
    this.submitting = false,
    this.submitSuccess = false,
    this.submitError,
  });

  TransactionFormState copyWith({
    String? transactionType,
    bool? loading,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? wallets,
    Map<String, dynamic>? selectedCategory,
    Map<String, dynamic>? selectedSubCategory,
    Map<String, dynamic>? selectedWallet,
    bool? uploadingReceipt,
    String? receiptUrl,
    bool? submitting,
    bool? submitSuccess,
    String? submitError,
    bool clearSelectedCategory = false,
    bool clearSelectedSubCategory = false,
    bool clearReceiptUrl = false,
    bool clearSubmitError = false,
  }) {
    return TransactionFormState(
      transactionType: transactionType ?? this.transactionType,
      loading: loading ?? this.loading,
      categories: categories ?? this.categories,
      wallets: wallets ?? this.wallets,
      selectedCategory:
          clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedSubCategory:
          clearSelectedSubCategory ? null : (selectedSubCategory ?? this.selectedSubCategory),
      selectedWallet: selectedWallet ?? this.selectedWallet,
      uploadingReceipt: uploadingReceipt ?? this.uploadingReceipt,
      receiptUrl: clearReceiptUrl ? null : (receiptUrl ?? this.receiptUrl),
      submitting: submitting ?? this.submitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}
