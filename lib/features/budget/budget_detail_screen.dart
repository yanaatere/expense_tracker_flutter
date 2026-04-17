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

class _BudgetDetailScreenState extends State<BudgetDetailScreen>
    with SingleTickerProviderStateMixin {
  late Budget _budget;
  late double _spending;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool get _shouldAlert => _budget.notificationEnabled && _pct >= 0.9;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _spending = widget.spending;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    if (_shouldAlert) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _shakeController.forward();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  double get _pct =>
      _budget.monthlyLimit > 0 ? (_spending / _budget.monthlyLimit).clamp(0.0, 1.5) : 0.0;

  String get _statusLabel {
    if (_pct >= 1.0) return 'Overbudget';
    if (_pct >= 0.9) return 'Warning';
    if (_pct >= 0.3) return 'Normal';
    return 'Safe';
  }

  Color get _statusColor {
    if (_pct >= 1.0) return const Color(0xFFEF4444);
    if (_pct >= 0.9) return const Color(0xFFF59E0B);
    if (_pct >= 0.3) return const Color(0xFF10B981);
    return const Color(0xFF635AFF);
  }

  Color get _barColor => _statusColor;

  String get _statusMessage {
    final tier = (_pct * 10).floor().clamp(0, 10);
    switch (tier) {
      case 1:
        return "Fresh start! You've only used a tiny bit of your budget. Off to a great start!";
      case 2:
        return "Looking good! You're keeping things well under control. Keep that momentum!";
      case 3:
        return "Nicely done! 30% in and you're still cruising smoothly. Practicality at its best!";
      case 4:
        return "Steady as she goes! You're approaching the halfway mark. Doing great so far!";
      case 5:
        return "Halfway there! You've used 50% of your budget. Plenty left for the rest of the week!";
      case 6:
        return "Passed the halfway point! Time to be a bit more mindful of those extra treats. You got this!";
      case 7:
        return "Heads up! You've used 70%. Maybe it's time to skip that extra latte? Just a thought!";
      case 8:
        return "The budget is getting cozy! 80% used. Let's prioritize the essentials for now.";
      case 9:
        return "Tighten the belt! You're at 90%. Almost at the limit—choose your next moves wisely!";
      default:
        if (tier >= 10) {
          return "Target reached! You've hit your budget limit. Time to pause and prep for next week!";
        }
        return '';
    }
  }

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
                          AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(_shouldAlert ? _shakeAnimation.value : 0, 0),
                              child: child,
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
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
                              final turningOn = !_budget.notificationEnabled;
                              setState(() {
                                _budget = _budget.copyWith(
                                  notificationEnabled: turningOn,
                                );
                              });
                              if (turningOn && _pct >= 0.9) {
                                _shakeController.reset();
                                _shakeController.forward();
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // ── Alert banner — uses AnimatedSize so it never ghost-reserves space ──
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: _shouldAlert
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _pct >= 1.0
                                      ? const Color(0xFFEF4444).withAlpha(18)
                                      : const Color(0xFFF59E0B).withAlpha(18),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _pct >= 1.0
                                        ? const Color(0xFFEF4444).withAlpha(80)
                                        : const Color(0xFFF59E0B).withAlpha(80),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _pct >= 1.0
                                          ? Icons.warning_rounded
                                          : Icons.notifications_active_rounded,
                                      color: _pct >= 1.0
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFFF59E0B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _pct >= 1.0
                                            ? 'Budget limit exceeded! You have spent more than your set budget for this category.'
                                            : 'You\'re close to your budget limit! Only ${(100 - _pct * 100).toStringAsFixed(0)}% remaining.',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _pct >= 1.0
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFF59E0B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
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
                        value: _pct.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: _barColor.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                      ),
                    ),

                    // ── Status message ────────────────────────────────────
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _statusColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: _statusColor.withAlpha(40)),
                        ),
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: _statusColor,
                            height: 1.5,
                          ),
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
