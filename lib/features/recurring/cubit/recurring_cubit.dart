import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/recurring_transaction.dart';
import '../../../core/services/recurring_transaction_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../service_locator.dart';
import 'recurring_state.dart';

class RecurringCubit extends Cubit<RecurringState> {
  RecurringCubit() : super(const RecurringState());

  Future<void> load() async {
    if (!isClosed) emit(state.copyWith(loading: true, clearError: true));

    try {
      // Try fetching from API.
      final raw = await RecurringTransactionService.getAll();
      final userId = await LocalStorage.getUsername() ?? '';
      final items = raw.map((m) => RecurringTransaction.fromApi(m, userId)).toList();

      // Persist locally.
      await ServiceLocator.recurringTransactionDao.upsertAll(items);

      if (!isClosed) emit(state.copyWith(loading: false, items: items));
    } on DioException {
      // Fall back to local cache.
      await _loadLocal();
    } catch (_) {
      await _loadLocal();
    }
  }

  Future<void> _loadLocal() async {
    try {
      final userId = await LocalStorage.getUsername() ?? '';
      final items = await ServiceLocator.recurringTransactionDao.getAll(userId);
      if (!isClosed) emit(state.copyWith(loading: false, items: items));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> delete(RecurringTransaction rt) async {
    if (!isClosed) emit(state.copyWith(deleting: true));
    try {
      if (rt.serverId != null) {
        await RecurringTransactionService.delete(int.parse(rt.serverId!));
      }
      await ServiceLocator.recurringTransactionDao.delete(rt.id);
      final updated = state.items.where((i) => i.id != rt.id).toList();
      if (!isClosed) emit(state.copyWith(deleting: false, items: updated));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(deleting: false));
    }
  }
}
