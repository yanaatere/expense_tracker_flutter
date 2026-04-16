import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/dao/budget_dao.dart';
import '../../core/theme/app_colors_theme.dart';
import '../../shared/widgets/amount_numpad.dart';
import '../../shared/widgets/primary_button.dart';
import 'cubit/budget_cubit.dart';

// ---------------------------------------------------------------------------
// Add / Edit Budget Screen
// ---------------------------------------------------------------------------

class AddBudgetScreen extends StatefulWidget {
  /// Pass an existing budget to enter edit mode.
  final Budget? existing;

  const AddBudgetScreen({super.key, this.existing});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  late String _period;
  late String _amountStr;
  String? _selectedCategoryName;
  int? _selectedCategoryId;
  late TextEditingController _titleController;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  double get _amount => double.tryParse(_amountStr) ?? 0;

  String get _formattedAmount {
    if (_amount == 0) return 'Rp. 0';
    final v = _amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'Rp. $v';
  }

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _period = b?.period ?? 'monthly';
    _amountStr = b != null ? b.monthlyLimit.toStringAsFixed(0) : '0';
    _selectedCategoryName = b?.categoryName;
    _selectedCategoryId = b?.categoryId;
    _titleController = TextEditingController(text: b?.title ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    setState(() {
      if (d == '00') {
        if (_amountStr != '0' && _amountStr.length < 11) _amountStr += '00';
        return;
      }
      if (_amountStr == '0') {
        _amountStr = d;
      } else if (_amountStr.length < 12) {
        _amountStr += d;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountStr.length <= 1) {
        _amountStr = '0';
      } else {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      }
    });
  }

  Future<void> _save() async {
    if (_amount <= 0 || _selectedCategoryName == null) return;

    setState(() => _saving = true);
    final title = _titleController.text.trim();
    final cubit = context.read<BudgetCubit>();

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        categoryName: _selectedCategoryName,
        categoryId: _selectedCategoryId,
        monthlyLimit: _amount,
        period: _period,
        title: title.isEmpty ? null : title,
        clearTitle: title.isEmpty,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await cubit.update(updated);
    } else {
      await cubit.add(
        _selectedCategoryName!,
        _amount,
        categoryId: _selectedCategoryId,
        period: _period,
        title: title.isEmpty ? null : title,
      );
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = expenseCategories;

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
                      _isEdit ? 'Edit Budget' : 'Set Limit',
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Period tabs ──────────────────────────────────────
                    _PeriodTabs(
                      selected: _period,
                      onChanged: (p) => setState(() => _period = p),
                    ),

                    const SizedBox(height: 24),

                    // ── Amount display ───────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _formattedAmount,
                            style: GoogleFonts.urbanist(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: context.appColors.labelText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter Amount',
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: context.appColors.placeholderText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Category dropdown ────────────────────────────────
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.appColors.inputBg,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryName,
                          hint: Text(
                            'Select category',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              color: context.appColors.placeholderText,
                            ),
                          ),
                          isExpanded: true,
                          items: categories.map((cat) {
                            final name = cat['name'] as String;
                            final color = categoryColor(name, type: 'expense');
                            final iconPath = categoryIconPath(name, type: 'expense');
                            return DropdownMenuItem(
                              value: name,
                              child: Row(
                                children: [
                                  if (iconPath != null) ...[
                                    Image.asset(iconPath, width: 20, height: 20,
                                        color: color, colorBlendMode: BlendMode.srcIn),
                                    const SizedBox(width: 10),
                                  ],
                                  Text(name,
                                      style: GoogleFonts.urbanist(
                                          fontSize: 14, color: context.appColors.labelText)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            final match = categories.firstWhere(
                              (c) => c['name'] == v,
                              orElse: () => {},
                            );
                            setState(() {
                              _selectedCategoryName = v;
                              _selectedCategoryId = match['id'] as int?;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Title field ──────────────────────────────────────
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.urbanist(
                          fontSize: 14, color: context.appColors.labelText),
                      decoration: InputDecoration(
                        hintText: 'e.g., Hangout, Coffee, fuel, grocery',
                        hintStyle: GoogleFonts.urbanist(
                            color: context.appColors.placeholderText),
                        filled: true,
                        fillColor: context.appColors.inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide:
                              const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Numpad ───────────────────────────────────────────
                    AmountNumpad(onDigit: _onDigit, onBackspace: _onBackspace),

                    const SizedBox(height: 24),

                    // ── Save ─────────────────────────────────────────────
                    PrimaryButton(
                      label: 'Save',
                      isLoading: _saving,
                      onPressed: (_amount > 0 && _selectedCategoryName != null)
                          ? _save
                          : null,
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

// ---------------------------------------------------------------------------
// Period tabs
// ---------------------------------------------------------------------------

class _PeriodTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const periods = ['daily', 'weekly', 'monthly'];
    const labels = ['Daily', 'Weekly', 'Monthly'];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.appColors.inputBg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: List.generate(periods.length, (i) {
          final active = selected == periods[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(periods[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : context.appColors.placeholderText,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
