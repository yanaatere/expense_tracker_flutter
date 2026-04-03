import '../../../core/models/transaction.dart';

class HomeState {
  final String username;
  final List<Transaction> transactions;
  final bool loadingTransactions;
  final String? transactionError;
  final Map<String, dynamic>? summary;
  final bool loadingSummary;

  const HomeState({
    this.username = 'User',
    this.transactions = const [],
    this.loadingTransactions = true,
    this.transactionError,
    this.summary,
    this.loadingSummary = true,
  });

  HomeState copyWith({
    String? username,
    List<Transaction>? transactions,
    bool? loadingTransactions,
    String? transactionError,
    Map<String, dynamic>? summary,
    bool? loadingSummary,
    bool clearTransactionError = false,
  }) {
    return HomeState(
      username: username ?? this.username,
      transactions: transactions ?? this.transactions,
      loadingTransactions: loadingTransactions ?? this.loadingTransactions,
      transactionError:
          clearTransactionError ? null : (transactionError ?? this.transactionError),
      summary: summary ?? this.summary,
      loadingSummary: loadingSummary ?? this.loadingSummary,
    );
  }
}
