import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_colors_theme.dart';
import '../../core/widgets/monex_bar_chart.dart';
import 'cubit/report_cubit.dart';
import 'cubit/report_state.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportCubit()..load(),
      child: const _ReportView(),
    );
  }
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

class _ReportView extends StatelessWidget {
  const _ReportView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: context.appColors.labelText,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Report',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.labelText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<ReportCubit, ReportState>(
                builder: (context, state) {
                  return CustomScrollView(
                    slivers: [
                      // Period tab bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _PeriodTabBar(state: state),
                        ),
                      ),

                      // Custom mode: no date picked yet → show picker prompt
                      if (state.periodMode == PeriodMode.custom &&
                          !state.customDateSelected) ...[
                        SliverToBoxAdapter(
                          child: _ChooseDateBody(state: state),
                        ),
                      ] else ...[
                        // Date navigator
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            child: _DateNavigator(state: state),
                          ),
                        ),

                        // Summary card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: _SummaryCard(state: state),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 16)),

                        // Sticky Income/Expense tab
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _TabBarDelegate(state: state),
                        ),

                        // Main content
                        SliverToBoxAdapter(
                          child: _ReportContent(state: state),
                        ),

                        const SliverToBoxAdapter(
                            child: SizedBox(height: 32)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period tab bar
// ---------------------------------------------------------------------------

class _PeriodTabBar extends StatelessWidget {
  final ReportState state;

  const _PeriodTabBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportCubit>();
    const modes = [
      (PeriodMode.monthly, 'Monthly'),
      (PeriodMode.annually, 'Annually'),
      (PeriodMode.custom, 'Choose Date'),
      (null, 'Compare'),
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.appColors.cardBg,
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: modes.map((item) {
          final mode = item.$1;
          final label = item.$2;
          final isSelected = mode != null && state.periodMode == mode;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (mode != null) cubit.setPeriodMode(mode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(36),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : context.appColors.placeholderText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Choose date body — shown when custom mode active but no month picked yet
// ---------------------------------------------------------------------------

class _ChooseDateBody extends StatelessWidget {
  final ReportState state;
  const _ChooseDateBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        children: [
          Text(
            'Choose date',
            style: GoogleFonts.urbanist(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.appColors.labelText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a month to view your financial report',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              color: context.appColors.placeholderText,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCalendarSheet(context, state),
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Open Calendar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                textStyle: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calendar bottom sheet
// ---------------------------------------------------------------------------

void _showCalendarSheet(BuildContext context, ReportState state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BlocProvider.value(
      value: context.read<ReportCubit>(),
      child: _CalendarSheet(initialState: state),
    ),
  );
}

class _CalendarSheet extends StatelessWidget {
  final ReportState initialState;
  const _CalendarSheet({required this.initialState});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) {
            final cubit = context.read<ReportCubit>();
            final summaries = state.monthlySummaries(state.calendarYear);
            final now = DateTime.now();
            final canGoForward = state.calendarYear < now.year;

            return Container(
              decoration: BoxDecoration(
                color: context.appColors.background,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Year header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => cubit.navigateCalendarYear(-1),
                          icon: const Icon(Icons.chevron_left_rounded,
                              size: 28),
                          color: context.appColors.labelText,
                        ),
                        Text(
                          state.calendarYear.toString(),
                          style: GoogleFonts.urbanist(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: context.appColors.labelText,
                            height: 1.0,
                          ),
                        ),
                        IconButton(
                          onPressed: canGoForward
                              ? () => cubit.navigateCalendarYear(1)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded,
                              size: 28),
                          color: canGoForward
                              ? context.appColors.labelText
                              : context.appColors.placeholderText,
                        ),
                      ],
                    ),
                  ),

                  // Month grid — only months with data
                  Expanded(
                    child: Builder(builder: (_) {
                      final withData = summaries
                          .where((s) =>
                              s.hasData &&
                              !DateTime(state.calendarYear, s.month)
                                  .isAfter(DateTime(now.year, now.month)))
                          .toList();

                      if (withData.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No transactions recorded in ${state.calendarYear}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                color: context.appColors.placeholderText,
                              ),
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: withData.length,
                        itemBuilder: (_, i) {
                          final s = withData[i];
                          final isSelected =
                              state.customSelectedDate?.year ==
                                      state.calendarYear &&
                                  state.customSelectedDate?.month ==
                                      s.month;

                          return _MonthCard(
                            summary: s,
                            isFuture: false,
                            isSelected: isSelected,
                            onTap: () async {
                              await cubit.selectCustomMonth(
                                  state.calendarYear, s.month);
                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Month card
// ---------------------------------------------------------------------------

class _MonthCard extends StatelessWidget {
  final MonthlySummary summary;
  final bool isFuture;
  final bool isSelected;
  final VoidCallback? onTap;

  const _MonthCard({
    required this.summary,
    required this.isFuture,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = summary.hasData && !isFuture;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFuture
              ? context.appColors.cardBg.withAlpha(100)
              : const Color(0xFFF0EFFF),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            if (hasData)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: summary.statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.statusLabel,
                  style: GoogleFonts.urbanist(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const SizedBox(height: 24),

            const Spacer(),

            // Date range
            Text(
              isFuture ? '' : summary.dateRangeLabel,
              style: GoogleFonts.urbanist(
                fontSize: 11,
                color: isFuture
                    ? context.appColors.placeholderText.withAlpha(80)
                    : context.appColors.placeholderText,
              ),
            ),
            const SizedBox(height: 2),

            // Month name
            Text(
              summary.monthName,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isFuture
                    ? context.appColors.placeholderText.withAlpha(80)
                    : context.appColors.labelText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date navigator
// ---------------------------------------------------------------------------

class _DateNavigator extends StatelessWidget {
  final ReportState state;

  const _DateNavigator({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportCubit>();
    final canNext = cubit.canGoNext;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavChevron(
          icon: Icons.chevron_left_rounded,
          onTap: cubit.previousPeriod,
        ),
        Column(
          children: [
            GestureDetector(
              onTap: state.periodMode == PeriodMode.custom
                  ? () => _showCalendarSheet(context, state)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.periodTitle,
                    style: GoogleFonts.urbanist(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.appColors.labelText,
                    ),
                  ),
                  if (state.periodMode == PeriodMode.custom) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.edit_calendar_rounded,
                        size: 16,
                        color: context.appColors.placeholderText),
                  ],
                ],
              ),
            ),
            Text(
              state.periodSubtitle,
              style: GoogleFonts.urbanist(
                fontSize: 12,
                color: context.appColors.placeholderText,
              ),
            ),
          ],
        ),
        _NavChevron(
          icon: Icons.chevron_right_rounded,
          onTap: canNext ? cubit.nextPeriod : null,
          disabled: !canNext,
        ),
      ],
    );
  }
}

class _NavChevron extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _NavChevron({
    required this.icon,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: disabled ? context.appColors.cardBg : AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: disabled ? context.appColors.placeholderText : Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final ReportState state;

  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Summary rows
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.labelText,
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.income,
                  label: 'Income',
                  value: 'Rp. ${fmt.format(state.totalIncome)},-',
                  valueColor: context.appColors.labelText,
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppColors.expense,
                  label: 'Spending',
                  value: 'Rp. ${fmt.format(state.totalExpense)},-',
                  valueColor: context.appColors.labelText,
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.more_horiz_rounded,
                  iconColor: AppColors.primary,
                  label: 'Balance',
                  value: 'Rp. ${fmt.format(state.balance)},-',
                  valueColor: state.balance >= 0
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ],
            ),
          ),

          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: context.appColors.inputBorder,
          ),

          // Status section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.statusColor,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    state.statusLabel,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Large percentage
                Text(
                  '${state.balancePct.toStringAsFixed(0)}%',
                  style: GoogleFonts.urbanist(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: state.statusColor,
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 4),

                // Balance amount
                Text(
                  '( Rp. ${fmt.format(state.balance)})',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: context.appColors.placeholderText,
                  ),
                ),

                const SizedBox(height: 12),

                // Status message
                Text(
                  state.statusMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: context.appColors.placeholderText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: context.appColors.placeholderText,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky Income/Expense tab bar
// ---------------------------------------------------------------------------

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final ReportState state;

  _TabBarDelegate({required this.state});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _IncomeExpenseTab(state: state);
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.state != state;
}

class _IncomeExpenseTab extends StatelessWidget {
  final ReportState state;

  const _IncomeExpenseTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportCubit>();

    return Container(
      height: 52,
      color: context.appColors.pageBg,
      child: Row(
        children: [
          _TabItem(
            label: 'Income',
            active: state.activeTab == ReportTab.income,
            onTap: () => cubit.setActiveTab(ReportTab.income),
          ),
          _TabItem(
            label: 'Expense',
            active: state.activeTab == ReportTab.expense,
            onTap: () => cubit.setActiveTab(ReportTab.expense),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? AppColors.primary
                    : context.appColors.placeholderText,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report content (bar chart + donut + list)
// ---------------------------------------------------------------------------

class _ReportContent extends StatelessWidget {
  final ReportState state;

  const _ReportContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final isIncome = state.activeTab == ReportTab.income;
    final barColor = isIncome ? AppColors.primary : AppColors.expense;
    final overviewTitle = isIncome
        ? (state.periodMode == PeriodMode.annually
            ? 'Annual Income Overview'
            : 'Monthly Income Overview')
        : (state.periodMode == PeriodMode.annually
            ? 'Annual Expense Overview'
            : 'Monthly Expense Overview');
    final totalTabLabel = isIncome ? 'Total Income' : 'Total Expense';
    final totalAmount = isIncome ? state.totalIncome : state.totalExpense;
    final fmt = NumberFormat('#,##0', 'en_US');

    if (state.loading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ── Bar chart card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: context.appColors.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalTabLabel,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: context.appColors.placeholderText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp. ${fmt.format(totalAmount)}',
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.labelText,
                  ),
                ),
                const SizedBox(height: 12),
                _BarChart(
                  data: state.barData,
                  barColor: barColor,
                  isAnnual: state.periodMode == PeriodMode.annually,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Donut chart card ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: BoxDecoration(
              color: context.appColors.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  overviewTitle,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: context.appColors.placeholderText,
                  ),
                ),
                const SizedBox(height: 8),
                _DonutChart(state: state, fmt: fmt),
                const SizedBox(height: 16),
                _CategoryList(state: state, fmt: fmt),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bar chart
// ---------------------------------------------------------------------------

class _BarChart extends StatelessWidget {
  final List<BarPoint> data;
  final Color barColor;
  final bool isAnnual;

  const _BarChart({
    required this.data,
    required this.barColor,
    required this.isAnnual,
  });

  @override
  Widget build(BuildContext context) {
    final pts = data
        .map((p) => MonexBarChartPoint(
              label: p.label,
              rangeLabel: p.rangeLabel,
              amount: p.amount,
            ))
        .toList();

    return MonexBarChart(
      points: pts,
      accentColor: barColor,
      isAnnual: isAnnual,
      showYAxis: true,
      height: 200,
    );
  }
}

// ---------------------------------------------------------------------------
// Donut chart
// ---------------------------------------------------------------------------

class _DonutChart extends StatefulWidget {
  final ReportState state;
  final NumberFormat fmt;

  const _DonutChart({required this.state, required this.fmt});

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(_DonutChart old) {
    super.didUpdateWidget(old);
    if (old.state.activeTab != widget.state.activeTab ||
        old.state.periodMode != widget.state.periodMode ||
        old.state.selectedDate != widget.state.selectedDate ||
        old.state.customSelectedDate != widget.state.customSelectedDate) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.state.catBreakdown;
    final isIncome = widget.state.activeTab == ReportTab.income;
    final total =
        isIncome ? widget.state.totalIncome : widget.state.totalExpense;
    final avgDaily = widget.state.avgDailyAmount;
    final avgLabel =
        isIncome ? 'Avg Daily Income' : 'Avg Daily Expense';
    final fmt = widget.fmt;

    if (cats.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data for this period',
            style: GoogleFonts.urbanist(
                color: context.appColors.placeholderText),
          ),
        ),
      );
    }

    final selected = _selectedIndex != null && _selectedIndex! < cats.length
        ? cats[_selectedIndex!]
        : null;

    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SfCircularChart(
            margin: EdgeInsets.zero,
            series: <CircularSeries>[
              DoughnutSeries<CategoryData, String>(
                dataSource: cats,
                xValueMapper: (c, _) => c.name,
                yValueMapper: (c, _) => c.amount,
                pointColorMapper: (c, _) => c.color,
                innerRadius: '55%',
                strokeWidth: 2,
                strokeColor: context.appColors.pageBg,
                explode: true,
                explodeIndex: _selectedIndex ?? -1,
                explodeOffset: '8%',
                onPointTap: (ChartPointDetails details) {
                  setState(() {
                    _selectedIndex =
                        _selectedIndex == details.pointIndex
                            ? null
                            : details.pointIndex;
                  });
                },
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: selected != null
                ? _SelectedCenter(
                    key: ValueKey(selected.name),
                    cat: selected,
                    fmt: fmt,
                  )
                : _DefaultCenter(
                    key: const ValueKey('default'),
                    total: total,
                    avgLabel: avgLabel,
                    avgDaily: avgDaily,
                    fmt: fmt,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DefaultCenter extends StatelessWidget {
  final double total;
  final String avgLabel;
  final double avgDaily;
  final NumberFormat fmt;

  const _DefaultCenter({
    super.key,
    required this.total,
    required this.avgLabel,
    required this.avgDaily,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rp. ${fmt.format(total)}',
          style: GoogleFonts.urbanist(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.appColors.labelText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          avgLabel,
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: context.appColors.placeholderText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.income,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            'Rp. ${fmt.format(avgDaily)} / day',
            style: GoogleFonts.urbanist(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedCenter extends StatelessWidget {
  final CategoryData cat;
  final NumberFormat fmt;

  const _SelectedCenter({super.key, required this.cat, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: cat.color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          cat.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.urbanist(
            fontSize: 11,
            color: context.appColors.placeholderText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Rp. ${fmt.format(cat.amount)}',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: context.appColors.labelText,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cat.color.withAlpha(30),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            '${cat.pct.toStringAsFixed(1)}%',
            style: GoogleFonts.urbanist(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cat.color,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Category list
// ---------------------------------------------------------------------------

class _CategoryList extends StatelessWidget {
  final ReportState state;
  final NumberFormat fmt;

  const _CategoryList({required this.state, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cats = state.catBreakdown;
    if (cats.isEmpty) return const SizedBox.shrink();

    return Column(
      children: cats.indexed.map((entry) {
        final i = entry.$1;
        final cat = entry.$2;
        return Column(
          children: [
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: context.appColors.inputBorder,
              )
            else
              const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: cat.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${cat.pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.labelText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat.name,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: context.appColors.placeholderText,
                    ),
                  ),
                ),
                Text(
                  'Rp. ${fmt.format(cat.amount)},-',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.labelText,
                  ),
                ),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }
}
