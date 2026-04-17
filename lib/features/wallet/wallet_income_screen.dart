import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/monex_bar_chart.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/models/wallet.dart';
import 'cubit/wallet_transaction_filter_cubit.dart';
import 'cubit/wallet_transaction_filter_state.dart';
import '../../../core/theme/app_colors_theme.dart';

class WalletIncomeScreen extends StatelessWidget {
  final Wallet wallet;
  const WalletIncomeScreen({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletTransactionFilterCubit(transactionType: 'income')
        ..initialize(wallet),
      child: _WalletIncomeView(wallet: wallet),
    );
  }
}

class _WalletIncomeView extends StatefulWidget {
  final Wallet wallet;
  const _WalletIncomeView({required this.wallet});

  @override
  State<_WalletIncomeView> createState() => _WalletIncomeViewState();
}

class _WalletIncomeViewState extends State<_WalletIncomeView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _periodLabel(bool monthly) {
    final now = DateTime.now();
    if (monthly) {
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      return 'Periode 1 - $lastDay ${DateFormat('MMMM').format(now)}';
    }
    return 'Periode Jan - Dec ${now.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletTransactionFilterCubit, WalletTransactionFilterState>(
      builder: (context, state) {
        final cubit = context.read<WalletTransactionFilterCubit>();
        final filtered = state.filteredTransactions();
        final total = cubit.totalAmount(filtered);
        final catTotals = cubit.categoryTotals(filtered);
        final avgDaily = cubit.avgDaily(filtered);
        final categories =
            incomeCategories.map((c) => c['name'] as String).toList();
        final overviewLabel =
            state.monthly ? 'Monthly Income Overview' : 'Annual Income Overview';

        return Scaffold(
body: SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────────────────
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon:
                            Icon(Icons.chevron_left_rounded, size: 28),
                        color: context.appColors.labelText,
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          '${widget.wallet.name} Income Resource',
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

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Monthly / Annually toggle ────────────────────────
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.appColors.cardBg,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Row(
                            children: [
                              _ToggleTab(
                                label: 'Monthly',
                                selected: state.monthly,
                                onTap: () => cubit.setMonthly(true),
                              ),
                              _ToggleTab(
                                label: 'Annualy',
                                selected: !state.monthly,
                                onTap: () => cubit.setMonthly(false),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        // ── Period label ─────────────────────────────────────
                        Center(
                          child: Text(
                            _periodLabel(state.monthly),
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: context.appColors.placeholderText,
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // ── Overview card ────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding:
                              EdgeInsets.fromLTRB(24, 24, 24, 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF0FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(80),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                overviewLabel,
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  color: context.appColors.placeholderText,
                                ),
                              ),
                              SizedBox(height: 12),
                              if (state.loading)
                                CircularProgressIndicator(
                                    color: AppColors.primary, strokeWidth: 2)
                              else if (state.showStats &&
                                  catTotals.isNotEmpty) ...[
                                _DonutChart(
                                  categoryTotals: catTotals,
                                  total: total,
                                  avgDaily: avgDaily,
                                  currency: widget.wallet.currency,
                                ),
                                const SizedBox(height: 16),
                                ...catTotals.keys
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((e) => _CategoryLegendRow(
                                          category: e.value,
                                          amount: catTotals[e.value]!,
                                          total: total,
                                          currency: widget.wallet.currency,
                                          color: categoryColor(e.value,
                                              type: 'income',
                                              fallbackIndex: e.key),
                                        )),
                              ] else
                                Text(
                                  formatCurrency(total, widget.wallet.currency),
                                  style: GoogleFonts.urbanist(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: context.appColors.labelText,
                                  ),
                                ),
                              SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => cubit.toggleStats(),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: state.showStats
                                        ? context.appColors.labelText
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        state.showStats
                                            ? Icons.close_rounded
                                            : Icons.pie_chart_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        state.showStats
                                            ? 'Hide Statistics'
                                            : 'See Statistics',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // ── Bar chart ────────────────────────────────────────
                        _WalletBarChart(
                          barPoints: state.barData,
                          monthly: state.monthly,
                          accentColor: AppColors.primary,
                        ),

                        SizedBox(height: 24),

                        // ── Section header ───────────────────────────────────
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.appColors.cardBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.access_time_rounded,
                                  size: 16, color: AppColors.primary),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${widget.wallet.name} Recent Income',
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.appColors.labelText,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 14),

                        // ── Search ───────────────────────────────────────────
                        TextField(
                          controller: _searchController,
                          onChanged: (v) => cubit.setSearch(v),
                          style: GoogleFonts.urbanist(
                              fontSize: 14, color: context.appColors.labelText),
                          decoration: InputDecoration(
                            hintText: 'Search Transaction',
                            hintStyle: GoogleFonts.urbanist(
                                fontSize: 14,
                                color: context.appColors.placeholderText),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: context.appColors.placeholderText, size: 20),
                            filled: true,
                            fillColor: context.appColors.inputBg,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // ── Period + Category dropdowns ──────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _DropdownFilter(
                                value: state.periodFilter,
                                items: state.periodOptions,
                                onChanged: (v) =>
                                    cubit.setPeriodFilter(v ?? 'All time'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CategoryDropdownFilter(
                                selectedCategory: state.categoryFilter,
                                categories: categories,
                                onChanged: (v) => cubit.setCategoryFilter(
                                    v == 'Category' ? null : v),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // ── Transaction list ─────────────────────────────────
                        if (state.error != null)
                          Center(
                            child: Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: 32),
                              child: Text(state.error!,
                                  style: GoogleFonts.urbanist(
                                      fontSize: 13,
                                      color: context.appColors.placeholderText)),
                            ),
                          )
                        else if (!state.loading && filtered.isEmpty)
                          Center(
                            child: Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: 32),
                              child: Text('No income transactions found',
                                  style: GoogleFonts.urbanist(
                                      fontSize: 13,
                                      color: context.appColors.placeholderText)),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                for (int i = 0; i < filtered.length; i++) ...[
                                  _IncomeTxRow(
                                    data: filtered[i],
                                    onDeleted: () => cubit.reload(),
                                    currency: widget.wallet.currency,
                                  ),
                                  if (i < filtered.length - 1)
                                    Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      indent: 64,
                                      endIndent: 16,
                                      color: context.appColors.inputBorder
                                          .withAlpha(180),
                                    ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


// ── Bar chart widget ──────────────────────────────────────────────────────────

class _WalletBarChart extends StatelessWidget {
  final List<WalletBarPoint> barPoints;
  final bool monthly;
  final Color accentColor;

  const _WalletBarChart({
    required this.barPoints,
    required this.monthly,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final pts = barPoints
        .map((p) => MonexBarChartPoint(
              label: p.label,
              rangeLabel: p.rangeLabel,
              amount: p.amount,
            ))
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: context.appColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthly ? 'Monthly Overview' : 'Annual Overview',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appColors.labelText,
            ),
          ),
          const SizedBox(height: 12),
          MonexBarChart(
            points: pts,
            accentColor: accentColor,
            isAnnual: !monthly,
            height: 180,
          ),
        ],
      ),
    );
  }
}

// ── Donut chart widget ────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double total;
  final double avgDaily;
  final String currency;

  const _DonutChart({
    required this.categoryTotals,
    required this.total,
    required this.avgDaily,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final entries = categoryTotals.entries.toList();
    final data = entries.asMap().entries.map((e) {
      return _ChartData(
        category: e.value.key,
        amount: e.value.value,
        color: categoryColor(e.value.key, fallbackIndex: e.key),
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: SfCircularChart(
        margin: EdgeInsets.zero,
        annotations: [
          CircularChartAnnotation(
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatCurrency(total, currency),
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.labelText,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Avg Daily',
                        style: GoogleFonts.urbanist(
                          fontSize: 9,
                          color: context.appColors.placeholderText,
                        ),
                      ),
                      Text(
                        formatCurrency(avgDaily, currency),
                        style: GoogleFonts.urbanist(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        series: <CircularSeries>[
          DoughnutSeries<_ChartData, String>(
            dataSource: data,
            xValueMapper: (d, _) => d.category,
            yValueMapper: (d, _) => d.amount,
            pointColorMapper: (d, _) => d.color,
            innerRadius: '60%',
            dataLabelSettings: const DataLabelSettings(isVisible: false),
          ),
        ],
      ),
    );
  }
}

// ── Chart data model ─────────────────────────────────────────────────────────

class _ChartData {
  final String category;
  final double amount;
  final Color color;
  _ChartData({required this.category, required this.amount, required this.color});
}

// ── Category legend row ───────────────────────────────────────────────────────

class _CategoryLegendRow extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  final String currency;
  final Color color;

  const _CategoryLegendRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0.0';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                color: context.appColors.labelText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$pct%',
            style: GoogleFonts.urbanist(
              fontSize: 12,
              color: context.appColors.placeholderText,
            ),
          ),
          SizedBox(width: 8),
          Text(
            formatCurrency(amount, currency),
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appColors.labelText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle tab ────────────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : context.appColors.placeholderText,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dropdown filter pill ──────────────────────────────────────────────────────

class _DropdownFilter extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter(
      {required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColors.cardBg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: GoogleFonts.urbanist(
                          fontSize: 13, color: context.appColors.labelText)),
                ))
            .toList(),
        onChanged: onChanged,
        isExpanded: true,
        underline: SizedBox(),
        isDense: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: context.appColors.placeholderText, size: 18),
        style: GoogleFonts.urbanist(fontSize: 13, color: context.appColors.labelText),
      ),
    );
  }
}

// ── Category dropdown with icons ──────────────────────────────────────────────

class _CategoryDropdownFilter extends StatelessWidget {
  final String? selectedCategory;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdownFilter({
    required this.selectedCategory,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = selectedCategory ?? 'Category';
    final allItems = ['Category', ...categories];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColors.cardBg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: DropdownButton<String>(
        value: allItems.contains(value) ? value : allItems.first,
        items: allItems.map((e) {
          final iconPath = e == 'Category'
              ? null
              : categoryIconPath(e, type: 'income');
          return DropdownMenuItem(
            value: e,
            child: Row(
              children: [
                if (iconPath != null) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Image.asset(
                      iconPath,
                      color: categoryColor(e, type: 'income'),
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(e,
                    style: GoogleFonts.urbanist(
                        fontSize: 13, color: context.appColors.labelText)),
              ],
            ),
          );
        }).toList(),
        selectedItemBuilder: (context) => allItems.map((e) {
          final iconPath = e == 'Category'
              ? null
              : categoryIconPath(e, type: 'income');
          return Row(
            children: [
              if (iconPath != null) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Image.asset(
                    iconPath,
                    color: categoryColor(e, type: 'income'),
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  e,
                  style: GoogleFonts.urbanist(
                      fontSize: 13, color: context.appColors.labelText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
        underline: SizedBox(),
        isDense: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: context.appColors.placeholderText, size: 18),
        style: GoogleFonts.urbanist(fontSize: 13, color: context.appColors.labelText),
      ),
    );
  }
}

// ── Income transaction row ────────────────────────────────────────────────────

class _IncomeTxRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onDeleted;
  final String currency;
  const _IncomeTxRow({required this.data, this.onDeleted, required this.currency});

  String _resolveCategoryName() {
    final name = data['category_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final rawId = data['category_id'];
    if (rawId != null) {
      final id = rawId is int ? rawId : int.tryParse(rawId.toString());
      if (id != null) {
        final match = incomeCategories.firstWhere(
          (c) => c['id'] == id,
          orElse: () => {},
        );
        final resolved = match['name'] as String?;
        if (resolved != null) return resolved;
      }
    }
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final rawAmount = data['amount'];
    final double amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount.toString()) ?? 0;
    final description = data['description'] as String? ?? '—';
    final dateStr = data['transaction_date'] as String? ?? '';
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }
    final dateLabel = DateFormat('d MMMM yyyy').format(date);
    final categoryName = _resolveCategoryName();
    final iconPath = categoryIconPath(categoryName, type: 'income');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final deleted = await context.push<bool>(
          '/transactions/detail',
          extra: data,
        );
        if (deleted == true) onDeleted?.call();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: iconPath != null
                  ? Image.asset(
                      iconPath,
                      color: categoryColor(categoryName, type: 'income'),
                      colorBlendMode: BlendMode.srcIn,
                    )
                  : Image.asset(
                      'assets/icons/wallets/wallet_transaction/up.webp',
                      color: AppColors.income,
                    ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.labelText)),
                  SizedBox(height: 2),
                  Text(dateLabel,
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: context.appColors.placeholderText)),
                ],
              ),
            ),
            Text(
              '+${formatCurrency(amount, currency)}',
              style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.income),
            ),
          ],
        ),
      ),
    );
  }
}
