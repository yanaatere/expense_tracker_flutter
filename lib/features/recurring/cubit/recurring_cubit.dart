import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/recurring_transaction.dart';
import '../../../core/repositories/recurring_repository.dart';
import '../../../service_locator.dart';
import 'recurring_state.dart';

class RecurringCubit extends Cubit<RecurringState> {
  final RecurringRepository _recurringRepository;

  RecurringCubit({RecurringRepository? recurringRepository})
      : _recurringRepository =
            recurringRepository ?? ServiceLocator.recurringRepository,
        super(const RecurringState());

  Future<void> load() async {
    if (!isClosed) emit(state.copyWith(loading: true, clearError: true));

    try {
      final items = await _recurringRepository.getAll();
      if (!isClosed) emit(state.copyWith(loading: false, items: items));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> delete(RecurringTransaction rt) async {
    if (!isClosed) emit(state.copyWith(deleting: true));
    try {
      await _recurringRepository.delete(rt);
      final updated = state.items.where((i) => i.id != rt.id).toList();
      if (!isClosed) emit(state.copyWith(deleting: false, items: updated));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(deleting: false));
    }
  }
}
