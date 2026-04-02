import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/services/transaction_service.dart';
import '../../core/utils/currency_formatter.dart';

// ---------------------------------------------------------------------------
// Transaction model
// ---------------------------------------------------------------------------

class _Transaction {
  final String title;
  final String category;
  final String type;
  final double amount;
  final DateTime date;
  final int? categoryId;
  final Map<String, dynamic> rawData;

  _Transaction(
    this.title,
    this.category,
    this.type,
    this.amount,
    this.date,
    this.categoryId,
    this.rawData,
  );

  factory _Transaction.fromApi(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'expense';
    final raw = map['amount'];
    double amount = raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0;
    if (type == 'expense') amount = -amount.abs();

    final rawId = map['category_id'];
    int? categoryId;
    String categoryName = '';
    if (rawId != null) {
      final id = rawId is int ? rawId : int.tryParse(rawId.toString());
      categoryId = id;
      if (id != null) {
        final cats = localCategories(type: type);
        final match = cats.firstWhere((c) => c['id'] == id, orElse: () => {});
        categoryName = match['name'] as String? ?? '';
      }
    }

    final dateStr = map['transaction_date'] as String? ?? '';
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }

    return _Transaction(
      map['description'] as String? ?? '',
      categoryName,
      type,
      amount,
      date,
      categoryId,
      map,
    );
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RecentTransactionFullPage extends StatefulWidget {
  const RecentTransactionFullPage({super.key});

  @override
  State<RecentTransactionFullPage> createState() =>
      _RecentTransactionFullPageState();
}

class _RecentTransactionFullPageState
    extends State<RecentTransactionFullPage> {
  List<_Transaction> _all = [];
  bool _loading = true;
  String? _error;

  // Filters
  String _dateFilter = 'All time';
  String? _typeFilter; // null = all, 'income', 'expense'
  String? _categoryFilter; // null = all, category name string

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await TransactionService.getRecentTransactions(limit: 200);
      final txns = raw.map(_Transaction.fromApi).toList();
      if (mounted) setState(() => _all = txns);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_Transaction> get _filtered {
    final now = DateTime.now();
    return _all.where((t) {
      // Date filter
      if (_dateFilter == 'This month') {
        if (t.date.year != now.year || t.date.month != now.month) return false;
      } else if (_dateFilter == 'Last month') {
        final last = DateTime(now.year, now.month - 1);
        if (t.date.year != last.year || t.date.month != last.month) return false;
      }

      // Type filter
      if (_typeFilter != null && t.type != _typeFilter) return false;

      // Category filter
      if (_categoryFilter != null && t.category != _categoryFilter) return false;

      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        if (!t.title.toLowerCase().contains(q) &&
            !t.category.toLowerCase().contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ── Available categories based on current type filter ─────────────────────

  List<String> get _availableCategories {
    if (_typeFilter == 'income') {
      return incomeCategories.map((c) => c['name'] as String).toList();
    } else if (_typeFilter == 'expense') {
      return expenseCategories.map((c) => c['name'] as String).toList();
    }
    return [
      ...incomeCategories.map((c) => c['name'] as String),
      ...expenseCategories.map((c) => c['name'] as String),
    ];
  }

  // ── Filter pill label ─────────────────────────────────────────────────────

  String get _typePillLabel {
    if (_typeFilter == 'income') return 'Income';
    if (_typeFilter == 'expense') return 'Expense';
    return 'Type';
  }

  String get _categoryPillLabel =>
      _categoryFilter != null ? _categoryFilter! : 'Category';

  bool get _typePillActive => _typeFilter != null;
  bool get _categoryPillActive => _categoryFilter != null;
  bool get _datePillActive => _dateFilter != 'All time';

  // ── Bottom sheet: Transaction Type ────────────────────────────────────────

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TypePickerSheet(
        selected: _typeFilter,
        onSelect: (v) {
          setState(() {
            _typeFilter = v;
            // Reset category if it no longer belongs to the new type
            if (_categoryFilter != null &&
                !_availableCategories.contains(_categoryFilter)) {
              _categoryFilter = null;
            }
          });
        },
      ),
    );
  }

  // ── Bottom sheet: Category ────────────────────────────────────────────────

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CategoryPickerSheet(
        categories: _availableCategories,
        selected: _categoryFilter,
        onSelect: (v) => setState(() => _categoryFilter = v),
      ),
    );
  }

  // ── Bottom sheet: Date range ──────────────────────────────────────────────

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DatePickerSheet(
        selected: _dateFilter,
        onSelect: (v) => setState(() => _dateFilter = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txns = _filtered;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back, color: AppColors.labelText),
        ),
        title: Text(
          'Recent Transaction',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.labelText,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: AppColors.labelText,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: AppColors.placeholderText,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.placeholderText,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),

          // ── Filter pills ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                _FilterPill(
                  label: _dateFilter,
                  active: _datePillActive,
                  onTap: _showDatePicker,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: _typePillLabel,
                  active: _typePillActive,
                  onTap: _showTypePicker,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: _categoryPillLabel,
                  active: _categoryPillActive,
                  onTap: _showCategoryPicker,
                ),
              ],
            ),
          ),

          // ── Transaction list ──────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          'Failed to load transactions',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: AppColors.placeholderText,
                          ),
                        ),
                      )
                    : txns.isEmpty
                        ? Center(
                            child: Text(
                              'No transactions found',
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                color: AppColors.placeholderText,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadTransactions,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                              itemCount: txns.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                thickness: 0.5,
                                indent: 60,
                                endIndent: 0,
                                color: AppColors.inputBorder.withAlpha(180),
                              ),
                              itemBuilder: (_, i) => _TransactionRow(
                                transaction: txns[i],
                                onDeleted: _loadTransactions,
                              ),
                            ),
                          ),
          ),
        ],
      ),
      // ── View Full Report button ───────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 0,
              ),
              onPressed: () {},
              child: Text(
                'View Full Report',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter pill widget
// ---------------------------------------------------------------------------

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.labelText,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? Colors.white : AppColors.placeholderText,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction type picker bottom sheet
// ---------------------------------------------------------------------------

class _TypePickerSheet extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _TypePickerSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Transaction Type',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.labelText,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.inputBorder.withAlpha(180), height: 1),
            _TypeOption(
              label: 'Income',
              isSelected: selected == 'income',
              onTap: () {
                onSelect(selected == 'income' ? null : 'income');
                Navigator.of(context).pop();
              },
            ),
            Divider(color: AppColors.inputBorder.withAlpha(180), height: 1),
            _TypeOption(
              label: 'Expense',
              isSelected: selected == 'expense',
              onTap: () {
                onSelect(selected == 'expense' ? null : 'expense');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF60A5FA), // light blue like screenshot
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date filter picker bottom sheet
// ---------------------------------------------------------------------------

class _DatePickerSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _DatePickerSheet({required this.selected, required this.onSelect});

  static const _options = ['All time', 'This month', 'Last month'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Date Range',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.labelText,
              ),
            ),
            const SizedBox(height: 8),
            ..._options.expand((opt) => [
                  Divider(
                      color: AppColors.inputBorder.withAlpha(180), height: 1),
                  InkWell(
                    onTap: () {
                      onSelect(opt);
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt,
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: selected == opt
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected == opt
                                    ? AppColors.primary
                                    : AppColors.labelText,
                              ),
                            ),
                          ),
                          if (selected == opt)
                            const Icon(Icons.check_rounded,
                                color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category picker bottom sheet
// ---------------------------------------------------------------------------

class _CategoryPickerSheet extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Category',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.labelText,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.inputBorder.withAlpha(180), height: 1),
          // "All" option
          InkWell(
            onTap: () {
              onSelect(null);
              Navigator.of(context).pop();
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'All Categories',
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        fontWeight: selected == null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected == null
                            ? AppColors.primary
                            : AppColors.labelText,
                      ),
                    ),
                  ),
                  if (selected == null)
                    const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 18),
                ],
              ),
            ),
          ),
          Divider(color: AppColors.inputBorder.withAlpha(180), height: 1),
          // Category list
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              itemCount: categories.length,
              separatorBuilder: (context, index) => Divider(
                color: AppColors.inputBorder.withAlpha(180),
                height: 1,
              ),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final isSelected = selected == cat;
                // Try income icon, fall back to expense icon
                final iconPath = categoryIconPath(cat, type: 'income') ??
                    categoryIconPath(cat, type: 'expense');
                return InkWell(
                  onTap: () {
                    onSelect(isSelected ? null : cat);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    child: Row(
                      children: [
                        if (iconPath != null)
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(iconPath),
                          )
                        else
                          const SizedBox(width: 44),
                        Expanded(
                          child: Text(
                            cat,
                            style: GoogleFonts.urbanist(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.labelText,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded,
                              color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction row
// ---------------------------------------------------------------------------

class _TransactionRow extends StatelessWidget {
  final _Transaction transaction;
  final VoidCallback? onDeleted;
  const _TransactionRow({required this.transaction, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amount > 0;
    final amt = transaction.amount.abs();
    final amountStr = isIncome ? '+${formatCurrency(amt, 'IDR')}' : '-${formatCurrency(amt, 'IDR')}';
    final dateStr = DateFormat('d MMMM yyyy').format(transaction.date);
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final iconPath =
        categoryIconPath(transaction.category, type: transaction.type);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final deleted = await context.push<bool>(
          '/transactions/detail',
          extra: transaction.rawData,
        );
        if (deleted == true) onDeleted?.call();
      },
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(9),
            child: iconPath != null
                ? Image.asset(iconPath)
                : Icon(
                    isIncome
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 18,
                    color: amountColor,
                  ),
          ),
          const SizedBox(width: 12),
          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title.isNotEmpty
                      ? transaction.title
                      : transaction.category,
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: AppColors.placeholderText,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            amountStr,
            style: GoogleFonts.urbanist(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
