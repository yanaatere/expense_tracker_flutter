import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/storage/local_storage.dart';
import '../../core/models/recurring_transaction.dart';
import 'cubit/recurring_cubit.dart';
import 'cubit/recurring_state.dart';
import '../../../core/theme/app_colors_theme.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecurringCubit()..load(),
      child: const _RecurringView(),
    );
  }
}

class _RecurringView extends StatelessWidget {
  const _RecurringView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
body: SafeArea(
        child: Column(
          children: [
            // App bar
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
                      'Scheduled Transaction',
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

            // Body
            Expanded(
              child: BlocBuilder<RecurringCubit, RecurringState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.items.isEmpty) {
                    return _EmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<RecurringCubit>().load(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: state.items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () async {
                          await context.push(
                            '/recurring/detail',
                            extra: state.items[i],
                          );
                          if (context.mounted) {
                            context.read<RecurringCubit>().load();
                          }
                        },
                        child: _RecurringItem(item: state.items[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // FAB to add schedule
      floatingActionButton: BlocBuilder<RecurringCubit, RecurringState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final isPremium = await LocalStorage.isPremium();
                  if (!context.mounted) return;
                  final count = context.read<RecurringCubit>().state.items.length;
                  if (!isPremium && count >= 3) {
                    final upgraded = await context.push<bool>('/premium');
                    if (upgraded != true || !context.mounted) return;
                  }
                  final added = await context.push<bool>('/recurring/add');
                  if (added == true && context.mounted) {
                    context.read<RecurringCubit>().load();
                  }
                },
                backgroundColor: AppColors.primary,
                elevation: 2,
                label: Text(
                  'Add Schedule',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No transaction Scheduled',
        style: GoogleFonts.urbanist(
          fontSize: 15,
          color: context.appColors.placeholderText,
        ),
      ),
    );
  }
}

class _RecurringItem extends StatelessWidget {
  final RecurringTransaction item;
  const _RecurringItem({required this.item});

  String get _frequencyLabel {
    switch (item.frequency) {
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
    final val = item.amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'Rp. $val/$_frequencyLabel';
  }

  @override
  Widget build(BuildContext context) {
    final catId = item.categoryId;
    final subCatId = item.subCategoryId;
    final type = item.type;

    // Resolve category & sub-category names.
    String? catName;
    String? subCatName;
    if (catId != null) {
      final cats = localCategories(type: type);
      final match = cats.firstWhere((c) => c['id'] == catId, orElse: () => {});
      catName = match['name'] as String?;
    }
    if (subCatId != null && catName != null) {
      final subs = localSubcategories(catName, type: type);
      final match = subs.firstWhere((s) => s['id'] == subCatId, orElse: () => {});
      subCatName = match['name'] as String?;
    }

    final iconPath = catName != null
        ? categoryIconPath(catName, type: type)
        : null;
    final color = catName != null
        ? categoryColor(catName, type: type)
        : context.appColors.placeholderText;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
      ),
      onDismissed: (_) => context.read<RecurringCubit>().delete(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: type == 'income'
              ? AppColors.income.withValues(alpha: 0.06)
              : AppColors.expense.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: type == 'income'
                ? AppColors.income.withValues(alpha: 0.15)
                : AppColors.expense.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: iconPath != null
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(iconPath, color: color),
                    )
                  : Icon(Icons.sync, color: color, size: 22),
            ),
            const SizedBox(width: 12),

            // Title + sub-category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.labelText,
                    ),
                  ),
                  if (subCatName != null || catName != null)
                    Text(
                      subCatName ?? catName!,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: context.appColors.placeholderText,
                      ),
                    ),
                ],
              ),
            ),

            // Amount / frequency
            Text(
              _amountLabel,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: type == 'income' ? AppColors.income : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
