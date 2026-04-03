import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/category_definitions.dart';
import '../../../core/models/wallet.dart';
import '../../../core/services/transaction_service.dart';
import '../../../service_locator.dart';
import 'transaction_form_state.dart';

class TransactionFormCubit extends Cubit<TransactionFormState> {
  TransactionFormCubit() : super(const TransactionFormState());

  /// Load wallets + categories. Pass [existingData] for edit mode to pre-select
  /// the saved category, sub-category, wallet, and receipt URL.
  Future<void> loadData({
    required String type,
    Map<String, dynamic>? existingData,
    String? existingReceiptUrl,
  }) async {
    emit(state.copyWith(transactionType: type, loading: true));

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

    // Resolve pre-selections from existing data (edit mode)
    Map<String, dynamic>? selectedCategory;
    Map<String, dynamic>? selectedSubCategory;
    Map<String, dynamic>? selectedWallet =
        mappedWallets.isNotEmpty ? mappedWallets.first : null;

    if (existingData != null) {
      final rawCatId = existingData['category_id'];
      if (rawCatId != null) {
        final catId = rawCatId is int ? rawCatId : int.tryParse(rawCatId.toString());
        if (catId != null) {
          final match = categories.firstWhere((c) => c['id'] == catId, orElse: () => {});
          if (match.isNotEmpty) selectedCategory = match;
        }
      }

      if (selectedCategory != null) {
        final rawSubId = existingData['sub_category_id'];
        if (rawSubId != null) {
          final subId = rawSubId is int ? rawSubId : int.tryParse(rawSubId.toString());
          if (subId != null) {
            final subs = localSubcategories(
                selectedCategory['name'] as String, type: type);
            final match = subs.firstWhere((s) => s['id'] == subId, orElse: () => {});
            if (match.isNotEmpty) selectedSubCategory = match;
          }
        }
      }

      final rawWalletId = existingData['wallet_id'];
      final walletId =
          rawWalletId is int ? rawWalletId : int.tryParse(rawWalletId.toString());
      if (walletId != null) {
        try {
          selectedWallet = mappedWallets.firstWhere((w) => w['id'] == walletId);
        } catch (_) {}
      }
    }

    if (!isClosed) {
      emit(state.copyWith(
        loading: false,
        categories: categories,
        wallets: mappedWallets,
        selectedCategory: selectedCategory,
        selectedSubCategory: selectedSubCategory,
        selectedWallet: selectedWallet,
        receiptUrl: (existingReceiptUrl?.isNotEmpty ?? false) ? existingReceiptUrl : null,
      ));
    }
  }

  /// Switch type (income ↔ expense) and reload categories.
  void setType(String type) {
    emit(state.copyWith(
      transactionType: type,
      categories: localCategories(type: type),
      clearSelectedCategory: true,
      clearSelectedSubCategory: true,
    ));
  }

  void setCategory(Map<String, dynamic>? cat) {
    emit(state.copyWith(
      selectedCategory: cat,
      clearSelectedSubCategory: true,
    ));
  }

  void setSubCategory(Map<String, dynamic>? sub) =>
      emit(state.copyWith(selectedSubCategory: sub));

  void setWallet(Map<String, dynamic>? wallet) =>
      emit(state.copyWith(selectedWallet: wallet));

  Future<void> uploadReceipt(File file) async {
    emit(state.copyWith(uploadingReceipt: true, clearSubmitError: true));
    try {
      final url = await TransactionService.uploadReceipt(file);
      if (!isClosed) emit(state.copyWith(uploadingReceipt: false, receiptUrl: url));
    } on DioException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          uploadingReceipt: false,
          submitError: e.response?.data?['message'] as String? ?? 'Upload failed',
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(uploadingReceipt: false, submitError: 'Upload failed'));
      }
    }
  }

  Future<void> deleteReceipt() async {
    final url = state.receiptUrl;
    emit(state.copyWith(clearReceiptUrl: true));
    if (url != null) {
      try {
        await TransactionService.deleteReceipt(url);
      } catch (_) {}
    }
  }

  void clearReceipt() => emit(state.copyWith(clearReceiptUrl: true));

  Future<void> submit({
    required double amount,
    required String description,
    String? note,
    required DateTime date,
    TimeOfDay? time,
  }) async {
    emit(state.copyWith(submitting: true, clearSubmitError: true));
    try {
      final dt = _combineDateAndTime(date, time);
      await TransactionService.createTransaction(
        type: state.transactionType,
        amount: amount,
        description: description,
        categoryId: state.selectedCategory?['id'] as int?,
        subCategoryId: state.selectedSubCategory?['id'] as int?,
        walletId: state.selectedWallet?['id'] as int?,
        date: dt.toIso8601String(),
        receiptImageUrl: state.receiptUrl,
      );
      if (!isClosed) emit(state.copyWith(submitting: false, submitSuccess: true));
    } on DioException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          submitting: false,
          submitError: e.response?.data?['message'] as String? ?? 'Failed to save',
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          submitting: false,
          submitError: 'Failed to save transaction',
        ));
      }
    }
  }

  Future<void> update({
    required int transactionId,
    required double amount,
    required String description,
    required DateTime date,
    TimeOfDay? time,
  }) async {
    emit(state.copyWith(submitting: true, clearSubmitError: true));
    try {
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await TransactionService.updateTransaction(
        id: transactionId,
        type: state.transactionType,
        amount: amount,
        description: description,
        categoryId: state.selectedCategory?['id'] as int?,
        subCategoryId: state.selectedSubCategory?['id'] as int?,
        walletId: state.selectedWallet?['id'] as int?,
        date: dateStr,
        receiptImageUrl: state.receiptUrl,
      );
      if (!isClosed) emit(state.copyWith(submitting: false, submitSuccess: true));
    } on DioException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          submitting: false,
          submitError: e.response?.data?['message'] as String? ?? 'Failed to save',
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          submitting: false,
          submitError: 'Failed to update transaction',
        ));
      }
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay? time) {
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
