import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/services/api_client.dart';
import '../../core/services/transaction_service.dart';
import '../../../core/theme/app_colors_theme.dart';

// ---------------------------------------------------------------------------
// Transaction Detail Screen
// ---------------------------------------------------------------------------

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const TransactionDetailScreen({super.key, required this.data});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Map<String, dynamic> _data;
  bool _loadingFull = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _data = widget.data; // show passed data immediately
    // Defer the API call until after the push animation completes so the
    // navigation transition isn't interrupted by a mid-animation setState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFull());
  }

  Future<void> _fetchFull() async {
    final rawId = _data['id'];
    if (rawId == null) return;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null) return;

    setState(() => _loadingFull = true);
    try {
      final full = await TransactionService.getTransaction(id);
      if (mounted) setState(() => _data = full);
    } catch (_) {
      // keep existing data on failure — no error shown to user
    } finally {
      if (mounted) setState(() => _loadingFull = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _type => _data['type'] as String? ?? 'expense';
  bool get _isIncome => _type == 'income';

  String _resolveCategoryName() {
    final rawId = _data['category_id'];
    if (rawId == null) return '';
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null) return '';
    final cats = localCategories(type: _type);
    final match = cats.firstWhere((c) => c['id'] == id, orElse: () => {});
    return match['name'] as String? ?? '';
  }

  String _resolveSubCategoryName() {
    final rawId = _data['sub_category_id'];
    if (rawId == null) return '';
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null) return '';
    final map = _type == 'expense'
        ? expenseCategorySubcategories
        : incomeCategorySubcategories;
    for (final subs in map.values) {
      for (final sub in subs) {
        if (sub['id'] == id) return sub['name'] as String;
      }
    }
    return '';
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Transaction',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this transaction? This cannot be undone.',
          style: GoogleFonts.urbanist(color: context.appColors.bodyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.urbanist(color: context.appColors.placeholderText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.urbanist(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final rawId = _data['id'];
      if (rawId != null) {
        final id = rawId is int ? rawId : int.tryParse(rawId.toString());
        if (id != null) await TransactionService.deleteTransaction(id);
      }
      if (mounted) context.pop(true); // signal caller to refresh
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction')),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rawAmount = _data['amount'];
    final double amount =
        rawAmount is num ? rawAmount.toDouble() : double.tryParse(rawAmount.toString()) ?? 0;

    final amountColor = _isIncome ? AppColors.income : AppColors.expense;
    final typeLabel = _isIncome ? 'Income' : 'Spending';

    final categoryName = _resolveCategoryName();
    final subCategoryName = _resolveSubCategoryName();
    final description = _data['description'] as String? ?? '';
    final walletName = _data['wallet_name'] as String? ?? '';
    final notes = _data['notes'] as String? ?? '';
    final receiptUrl = _data['receipt_image_url'] as String? ?? '';

    final dateStr = _data['transaction_date'] as String? ?? '';
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }
    final dateLabel = DateFormat('d MMM yyyy').format(date);

    final createdAtStr = _data['created_at'] as String? ?? '';
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(createdAtStr);
    } catch (_) {
      createdAt = date;
    }
    final timeLabel = DateFormat('HH:mm').format(createdAt);

    final categoryIconP = categoryIconPath(categoryName, type: _type);
    final subCategoryIconP = subCategoryIconPath(subCategoryName, type: _type);

    final formattedAmount = NumberFormat('#,##0', 'en_US').format(amount.abs());
    final amountStr = _isIncome ? '+Rp. $formattedAmount' : '-Rp. $formattedAmount';

    return Scaffold(
body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, size: 28),
                    color: context.appColors.labelText,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Transaction Detail',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.labelText,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: _loadingFull
                        ? const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),

            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Amount banner ─────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Category icon circle
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: amountColor.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(14),
                          child: categoryIconP != null
                              ? Image.asset(
                                  categoryIconP,
                                  color: categoryColor(categoryName, type: _type),
                                  colorBlendMode: BlendMode.srcIn,
                                )
                              : Icon(
                                  _isIncome
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: amountColor,
                                  size: 28,
                                ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                typeLabel,
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  color: context.appColors.placeholderText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                amountStr,
                                style: GoogleFonts.urbanist(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: amountColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // ── Detail card ───────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appColors.inputBorder),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(label: 'Title', value: description),
                          _rowDivider(),
                          _DetailRowWithIcon(
                            label: 'Category',
                            value: categoryName.isNotEmpty ? categoryName : '—',
                            iconPath: categoryIconP,
                            iconColor: categoryName.isNotEmpty
                                ? categoryColor(categoryName, type: _type)
                                : null,
                          ),
                          _rowDivider(),
                          _DetailRowWithIcon(
                            label: 'For',
                            value: subCategoryName.isNotEmpty ? subCategoryName : '—',
                            iconPath: subCategoryIconP,
                            iconColor: subCategoryName.isNotEmpty
                                ? subCategoryColor(subCategoryName, type: _type)
                                : null,
                          ),
                          _rowDivider(),
                          _DetailRow(
                            label: 'Wallet',
                            value: walletName.isNotEmpty ? walletName : '—',
                          ),
                          _rowDivider(),
                          _DetailRow(label: 'Date', value: dateLabel),
                          _rowDivider(),
                          _DetailRow(label: 'Time', value: timeLabel),
                          if (notes.isNotEmpty) ...[
                            _rowDivider(),
                            _DetailRow(label: 'Note', value: notes),
                          ],
                          _rowDivider(),
                          _AttachmentRow(url: receiptUrl),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom action buttons ──────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: context.appColors.inputBorder.withAlpha(180)),
                ),
              ),
              child: Row(
                children: [
                  // Delete button
                  GestureDetector(
                    onTap: _deleting ? null : _confirmDelete,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.expense.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.expense.withAlpha(60),
                        ),
                      ),
                      child: _deleting
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                color: AppColors.expense,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.expense,
                              size: 24,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Edit Transaction button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(
                          'Edit Transaction',
                          style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final router = GoRouter.of(context);
                          final updated = await router.push<bool>(
                            '/transactions/edit',
                            extra: _data,
                          );
                          if (!mounted) return;
                          if (updated == true) {
                            router.pop(true);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail row helpers ────────────────────────────────────────────────────────

Widget _rowDivider() => const Divider(
      height: 1,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
    );

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: context.appColors.placeholderText,
            ),
          ),
          Spacer(),
          Text(
            value.isNotEmpty ? value : '—',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.appColors.labelText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRowWithIcon extends StatelessWidget {
  final String label;
  final String value;
  final String? iconPath;
  final Color? iconColor;
  const _DetailRowWithIcon({
    required this.label,
    required this.value,
    this.iconPath,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: context.appColors.placeholderText,
            ),
          ),
          Spacer(),
          if (iconPath != null) ...[
            Container(
              width: 26,
              height: 26,
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: context.appColors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                iconPath!,
                color: iconColor,
                colorBlendMode: iconColor != null ? BlendMode.srcIn : null,
              ),
            ),
          ],
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.appColors.labelText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attachment row ────────────────────────────────────────────────────────────

class _AttachmentRow extends StatelessWidget {
  final String url;
  const _AttachmentRow({required this.url});

  void _showFullImage(BuildContext context) {
    final resolved = ApiClient.resolveMediaUrl(url);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resolved,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Attachment',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: context.appColors.placeholderText,
            ),
          ),
          Spacer(),
          if (url.isEmpty)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.appColors.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: context.appColors.placeholderText,
                size: 28,
              ),
            )
          else
          GestureDetector(
            onTap: () => _showFullImage(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ApiClient.resolveMediaUrl(url),
                width: 80,
                height: 80,
                cacheWidth: 160,
                cacheHeight: 160,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.appColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.appColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: context.appColors.placeholderText,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
