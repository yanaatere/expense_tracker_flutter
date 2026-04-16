import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/dao/budget_dao.dart';
import '../../core/theme/app_colors_theme.dart';
import '../../shared/widgets/primary_button.dart';
import 'cubit/budget_cubit.dart';

// ---------------------------------------------------------------------------
// Budget Detail Screen
// ---------------------------------------------------------------------------

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;
  final double spending;

  const BudgetDetailScreen({
    super.key,
    required this.budget,
    required this.spending,
  });

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  late Budget _budget;
  late double _spending;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _spending = widget.spending;
  }

  double get _pct =>
      _budget.monthlyLimit > 0 ? (_spending / _budget.monthlyLimit).clamp(0.0, 1.0) : 0.0;

  Color get _barColor =>
      _pct >= 1.0 ? Colors.red : _pct >= 0.8 ? Colors.orange : const Color(0xFF10B981);

  String get _statusLabel =>
      _pct >= 1.0 ? 'Exceeded' : _pct >= 0.8 ? 'Warning' : 'Normal';

  Color get _statusColor =>
      _pct >= 1.0 ? Colors.red : _pct >= 0.8 ? Colors.orange : const Color(0xFF10B981);

  String get _periodBadgeLabel {
    switch (_budget.period) {
      case 'daily':
        return 'Daily Budgeting';
      case 'weekly':
        return 'Weekly Budgeting';
      default:
        return 'Monthly Budgeting';
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Budget',
            style: GoogleFonts.urbanist(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete the "${_budget.displayName}" budget? This cannot be undone.',
          style: GoogleFonts.urbanist(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: GoogleFonts.urbanist(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      if (_budget.id != null) {
        await context.read<BudgetCubit>().delete(_budget.id!);
      }
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final spendingFormatted = fmt.format(_spending);
    final limitFormatted = fmt.format(_budget.monthlyLimit);
    final pctLabel = (_pct * 100).toStringAsFixed(0);
    final color = categoryColor(_budget.categoryName, type: 'expense');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
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
                      _budget.displayName,
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Notification alert card ──────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.appColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notification alert',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.appColors.labelText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'You will receive a notification when your budget is almost at its limit',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 11,
                                    color: context.appColors.placeholderText,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _budget.notificationEnabled,
                            activeThumbColor: AppColors.primary,
                            onChanged: (_) async {
                              await context
                                  .read<BudgetCubit>()
                                  .toggleNotification(_budget);
                              setState(() {
                                _budget = _budget.copyWith(
                                  notificationEnabled: !_budget.notificationEnabled,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Period + status badges ────────────────────────────
                    Row(
                      children: [
                        _Badge(label: _periodBadgeLabel, color: AppColors.primary),
                        const SizedBox(width: 8),
                        _Badge(label: _statusLabel, color: _statusColor),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Budget name ──────────────────────────────────────
                    Text(
                      _budget.displayName,
                      style: GoogleFonts.urbanist(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.labelText,
                      ),
                    ),
                    Text(
                      _budget.categoryName,
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: context.appColors.placeholderText,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── % used (large) ───────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '$pctLabel%',
                            style: GoogleFonts.urbanist(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: _barColor,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(Rp $spendingFormatted) Used of the budget',
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: context.appColors.placeholderText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Expense vs Budget row ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Expense',
                                style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    color: context.appColors.placeholderText)),
                            Text('Rp $spendingFormatted',
                                style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.appColors.labelText)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Budget',
                                style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    color: context.appColors.placeholderText)),
                            Text('Rp $limitFormatted',
                                style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: color)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Progress bar ──────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _pct,
                        minHeight: 8,
                        backgroundColor: _barColor.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                      ),
                    ),

                    // ── Status message ────────────────────────────────────
                    if (_pct >= 0.8) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _barColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _barColor.withAlpha(40)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('💡', style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pct >= 1.0
                                    ? 'You\'ve exceeded your ${_budget.displayName} budget. Time to review your spending!'
                                    : 'The budget is getting cozy: $pctLabel% used. Let\'s prioritize the essentials for now.',
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  color: _barColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom action row ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  // Delete button
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEEEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: AppColors.expense, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Edit button
                  Expanded(
                    child: PrimaryButton(
                      label: 'Edit Budgeting',
                      onPressed: () async {
                        await context.push('/budget/add', extra: _budget);
                        // Refresh spending after edit
                        if (context.mounted) context.read<BudgetCubit>().load();
                        if (context.mounted) context.pop();
                      },
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

// ---------------------------------------------------------------------------
// Badge chip
// ---------------------------------------------------------------------------

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
