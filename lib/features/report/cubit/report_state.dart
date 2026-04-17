import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/category_definitions.dart';
import '../../../core/models/expense.dart';

enum PeriodMode { monthly, annually, custom }

enum ReportTab { income, expense }

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class BarPoint {
  final String label;
  final String rangeLabel;
  final double amount;

  const BarPoint({
    required this.label,
    required this.rangeLabel,
    required this.amount,
  });
}

class CategoryData {
  final String name;
  final double amount;
  final double pct;
  final Color color;

  const CategoryData({
    required this.name,
    required this.amount,
    required this.pct,
    required this.color,
  });
}

class MonthlySummary {
  final int year;
  final int month;
  final double income;
  final double expense;

  const MonthlySummary({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
  double get balancePct => income > 0 ? (balance / income) * 100 : 0;

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  String get dateRangeLabel =>
      '01-${daysInMonth.toString().padLeft(2, '0')}';

  String get monthName => DateFormat('MMMM').format(DateTime(year, month));

  bool get hasData => income > 0 || expense > 0;

  String get statusLabel {
    if (!hasData) return '';
    if (income == 0 && expense > 0) return 'Budget Alert';
    final pct = balancePct;
    if (pct < 0) return 'Budget Alert';
    if (pct < 30) return 'Balanced Out';
    return 'Very Positive';
  }

  Color get statusColor {
    switch (statusLabel) {
      case 'Budget Alert':
        return const Color(0xFFEF4444);
      case 'Balanced Out':
        return const Color(0xFFF59E0B);
      case 'Very Positive':
        return const Color(0xFF635AFF);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ReportState {
  final bool loading;
  final String? error;
  final PeriodMode periodMode;
  final DateTime selectedDate;
  final ReportTab activeTab;
  final List<Expense> expenses;

  /// All expenses across all time — used to compute calendar status badges.
  final List<Expense> allExpenses;

  /// Year currently displayed in the custom calendar sheet.
  final int calendarYear;

  /// Set when user picks a month in custom mode. Null = picker not yet used.
  final DateTime? customSelectedDate;

  ReportState({
    this.loading = false,
    this.error,
    this.periodMode = PeriodMode.monthly,
    required this.selectedDate,
    this.activeTab = ReportTab.income,
    this.expenses = const [],
    this.allExpenses = const [],
    int? calendarYear,
    this.customSelectedDate,
  }) : calendarYear = calendarYear ?? selectedDate.year;

  // ── Period range ──────────────────────────────────────────────────────────

  DateTime get rangeStart {
    switch (periodMode) {
      case PeriodMode.monthly:
        return DateTime(selectedDate.year, selectedDate.month, 1);
      case PeriodMode.annually:
        return DateTime(selectedDate.year, 1, 1);
      case PeriodMode.custom:
        if (customSelectedDate != null) {
          return DateTime(customSelectedDate!.year, customSelectedDate!.month, 1);
        }
        return DateTime(selectedDate.year, selectedDate.month, 1);
    }
  }

  DateTime get rangeEnd {
    switch (periodMode) {
      case PeriodMode.monthly:
        return DateTime(selectedDate.year, selectedDate.month + 1, 1)
            .subtract(const Duration(microseconds: 1));
      case PeriodMode.annually:
        return DateTime(selectedDate.year + 1, 1, 1)
            .subtract(const Duration(microseconds: 1));
      case PeriodMode.custom:
        if (customSelectedDate != null) {
          return DateTime(customSelectedDate!.year, customSelectedDate!.month + 1, 1)
              .subtract(const Duration(microseconds: 1));
        }
        return DateTime(selectedDate.year, selectedDate.month + 1, 1)
            .subtract(const Duration(microseconds: 1));
    }
  }

  String get periodTitle {
    switch (periodMode) {
      case PeriodMode.monthly:
        return DateFormat('MMMM yyyy').format(selectedDate);
      case PeriodMode.annually:
        return selectedDate.year.toString();
      case PeriodMode.custom:
        if (customSelectedDate != null) {
          return DateFormat('MMMM yyyy').format(customSelectedDate!);
        }
        return 'Choose date';
    }
  }

  String get periodSubtitle {
    switch (periodMode) {
      case PeriodMode.monthly:
        final start = DateFormat('d MMM').format(rangeStart);
        final end = DateFormat('d MMM').format(rangeEnd);
        return '($start - $end)';
      case PeriodMode.annually:
        return '(Jan ${selectedDate.year} - Dec ${selectedDate.year})';
      case PeriodMode.custom:
        if (customSelectedDate != null) {
          final start = DateFormat('d MMM').format(rangeStart);
          final end = DateFormat('d MMM').format(rangeEnd);
          return '($start - $end)';
        }
        return '';
    }
  }

  bool get customDateSelected =>
      periodMode == PeriodMode.custom && customSelectedDate != null;

  // ── Computed totals ───────────────────────────────────────────────────────

  double get totalIncome =>
      expenses.where((e) => e.type == 'income').fold(0, (s, e) => s + e.amount);

  double get totalExpense =>
      expenses.where((e) => e.type == 'expense').fold(0, (s, e) => s + e.amount);

  double get balance => totalIncome - totalExpense;

  double get balancePct =>
      totalIncome > 0 ? (balance / totalIncome) * 100 : 0;

  // ── Status ────────────────────────────────────────────────────────────────

  String get statusLabel {
    if (totalIncome == 0 && totalExpense > 0) return 'Budget Alert';
    if (totalIncome == 0) return 'No Data';
    final pct = balancePct;
    if (pct < 0) return 'Budget Alert';
    if (pct < 30) return 'Balanced Out';
    return 'Very Positive';
  }

  Color get statusColor {
    switch (statusLabel) {
      case 'Budget Alert':
        return const Color(0xFFEF4444);
      case 'Balanced Out':
        return const Color(0xFFF59E0B);
      case 'Very Positive':
        return const Color(0xFF635AFF);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String get statusMessage {
    if (totalIncome == 0 && totalExpense == 0) {
      return 'No transactions recorded for this period.';
    }
    if (statusLabel == 'Budget Alert') {
      return "You're spending more than you earn. Time to review your expenses and cut back.";
    }
    final pct = balancePct.round();
    if (statusLabel == 'Balanced Out') {
      return "You're close to breaking even with a $pct% balance. Review non-essential spending.";
    }
    if (balancePct >= 60) {
      return "Amazing! You have a $pct% surplus this period. Great time to invest or build your emergency fund! 🚀";
    }
    return "Great job! You have a $pct% surplus this period. Keep building that savings habit!";
  }

  // ── Avg daily ─────────────────────────────────────────────────────────────

  double get avgDailyAmount {
    final days = rangeEnd.difference(rangeStart).inDays + 1;
    if (days == 0) return 0;
    return (activeTab == ReportTab.income ? totalIncome : totalExpense) / days;
  }

  // ── Bar chart data ────────────────────────────────────────────────────────

  List<BarPoint> get barData {
    final filtered = expenses
        .where((e) => e.type == (activeTab == ReportTab.income ? 'income' : 'expense'))
        .toList();

    if (periodMode == PeriodMode.annually) {
      // 12 monthly buckets
      final monthAmounts = List<double>.filled(12, 0);
      for (final e in filtered) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.expenseDate);
        if (d.year != selectedDate.year) continue;
        monthAmounts[d.month - 1] += e.amount;
      }
      const monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return List.generate(12, (i) => BarPoint(
        label: monthLabels[i],
        rangeLabel: '${monthLabels[i]} ${selectedDate.year}',
        amount: monthAmounts[i],
      ));
    }

    // Monthly or custom (selected month) → 6 buckets of ~5 days
    final ref = periodMode == PeriodMode.custom && customSelectedDate != null
        ? customSelectedDate!
        : selectedDate;
    final monthNum = ref.month.toString().padLeft(2, '0');
    final monthAbbr = DateFormat('MMM').format(ref);
    final lastDay = DateTime(ref.year, ref.month + 1, 0).day;
    final buckets = List<double>.filled(6, 0);
    for (final e in filtered) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.expenseDate);
      if (d.year != ref.year || d.month != ref.month) continue;
      final bucket = ((d.day - 1) ~/ 5).clamp(0, 5);
      buckets[bucket] += e.amount;
    }
    final startDays = ['01', '06', '11', '16', '21', '26'];
    final endDays = ['05', '10', '15', '20', '25',
      lastDay.toString().padLeft(2, '0')];
    return List.generate(6, (i) => BarPoint(
      label: '${startDays[i]}/$monthNum',
      rangeLabel: '${startDays[i]} - ${endDays[i]} / $monthAbbr',
      amount: buckets[i],
    ));
  }

  // ── Category breakdown ────────────────────────────────────────────────────

  List<CategoryData> get catBreakdown {
    final type = activeTab == ReportTab.income ? 'income' : 'expense';
    final filtered = expenses.where((e) => e.type == type).toList();
    final total = filtered.fold<double>(0, (s, e) => s + e.amount);
    if (total == 0) return [];

    final Map<String, double> byCategory = {};
    for (final e in filtered) {
      final name = _resolveCategory(e);
      byCategory[name] = (byCategory[name] ?? 0) + e.amount;
    }

    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.indexed.map((entry) {
      final i = entry.$1;
      final name = entry.$2.key;
      final amount = entry.$2.value;
      return CategoryData(
        name: name,
        amount: amount,
        pct: (amount / total) * 100,
        color: categoryColor(name, type: type, fallbackIndex: i),
      );
    }).toList();
  }

  // ── Calendar: monthly summaries for the given year ────────────────────────

  List<MonthlySummary> monthlySummaries(int year) {
    return List.generate(12, (i) {
      final month = i + 1;
      double inc = 0, exp = 0;
      for (final e in allExpenses) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.expenseDate);
        if (d.year != year || d.month != month) continue;
        if (e.type == 'income') {
          inc += e.amount;
        } else {
          exp += e.amount;
        }
      }
      return MonthlySummary(
        year: year,
        month: month,
        income: inc,
        expense: exp,
      );
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _resolveCategory(Expense e) {
    if (e.category.isNotEmpty) return e.category;
    if (e.categoryId == null) return 'Other';
    final cats = localCategories(type: e.type);
    for (final c in cats) {
      if (c['id'] == e.categoryId) return c['name'] as String;
    }
    return 'Other';
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  ReportState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    PeriodMode? periodMode,
    DateTime? selectedDate,
    ReportTab? activeTab,
    List<Expense>? expenses,
    List<Expense>? allExpenses,
    int? calendarYear,
    DateTime? customSelectedDate,
    bool clearCustomSelectedDate = false,
  }) {
    return ReportState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      periodMode: periodMode ?? this.periodMode,
      selectedDate: selectedDate ?? this.selectedDate,
      activeTab: activeTab ?? this.activeTab,
      expenses: expenses ?? this.expenses,
      allExpenses: allExpenses ?? this.allExpenses,
      calendarYear: calendarYear ?? this.calendarYear,
      customSelectedDate: clearCustomSelectedDate
          ? null
          : (customSelectedDate ?? this.customSelectedDate),
    );
  }
}
