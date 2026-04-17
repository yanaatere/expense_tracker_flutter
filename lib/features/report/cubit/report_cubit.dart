import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/expense.dart';
import '../../../core/services/report_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../service_locator.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  ReportCubit() : super(ReportState(selectedDate: DateTime.now()));

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final entry = await ServiceLocator.authCacheDao.get();
      final userId = entry?.userId ?? '';
      final isPremium = await LocalStorage.isPremium();

      List<Expense> filtered;
      List<Expense> all;

      if (isPremium) {
        // Premium: fetch from backend for cross-device consistent data.
        final effectiveDate = (state.periodMode == PeriodMode.custom &&
                state.customSelectedDate != null)
            ? state.customSelectedDate!
            : state.selectedDate;
        filtered = await ReportService.fetchTransactions(
          userId: userId,
          year: effectiveDate.year,
          month: state.periodMode != PeriodMode.annually
              ? effectiveDate.month
              : null,
          mode: state.periodMode == PeriodMode.annually ? 'annually' : 'monthly',
        );
        // For calendar badges: fetch all-time transactions locally (fast, cached)
        all = await ServiceLocator.expenseDao.getAll(userId);
      } else {
        // Free: local SQLite only.
        all = await ServiceLocator.expenseDao.getAll(userId);
        final startMs = state.rangeStart.millisecondsSinceEpoch;
        final endMs = state.rangeEnd.millisecondsSinceEpoch;
        filtered = all
            .where((e) => e.expenseDate >= startMs && e.expenseDate <= endMs)
            .toList();
      }

      if (!isClosed) {
        emit(state.copyWith(loading: false, expenses: filtered, allExpenses: all));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    }
  }

  void setPeriodMode(PeriodMode mode) {
    if (state.periodMode == mode) return;
    if (mode == PeriodMode.custom) {
      // Just switch mode; show calendar picker — don't reload until month is picked.
      emit(state.copyWith(periodMode: mode, clearCustomSelectedDate: true));
      return;
    }
    emit(state.copyWith(periodMode: mode));
    load();
  }

  void setActiveTab(ReportTab tab) {
    emit(state.copyWith(activeTab: tab));
  }

  void previousPeriod() {
    final d = state.periodMode == PeriodMode.custom && state.customSelectedDate != null
        ? state.customSelectedDate!
        : state.selectedDate;
    final next = state.periodMode == PeriodMode.monthly
        ? DateTime(d.year, d.month - 1)
        : DateTime(d.year - 1);

    if (state.periodMode == PeriodMode.custom) {
      emit(state.copyWith(customSelectedDate: next, calendarYear: next.year));
    } else {
      emit(state.copyWith(selectedDate: next));
    }
    load();
  }

  void nextPeriod() {
    if (!canGoNext) return;
    final d = state.periodMode == PeriodMode.custom && state.customSelectedDate != null
        ? state.customSelectedDate!
        : state.selectedDate;
    final next = state.periodMode == PeriodMode.monthly || state.periodMode == PeriodMode.custom
        ? DateTime(d.year, d.month + 1)
        : DateTime(d.year + 1);

    if (state.periodMode == PeriodMode.custom) {
      emit(state.copyWith(customSelectedDate: next, calendarYear: next.year));
    } else {
      emit(state.copyWith(selectedDate: next));
    }
    load();
  }

  bool get canGoNext {
    final now = DateTime.now();
    final d = state.periodMode == PeriodMode.custom && state.customSelectedDate != null
        ? state.customSelectedDate!
        : state.selectedDate;
    if (state.periodMode == PeriodMode.annually) {
      return d.year < now.year;
    }
    return d.year < now.year || d.month < now.month;
  }

  /// Called when user taps a month in the calendar picker.
  Future<void> selectCustomMonth(int year, int month) async {
    final picked = DateTime(year, month);
    emit(state.copyWith(customSelectedDate: picked, calendarYear: year));
    await load();
  }

  /// Navigate the calendar year display (delta = ±1).
  void navigateCalendarYear(int delta) {
    // Don't allow browsing beyond current year.
    final newYear = (state.calendarYear + delta).clamp(2000, DateTime.now().year);
    emit(state.copyWith(calendarYear: newYear));
  }
}
