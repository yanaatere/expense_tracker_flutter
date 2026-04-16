import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/category_definitions.dart';
import '../../../core/models/recurring_transaction.dart';
import '../../../core/models/wallet.dart';
import '../../../core/repositories/recurring_repository.dart';
import '../../../service_locator.dart';
import 'recurring_form_state.dart';

class RecurringFormCubit extends Cubit<RecurringFormState> {
  final RecurringRepository _recurringRepository;

  RecurringFormCubit({RecurringRepository? recurringRepository})
      : _recurringRepository =
            recurringRepository ?? ServiceLocator.recurringRepository,
        super(const RecurringFormState());

  Future<void> loadData({String type = 'income'}) async {
    if (!isClosed) emit(state.copyWith(transactionType: type, loading: true));

    final wallets = await ServiceLocator.walletRepository
        .getWallets()
        .catchError((_) => <Wallet>[]);

    final mappedWallets = _mapWallets(wallets);
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

  Future<void> loadForEdit(RecurringTransaction rt) async {
    if (!isClosed) {
      emit(state.copyWith(
        transactionType: rt.type,
        loading: true,
        editLocalId: rt.id,
        editServerId: rt.serverId,
      ));
    }

    final wallets = await ServiceLocator.walletRepository
        .getWallets()
        .catchError((_) => <Wallet>[]);

    final mappedWallets = _mapWallets(wallets);
    final categories = localCategories(type: rt.type);

    // Pre-select matching category
    Map<String, dynamic>? selectedCat;
    if (rt.categoryId != null) {
      final matches = categories.where((c) => c['id'] == rt.categoryId).toList();
      if (matches.isNotEmpty) selectedCat = matches.first;
    }

    // Pre-select matching sub-category
    Map<String, dynamic>? selectedSub;
    if (selectedCat != null && rt.subCategoryId != null) {
      final subs = localSubcategories(selectedCat['name'] as String, type: rt.type);
      final matches = subs.where((s) => s['id'] == rt.subCategoryId).toList();
      if (matches.isNotEmpty) selectedSub = matches.first;
    }

    // Pre-select matching wallet
    Map<String, dynamic>? selectedWallet;
    if (rt.walletId != null && mappedWallets.isNotEmpty) {
      final matches = mappedWallets
          .where((w) => w['id'].toString() == rt.walletId)
          .toList();
      selectedWallet = matches.isNotEmpty ? matches.first : mappedWallets.first;
    } else if (mappedWallets.isNotEmpty) {
      selectedWallet = mappedWallets.first;
    }

    if (!isClosed) {
      emit(state.copyWith(
        loading: false,
        categories: categories,
        wallets: mappedWallets,
        selectedCategory: selectedCat,
        selectedSubCategory: selectedSub,
        selectedWallet: selectedWallet,
        editLocalId: rt.id,
        editServerId: rt.serverId,
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
      final walletId = state.selectedWallet?['id'] as String?;

      final rt = await _recurringRepository.create(
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

      if (!isClosed) {
        emit(state.copyWith(submitting: false, submitSuccess: true, resultItem: rt));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(submitting: false, submitError: e.toString()));
      }
    }
  }

  Future<void> update({
    required RecurringTransaction original,
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
      final walletId = state.selectedWallet?['id'] as String?;

      final updated = await _recurringRepository.update(
        original: original,
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

      if (!isClosed) {
        emit(state.copyWith(submitting: false, submitSuccess: true, resultItem: updated));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(submitting: false, submitError: e.toString()));
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _mapWallets(List<Wallet> wallets) {
    return wallets
        .map((w) => <String, dynamic>{
              'id': w.serverId ?? w.id,
              'name': w.name,
              'type': w.type,
              'balance': w.balance,
            })
        .toList();
  }
}
