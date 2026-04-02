import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/models/wallet.dart';
import '../../core/services/wallet_service.dart';

class WalletIncomeScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletIncomeScreen({super.key, required this.wallet});

  @override
  State<WalletIncomeScreen> createState() => _WalletIncomeScreenState();
}

class _WalletIncomeScreenState extends State<WalletIncomeScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String? _error;

  bool _monthly = true; // false = annually
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _periodFilter = 'All time';
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int? get _selectedCategoryId {
    if (_categoryFilter == null) return null;
    final match = incomeCategories.firstWhere(
      (c) => c['name'] == _categoryFilter,
      orElse: () => {},
    );
    return match['id'] as int?;
  }

  Future<void> _load() async {
    final serverId = widget.wallet.serverId != null
        ? int.tryParse(widget.wallet.serverId!)
        : null;
    if (serverId == null) {
      setState(() { _loading = false; _error = 'Wallet not synced yet'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await WalletService.getWalletTransactions(
        serverId,
        type: 'income',
        categoryId: _selectedCategoryId,
      );
      if (mounted) setState(() { _all = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  DateTime _parseDate(Map<String, dynamic> t) {
    final s = t['transaction_date'] as String? ?? '';
    try { return DateTime.parse(s); } catch (_) { return DateTime.now(); }
  }

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    return _all.where((t) {
      final date = _parseDate(t);

      // Period filter
      if (_monthly) {
        if (_periodFilter == 'This month' &&
            (date.month != now.month || date.year != now.year)) {
          return false;
        }
        if (_periodFilter == 'Last month') {
          final last = DateTime(now.year, now.month - 1);
          if (date.month != last.month || date.year != last.year) return false;
        }
      } else {
        if (_periodFilter == 'This year' && date.year != now.year) return false;
        if (_periodFilter == 'Last year' && date.year != now.year - 1) return false;
      }

      // Search
      final desc = (t['description'] as String? ?? '').toLowerCase();
      if (_searchQuery.isNotEmpty && !desc.contains(_searchQuery.toLowerCase())) return false;

      return true;
    }).toList();
  }

  double get _totalIncome => _filtered.fold(0.0, (sum, t) {
    final raw = t['amount'];
    return sum + (raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0);
  });

  bool _showStats = false;

  List<String> get _categories =>
      incomeCategories.map((c) => c['name'] as String).toList();

  String _resolveCategoryName(Map<String, dynamic> t) {
    final name = t['category_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final rawId = t['category_id'];
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

  /// Category name → total amount, sorted descending by amount.
  Map<String, double> get _categoryTotals {
    final map = <String, double>{};
    for (final t in _filtered) {
      final cat = _resolveCategoryName(t);
      final raw = t['amount'];
      final amt = raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0;
      map[cat] = (map[cat] ?? 0) + amt;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  double get _avgDailyIncome {
    if (_filtered.isEmpty) return 0;
    final dates = _filtered.map(_parseDate).toList();
    dates.sort();
    final days = dates.last.difference(dates.first).inDays + 1;
    return _totalIncome / days;
  }

  // ── Period text ───────────────────────────────────────────────────────────

  String get _periodLabel {
    final now = DateTime.now();
    if (_monthly) {
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      return 'Periode 1 - $lastDay ${DateFormat('MMMM').format(now)}';
    }
    return 'Periode Jan - Dec ${now.year}';
  }

  String get _overviewLabel =>
      _monthly ? 'Monthly Income Overview' : 'Annual Income Overview';

  List<String> get _periodOptions =>
      _monthly ? ['All time', 'This month', 'Last month'] : ['All time', 'This year', 'Last year'];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    color: AppColors.labelText,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      '${widget.wallet.name} Income Resource',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.labelText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Monthly / Annually toggle ────────────────────────────
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          _ToggleTab(
                            label: 'Monthly',
                            selected: _monthly,
                            onTap: () => setState(() {
                              _monthly = true;
                              _periodFilter = 'All time';
                            }),
                          ),
                          _ToggleTab(
                            label: 'Annualy',
                            selected: !_monthly,
                            onTap: () => setState(() {
                              _monthly = false;
                              _periodFilter = 'All time';
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Period label ─────────────────────────────────────────
                    Center(
                      child: Text(
                        _periodLabel,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: AppColors.placeholderText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Overview card ────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                            _overviewLabel,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: AppColors.placeholderText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_loading)
                            const CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2)
                          else if (_showStats && _categoryTotals.isNotEmpty) ...[
                            _DonutChart(
                              categoryTotals: _categoryTotals,
                              total: _totalIncome,
                              avgDaily: _avgDailyIncome,
                              currency: widget.wallet.currency,
                            ),
                            const SizedBox(height: 16),
                            ..._categoryTotals.keys.toList().asMap().entries.map((e) => _CategoryLegendRow(
                                  category: e.value,
                                  amount: _categoryTotals[e.value]!,
                                  total: _totalIncome,
                                  currency: widget.wallet.currency,
                                  color: categoryColor(e.value, type: 'income', fallbackIndex: e.key),
                                )),
                          ] else
                            Text(
                              formatCurrency(_totalIncome, widget.wallet.currency),
                              style: GoogleFonts.urbanist(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.labelText,
                              ),
                            ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => setState(() => _showStats = !_showStats),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: _showStats
                                    ? AppColors.labelText
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showStats
                                        ? Icons.close_rounded
                                        : Icons.pie_chart_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _showStats ? 'Hide Statistics' : 'See Statistics',
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

                    const SizedBox(height: 24),

                    // ── Section header ───────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.access_time_rounded,
                              size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.wallet.name} Recent Income',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.labelText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Search ───────────────────────────────────────────────
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.urbanist(
                          fontSize: 14, color: AppColors.labelText),
                      decoration: InputDecoration(
                        hintText: 'Search Transaction',
                        hintStyle: GoogleFonts.urbanist(
                            fontSize: 14, color: AppColors.placeholderText),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.placeholderText, size: 20),
                        filled: true,
                        fillColor: AppColors.inputBg,
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

                    const SizedBox(height: 12),

                    // ── Period + Category dropdowns ──────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownFilter(
                            value: _periodFilter,
                            items: _periodOptions,
                            onChanged: (v) =>
                                setState(() => _periodFilter = v ?? 'All time'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DropdownFilter(
                            value: _categoryFilter ?? 'Category',
                            items: ['Category', ..._categories],
                            onChanged: (v) {
                              setState(() => _categoryFilter = (v == 'Category') ? null : v);
                              _load();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Transaction list ─────────────────────────────────────
                    if (_error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(_error!,
                              style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  color: AppColors.placeholderText)),
                        ),
                      )
                    else if (!_loading && _filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text('No income transactions found',
                              style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  color: AppColors.placeholderText)),
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
                            for (int i = 0; i < _filtered.length; i++) ...[
                              _IncomeTxRow(data: _filtered[i], onDeleted: _load),
                              if (i < _filtered.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  indent: 64,
                                  endIndent: 16,
                                  color: AppColors.inputBorder.withAlpha(180),
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
                    color: AppColors.labelText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          color: AppColors.placeholderText,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                color: AppColors.labelText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$pct%',
            style: GoogleFonts.urbanist(
              fontSize: 12,
              color: AppColors.placeholderText,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCurrency(amount, currency),
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.labelText,
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
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
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
              color: selected ? Colors.white : AppColors.placeholderText,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: GoogleFonts.urbanist(
                          fontSize: 13, color: AppColors.labelText)),
                ))
            .toList(),
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.placeholderText, size: 18),
        style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.labelText),
      ),
    );
  }
}

// ── Income transaction row ────────────────────────────────────────────────────

class _IncomeTxRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onDeleted;
  const _IncomeTxRow({required this.data, this.onDeleted});

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
    final formatted = NumberFormat('#,##0.##').format(amount);
    final dateLabel = DateFormat('d MMMM yyyy').format(date);

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/icons/wallets/wallet_transaction/up.webp',
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.labelText)),
                  const SizedBox(height: 2),
                  Text(dateLabel,
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: AppColors.placeholderText)),
                ],
              ),
            ),
            Text(
              '+\$$formatted',
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
