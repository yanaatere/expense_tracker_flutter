import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/dao/budget_dao.dart';
import '../../core/services/ai_service.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors_theme.dart';
import '../../shared/widgets/primary_button.dart';
import 'cubit/budget_cubit.dart';
import 'cubit/budget_state.dart';

// ---------------------------------------------------------------------------
// Budget Screen
// ---------------------------------------------------------------------------

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BudgetCubit()..load(),
      child: const _BudgetView(),
    );
  }
}

class _BudgetView extends StatelessWidget {
  const _BudgetView();

  @override
  Widget build(BuildContext context) {
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
                      'Budgeting',
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

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<BudgetCubit, BudgetState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.budgets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pie_chart_outline_rounded,
                              size: 52, color: context.appColors.inputBorder),
                          const SizedBox(height: 12),
                          Text(
                            'No budgeting',
                            style: GoogleFonts.urbanist(
                              fontSize: 15,
                              color: context.appColors.placeholderText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by period in desired order.
                  final groups = <String, List<Budget>>{};
                  for (final p in ['daily', 'weekly', 'monthly']) {
                    final list = state.budgets.where((b) => b.period == p).toList();
                    if (list.isNotEmpty) groups[p] = list;
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: [
                      for (final entry in groups.entries) ...[
                        _PeriodHeader(period: entry.key),
                        const SizedBox(height: 8),
                        for (final budget in entry.value) ...[
                          _BudgetRow(
                            budget: budget,
                            spending: state.spending[budget.id] ?? 0,
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Bottom buttons ──────────────────────────────────────────────────
      floatingActionButton: BlocBuilder<BudgetCubit, BudgetState>(
        builder: (context, state) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AiSuggestionsButton(cubit: context.read<BudgetCubit>()),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Add Budgeting',
                onPressed: () async {
                  await context.push('/budget/add');
                  if (context.mounted) context.read<BudgetCubit>().load();
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ---------------------------------------------------------------------------
// Period header
// ---------------------------------------------------------------------------

class _PeriodHeader extends StatelessWidget {
  final String period;
  const _PeriodHeader({required this.period});

  String get _label =>
      period == 'daily' ? 'Daily' : period == 'weekly' ? 'Weekly' : 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      style: GoogleFonts.urbanist(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.appColors.placeholderText,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget row
// ---------------------------------------------------------------------------

class _BudgetRow extends StatelessWidget {
  final Budget budget;
  final double spending;

  const _BudgetRow({required this.budget, required this.spending});

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(budget.categoryName, type: 'expense');
    final iconPath = categoryIconPath(budget.categoryName, type: 'expense');
    final pct = budget.monthlyLimit > 0 ? (spending / budget.monthlyLimit).clamp(0.0, 1.0) : 0.0;
    final pctLabel = (pct * 100).toStringAsFixed(0);
    final limitFormatted = NumberFormat('#,##0', 'en_US').format(budget.monthlyLimit);

    final Color barColor = pct >= 1.0
        ? Colors.red
        : pct >= 0.8
            ? Colors.orange
            : const Color(0xFF10B981);

    return GestureDetector(
      onTap: () async {
        await context.push('/budget/detail', extra: {
          'budget': budget,
          'spending': spending,
        });
        if (context.mounted) context.read<BudgetCubit>().load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.appColors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: iconPath != null
                      ? Image.asset(iconPath, color: color, colorBlendMode: BlendMode.srcIn)
                      : Icon(Icons.category_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),

                // Name + limit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.displayName,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.labelText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp $limitFormatted / ${budget.periodLabel}',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: context.appColors.placeholderText,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(Icons.chevron_right_rounded,
                    color: context.appColors.inputBorder, size: 20),
              ],
            ),

            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: barColor.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 6),

            // % label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$pctLabel% of the budget',
                style: GoogleFonts.urbanist(
                  fontSize: 11,
                  color: pct >= 1.0
                      ? Colors.red
                      : pct >= 0.8
                          ? Colors.orange
                          : context.appColors.placeholderText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Suggestions button
// ---------------------------------------------------------------------------

class _AiSuggestionsButton extends StatefulWidget {
  final BudgetCubit cubit;
  const _AiSuggestionsButton({required this.cubit});

  @override
  State<_AiSuggestionsButton> createState() => _AiSuggestionsButtonState();
}

class _AiSuggestionsButtonState extends State<_AiSuggestionsButton> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    LocalStorage.isPremium().then((v) {
      if (mounted) setState(() => _isPremium = v);
    });
  }

  Future<void> _showSuggestions() async {
    if (!_isPremium) {
      await context.push('/premium');
      return;
    }

    final suggestions = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiSuggestionsSheet(),
    );

    if (suggestions != null && mounted) {
      for (final s in suggestions) {
        final cat = s['category'] as String?;
        final limit = (s['limit'] as num?)?.toDouble();
        if (cat != null && limit != null) {
          await widget.cubit.add(cat, limit);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showSuggestions,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          backgroundColor: context.appColors.background,
        ),
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: Text(
          'AI Budget Suggestions',
          style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Suggestions Sheet
// ---------------------------------------------------------------------------

class _AiSuggestionsSheet extends StatefulWidget {
  const _AiSuggestionsSheet();

  @override
  State<_AiSuggestionsSheet> createState() => _AiSuggestionsSheetState();
}

class _AiSuggestionsSheetState extends State<_AiSuggestionsSheet> {
  List<Map<String, dynamic>>? _suggestions;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await AiService.budgetSuggestions();
      if (mounted) setState(() { _suggestions = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load suggestions.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: context.appColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.appColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('AI Budget Suggestions',
                    style: GoogleFonts.urbanist(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: context.appColors.labelText)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, style: GoogleFonts.urbanist(color: context.appColors.placeholderText)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _suggestions?.length ?? 0,
                        separatorBuilder: (context2, idx) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final s = _suggestions![i];
                          final cat = s['category'] as String? ?? '';
                          final limit = (s['limit'] as num?)?.toDouble() ?? 0;
                          final color = categoryColor(cat, type: 'expense');
                          final formatted = NumberFormat('#,##0', 'en_US').format(limit);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: context.appColors.cardBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(30), shape: BoxShape.circle),
                                  child: Icon(Icons.category_rounded, color: color, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(cat,
                                    style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600,
                                        color: context.appColors.labelText))),
                                Text('Rp $formatted',
                                    style: GoogleFonts.urbanist(fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          if (!_loading && _error == null && (_suggestions?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  onPressed: () => Navigator.of(context).pop(_suggestions),
                  child: Text('Apply All',
                      style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
