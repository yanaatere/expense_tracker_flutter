import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/models/recurring_transaction.dart';
import '../../core/services/recurring_transaction_service.dart';
import '../../service_locator.dart';
import '../../../core/theme/app_colors_theme.dart';

class RecurringDetailScreen extends StatefulWidget {
  final RecurringTransaction item;

  const RecurringDetailScreen({super.key, required this.item});

  @override
  State<RecurringDetailScreen> createState() => _RecurringDetailScreenState();
}

class _RecurringDetailScreenState extends State<RecurringDetailScreen> {
  late RecurringTransaction _item;
  String? _walletName;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadWalletName();
  }

  Future<void> _loadWalletName() async {
    if (_item.walletId == null) return;
    try {
      final wallets = await ServiceLocator.walletRepository.getWallets();
      final match = wallets.firstWhere(
        (w) => w.serverId == _item.walletId,
        orElse: () => wallets.firstWhere(
          (w) => w.id == _item.walletId,
          orElse: () => throw Exception('not found'),
        ),
      );
      if (mounted) setState(() => _walletName = match.name);
    } catch (_) {}
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get _categoryName {
    if (_item.categoryId == null) return '—';
    final cats = localCategories(type: _item.type);
    final match = cats.firstWhere(
      (c) => c['id'] == _item.categoryId,
      orElse: () => {},
    );
    return match['name'] as String? ?? '—';
  }

  String get _subCategoryName {
    if (_item.subCategoryId == null) return '—';
    final catName = _categoryName;
    if (catName == '—') return '—';
    final subs = localSubcategories(catName, type: _item.type);
    final match = subs.firstWhere(
      (s) => s['id'] == _item.subCategoryId,
      orElse: () => {},
    );
    return match['name'] as String? ?? '—';
  }

  String get _spanLabel {
    if (_item.endDate == null || _item.endDate!.isEmpty) return '—';
    try {
      final start = DateTime.parse(_item.startDate);
      final end = DateTime.parse(_item.endDate!);

      final diffYears = end.year - start.year;
      if (diffYears > 0 && end.month == start.month && end.day == start.day) {
        return '$diffYears ${diffYears == 1 ? 'Year' : 'Years'}';
      }

      final diffMonths = (end.year - start.year) * 12 + (end.month - start.month);
      if (diffMonths > 0 && end.day == start.day) {
        return '$diffMonths ${diffMonths == 1 ? 'Month' : 'Months'}';
      }

      final diffDays = end.difference(start).inDays;
      if (diffDays > 0 && diffDays % 7 == 0) {
        final w = diffDays ~/ 7;
        return '$w ${w == 1 ? 'Week' : 'Weeks'}';
      }

      return '$diffDays ${diffDays == 1 ? 'Day' : 'Days'}';
    } catch (_) {
      return '—';
    }
  }

  String get _frequencyLabel {
    switch (_item.frequency) {
      case 'daily':
        return 'Day';
      case 'weekly':
        return 'Week';
      case 'yearly':
        return 'Year';
      default:
        return 'Month';
    }
  }

  String get _amountLabel {
    final val = _item.amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'Rp. $val/$_frequencyLabel';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final d = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateLong(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final d = DateTime.parse(dateStr);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String get _currentMonthName {
    const months = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december',
    ];
    return months[DateTime.now().month - 1];
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Schedule',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${_item.title}"?',
          style: GoogleFonts.urbanist(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.urbanist()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.urbanist(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);

    try {
      if (_item.serverId != null) {
        await RecurringTransactionService.delete(int.parse(_item.serverId!));
      }
      await ServiceLocator.recurringTransactionDao.delete(_item.id);
      if (mounted) context.pop('deleted');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _openEdit() async {
    final result = await context.push<RecurringTransaction?>(
      '/recurring/edit',
      extra: _item,
    );
    if (result != null && mounted) {
      setState(() {
        _item = result;
        _walletName = null;
      });
      _loadWalletName();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final catName = _categoryName;
    final subCatName = _subCategoryName;
    final catColor = catName != '—'
        ? categoryColor(catName, type: _item.type)
        : context.appColors.placeholderText;
    final catIconPath =
        catName != '—' ? categoryIconPath(catName, type: _item.type) : null;
    final subIconPath = subCatName != '—'
        ? subCategoryIconPath(subCatName, type: _item.type)
        : null;
    final subColor = subCatName != '—'
        ? subCategoryColor(subCatName, type: _item.type)
        : context.appColors.placeholderText;

    return Scaffold(
body: SafeArea(
        child: Column(
          children: [
            // ── App bar ───────────────────────────────────────────────────
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
                      _item.title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Item header card ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _item.type == 'income'
                            ? AppColors.income.withValues(alpha: 0.08)
                            : AppColors.expense.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _item.type == 'income'
                              ? AppColors.income.withValues(alpha: 0.2)
                              : AppColors.expense.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: catIconPath != null
                                ? Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Image.asset(catIconPath,
                                        color: catColor),
                                  )
                                : Icon(Icons.sync,
                                    color: catColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _item.title,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.appColors.labelText,
                                  ),
                                ),
                                if (subCatName != '—' || catName != '—')
                                  Text(
                                    subCatName != '—' ? subCatName : catName,
                                    style: GoogleFonts.urbanist(
                                      fontSize: 12,
                                      color: context.appColors.placeholderText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            _amountLabel,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _item.type == 'income'
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Receipt section ────────────────────────────────────
                    Text(
                      "You haven't upload any receipt in $_currentMonthName",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: context.appColors.placeholderText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Receipt upload coming soon')),
                          );
                        },
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: Text(
                          'Upload Receipt',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('No receipt uploaded yet')),
                        );
                      },
                      child: Text(
                        'View Receipt',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: context.appColors.inputBorder),
                    const SizedBox(height: 8),

                    // ── Detail rows ────────────────────────────────────────
                    _DetailRow(label: 'Tittle', value: _item.title),
                    _DetailRow(
                      label: 'Category',
                      valueWidget: catName != '—'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (catIconPath != null) ...[
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Image.asset(catIconPath,
                                          color: catColor),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  catName,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.appColors.labelText,
                                  ),
                                ),
                              ],
                            )
                          : null,
                      value: catName == '—' ? '—' : null,
                    ),
                    _DetailRow(
                      label: 'For',
                      valueWidget: subCatName != '—'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (subIconPath != null) ...[
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: subColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Image.asset(subIconPath,
                                          color: subColor),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  subCatName,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.appColors.labelText,
                                  ),
                                ),
                              ],
                            )
                          : null,
                      value: subCatName == '—' ? '—' : null,
                    ),
                    const _DetailRow(label: 'Description', value: '—'),
                    _DetailRow(
                        label: 'Wallet', value: _walletName ?? '—'),
                    _DetailRow(
                        label: 'Start Date',
                        value: _formatDate(_item.startDate)),
                    _DetailRow(label: 'Span Time', value: _spanLabel),

                    // End date note
                    if (_item.endDate != null && _item.endDate!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.appColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Note: Your ${_item.title.toLowerCase()} will be end at'
                          ' ${_formatDateLong(_item.endDate)}.'
                          ' After that date, transaction will no longer continued',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: context.appColors.placeholderText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom action bar ────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              // Delete button
              GestureDetector(
                onTap: _deleting ? null : _delete,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.expense.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _deleting
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              color: AppColors.expense, strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded,
                          color: AppColors.expense, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Edit button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    onPressed: _deleting ? null : _openEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(
                      'Edit Transaction',
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detail row widget ────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DetailRow({
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  color: context.appColors.placeholderText,
                ),
              ),
              const Spacer(),
              valueWidget ??
                  Text(
                    value ?? '—',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.labelText,
                    ),
                  ),
            ],
          ),
        ),
        Divider(height: 1, color: context.appColors.inputBorder),
      ],
    );
  }
}
