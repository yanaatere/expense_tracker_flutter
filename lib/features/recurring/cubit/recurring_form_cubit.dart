import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/category_definitions.dart';
import '../../../core/models/recurring_transaction.dart';
import '../../../core/models/wallet.dart';
import '../../../core/services/recurring_transaction_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../service_locator.dart';
import 'recurring_form_state.dart';

class RecurringFormCubit extends Cubit<RecurringFormState> {
  RecurringFormCubit() : super(const RecurringFormState());

  Future<void> loadData({String type = 'income'}) async {
    if (!isClosed) emit(state.copyWith(transactionType: type, loading: true));

    final wallets = await ServiceLocator.walletRepository
        .getWallets()
        .catchError((_) => <Wallet>[]);

    final mappedWallets = wallets
        .map((w) => <String, dynamic>{
              'id': w.serverId != null ? int.tryParse(w.serverId!) : null,
              'name': w.name,
              'type': w.type,
              'balance': w.balance,
            })
        .where((m) => m['id'] != null)
        .toList();

    final categories = localCategories(type: type);

    if (!isClosed) {
      emit(state.copyWith(
        loading: false,
        categories: categories,
        wallets: mappedWallets,
        selectedWallet: mappedWallets.isNotEmpty ? mappedWallets.first : null,
      ));
    }
  }

  void setType(String type) {
    if (!isClosed) {
      emit(state.copyWith(
        transactionType: type,
        categories: localCategories(type: type),
        clearSelectedCategory: true,
        clearSelectedSubCategory: true,
      ));
    }
  }

  void setCategory(Map<String, dynamic> cat) {
    if (!isClosed) {
      emit(state.copyWith(
        selectedCategory: cat,
        clearSelectedSubCategory: true,
      ));
    }
  }

  void setSubCategory(Map<String, dynamic> sub) {
    if (!isClosed) emit(state.copyWith(selectedSubCategory: sub));
  }

  void setWallet(Map<String, dynamic> wallet) {
    if (!isClosed) emit(state.copyWith(selectedWallet: wallet));
  }

  Future<void> submit({
    required double amount,
    required String title,
    required String frequency,
    required String startDate,
    String? endDate,
  }) async {
    if (!isClosed) emit(state.copyWith(submitting: true, clearSubmitError: true));

    try {
      final categoryId = state.selectedCategory?['id'] as int?;
      final subCategoryId = state.selectedSubCategory?['id'] as int?;
      final walletId = state.selectedWallet?['id'] as int?;

      final raw = await RecurringTransactionService.create(
        title: title,
        type: state.transactionType,
        amount: amount,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        walletId: walletId,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
      );

      // Persist locally.
      final userId = await LocalStorage.getUsername() ?? '';
      final rt = RecurringTransaction.fromApi(raw, userId);
      await ServiceLocator.recurringTransactionDao.insert(rt);

      if (!isClosed) emit(state.copyWith(submitting: false, submitSuccess: true));
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? 'Failed to save schedule';
      if (!isClosed) {
        emit(state.copyWith(submitting: false, submitError: msg));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(submitting: false, submitError: e.toString()));
      }
    }
  }
}
