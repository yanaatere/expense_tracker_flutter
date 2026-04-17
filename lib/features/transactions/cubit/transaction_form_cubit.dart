import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/category_definitions.dart';
import '../../../core/models/wallet.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/services/transaction_service.dart';
import '../../../service_locator.dart';
import 'transaction_form_state.dart';

class TransactionFormCubit extends Cubit<TransactionFormState> {
  final TransactionRepository _transactionRepository;

  TransactionFormCubit({TransactionRepository? transactionRepository})
      : _transactionRepository =
            transactionRepository ?? ServiceLocator.transactionRepository,
        super(const TransactionFormState());

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

    // Include all wallets — local-only wallets have null server ID but are still
    // valid for free users.
    final mappedWallets = wallets
        .map((w) => <String, dynamic>{
              'id': w.serverId ?? w.id,
              'server_id': w.serverId,
              'name': w.name,
              'type': w.type,
              'balance': w.balance,
            })
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
      if (rawWalletId != null) {
        final walletIdStr = rawWalletId.toString();
        try {
          selectedWallet = mappedWallets.firstWhere(
            (w) => w['id'].toString() == walletIdStr ||
                w['server_id']?.toString() == walletIdStr,
          );
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
      // wallet_id: use server ID if available, otherwise local ID (will be null
      // in toApiMap for local-only wallets, which is acceptable)
      final walletId = state.selectedWallet?['id'] as String?;
      await _transactionRepository.createTransaction(
        type: state.transactionType,
        amount: amount,
        description: description,
        note: note,
        date: dt,
        categoryId: state.selectedCategory?['id'] as int?,
        subCategoryId: state.selectedSubCategory?['id'] as int?,
        walletId: walletId,
        receiptImageUrl: state.receiptUrl,
      );
      // Check if this expense exceeded a budget with notifications enabled.
      // Do this BEFORE emitting success so both fire in one state update.
      String? budgetWarning;
      if (state.transactionType == 'expense') {
        final catId = state.selectedCategory?['id'] as int?;
        if (catId != null) {
          try {
            final budget = await ServiceLocator.budgetDao.getForCategory(catId);
            if (budget != null && budget.notificationEnabled) {
              final entry = await ServiceLocator.authCacheDao.get();
              if (entry != null) {
                final spending = await ServiceLocator.budgetDao
                    .getCurrentSpending(budget, entry.userId);
                if (spending >= budget.monthlyLimit) {
                  budgetWarning = budget.displayName;
                }
              }
            }
          } catch (_) {}
        }
      }

      if (!isClosed) {
        emit(state.copyWith(
          submitting: false,
          submitSuccess: true,
          budgetWarning: budgetWarning,
        ));
      }
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
    required String localId,
    String? serverId,
    required double amount,
    required String description,
    required DateTime date,
    TimeOfDay? time,
  }) async {
    emit(state.copyWith(submitting: true, clearSubmitError: true));
    try {
      final dt = _combineDateAndTime(date, time);
      final walletId = state.selectedWallet?['id'] as String?;
      await _transactionRepository.updateTransaction(
        localId: localId,
        serverId: serverId,
        type: state.transactionType,
        amount: amount,
        description: description,
        date: dt,
        categoryId: state.selectedCategory?['id'] as int?,
        subCategoryId: state.selectedSubCategory?['id'] as int?,
        walletId: walletId,
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
