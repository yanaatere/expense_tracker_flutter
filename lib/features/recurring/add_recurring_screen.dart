import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import 'cubit/recurring_form_cubit.dart';
import 'cubit/recurring_form_state.dart';

class AddRecurringScreen extends StatelessWidget {
  const AddRecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecurringFormCubit()..loadData(type: 'income'),
      child: const _AddRecurringView(),
    );
  }
}

// ─── View ────────────────────────────────────────────────────────────────────

class _AddRecurringView extends StatefulWidget {
  const _AddRecurringView();

  @override
  State<_AddRecurringView> createState() => _AddRecurringViewState();
}

class _AddRecurringViewState extends State<_AddRecurringView> {
  String _amountStr = '0';
  final _titleController = TextEditingController();

  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now();
  int _spanValue = 1;
  String _spanUnit = 'years';

  double get _amount => double.tryParse(_amountStr) ?? 0;

  String get _formattedAmount {
    final val = _amount;
    if (val == 0) return 'Rp. 0';
    final formatted = val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'Rp. $formatted';
  }

  String get _startDateLabel {
    final d = _startDate;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year.toString().substring(2)}';
  }

  DateTime get _endDate {
    switch (_spanUnit) {
      case 'days':
        return _startDate.add(Duration(days: _spanValue));
      case 'weeks':
        return _startDate.add(Duration(days: _spanValue * 7));
      case 'months':
        return DateTime(_startDate.year, _startDate.month + _spanValue, _startDate.day);
      default:
        return DateTime(_startDate.year + _spanValue, _startDate.month, _startDate.day);
    }
  }

  String _dateToStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _spanUnitLabel(int value) {
    switch (_spanUnit) {
      case 'days':
        return value == 1 ? 'Day' : 'Days';
      case 'weeks':
        return value == 1 ? 'Week' : 'Weeks';
      case 'months':
        return value == 1 ? 'Month' : 'Months';
      default:
        return value == 1 ? 'Year' : 'Years';
    }
  }

  void _onDigit(String d) {
    setState(() {
      if (d == '00') {
        if (_amountStr != '0' && _amountStr.length < 11) {
          _amountStr += '00';
        }
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _showCategoryPicker(RecurringFormState formState) async {
    final cat = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemPickerSheet(
        title: 'Select Category',
        items: formState.categories,
        selectedId: formState.selectedCategory?['id'],
        type: formState.transactionType,
        isSub: false,
      ),
    );
    if (cat == null || !mounted) return;
    context.read<RecurringFormCubit>().setCategory(cat);
  }

  Future<void> _showSubCategoryPicker(RecurringFormState formState) async {
    if (formState.selectedCategory == null) return;
    final categoryName = formState.selectedCategory!['name'] as String;
    final items = localSubcategories(categoryName, type: formState.transactionType);
    if (items.isEmpty) return;

    final sub = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemPickerSheet(
        title: categoryName,
        items: items,
        selectedId: formState.selectedSubCategory?['id'],
        type: formState.transactionType,
        isSub: true,
      ),
    );
    if (sub == null || !mounted) return;
    context.read<RecurringFormCubit>().setSubCategory(sub);
  }

  Future<void> _submit(RecurringFormState formState) async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final router = GoRouter.of(context);
    await context.read<RecurringFormCubit>().submit(
      amount: _amount,
      title: _titleController.text.trim(),
      frequency: _frequency,
      startDate: _dateToStr(_startDate),
      endDate: _dateToStr(_endDate),
    );

    if (!mounted) return;
    final state = context.read<RecurringFormCubit>().state;
    if (state.submitSuccess) {
      router.pop(true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecurringFormCubit, RecurringFormState>(
      listenWhen: (prev, curr) =>
          curr.submitError != prev.submitError && curr.submitError != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.submitError!)),
        );
      },
      builder: (context, formState) {
        final isIncome = formState.transactionType == 'income';

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ── App bar ─────────────────────────────────────────────
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
                          'Add Schedule',
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

                // ── Toggle ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      children: [
                        _ToggleTab(
                          label: 'Income',
                          selected: isIncome,
                          onTap: () =>
                              context.read<RecurringFormCubit>().setType('income'),
                        ),
                        _ToggleTab(
                          label: 'Expense',
                          selected: !isIncome,
                          onTap: () =>
                              context.read<RecurringFormCubit>().setType('expense'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Amount display ────────────────────────────────────────
                Column(
                  children: [
                    Text(
                      isIncome ? 'Add Income Schedule' : 'Add Expense Schedule',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: AppColors.placeholderText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedAmount,
                      style: GoogleFonts.urbanist(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.labelText,
                      ),
                    ),
                    Text(
                      'Enter Amount',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: AppColors.placeholderText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Scrollable form fields ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Category + Sub-category pills
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _CategoryPill(
                                  label: formState.selectedCategory != null
                                      ? formState.selectedCategory!['name'] as String
                                      : 'Category',
                                  icon: formState.selectedCategory != null
                                      ? _CategoryIcon(
                                          name: formState.selectedCategory!['name'] as String,
                                          isSub: false,
                                          size: 18,
                                          type: formState.transactionType,
                                        )
                                      : const Icon(Icons.grid_view_rounded,
                                          size: 16, color: AppColors.placeholderText),
                                  hasValue: formState.selectedCategory != null,
                                  enabled: formState.categories.isNotEmpty,
                                  onTap: () => _showCategoryPicker(formState),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _CategoryPill(
                                  label: formState.selectedSubCategory != null
                                      ? formState.selectedSubCategory!['name'] as String
                                      : 'Sub-category',
                                  icon: formState.selectedSubCategory != null
                                      ? _CategoryIcon(
                                          name: formState.selectedSubCategory!['name'] as String,
                                          isSub: true,
                                          size: 18,
                                          type: formState.transactionType,
                                        )
                                      : const Icon(Icons.list_rounded,
                                          size: 16, color: AppColors.placeholderText),
                                  hasValue: formState.selectedSubCategory != null,
                                  enabled: formState.selectedCategory != null,
                                  onTap: () => _showSubCategoryPicker(formState),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tittle',
                                style: GoogleFonts.urbanist(
                                    fontSize: 13, color: AppColors.bodyText),
                              ),
                              const SizedBox(height: 4),
                              _InputField(
                                controller: _titleController,
                                hint: 'e.g., Installment, Billing, Credit Card',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Frequency + Start date
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Frequency',
                                        style: GoogleFonts.urbanist(
                                            fontSize: 13, color: AppColors.bodyText)),
                                    const SizedBox(height: 4),
                                    _DropdownField<String>(
                                      value: _frequency,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'daily', child: Text('Daily')),
                                        DropdownMenuItem(
                                            value: 'weekly', child: Text('Weekly')),
                                        DropdownMenuItem(
                                            value: 'monthly', child: Text('Monthly')),
                                        DropdownMenuItem(
                                            value: 'yearly', child: Text('Yearly')),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _frequency = v ?? 'monthly'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Start date',
                                        style: GoogleFonts.urbanist(
                                            fontSize: 13, color: AppColors.bodyText)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: _pickStartDate,
                                      child: Container(
                                        height: 44,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: AppColors.inputBg,
                                          borderRadius: BorderRadius.circular(40),
                                          border: Border.all(
                                              color: AppColors.inputBorder),
                                        ),
                                        child: Text(
                                          _startDateLabel,
                                          style: GoogleFonts.urbanist(
                                            fontSize: 13,
                                            color: AppColors.labelText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Span Time
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Span Time',
                                  style: GoogleFonts.urbanist(
                                      fontSize: 13, color: AppColors.bodyText)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: _DropdownField<String>(
                                      value: _spanUnit,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'days', child: Text('Daily')),
                                        DropdownMenuItem(
                                            value: 'weeks', child: Text('Weekly')),
                                        DropdownMenuItem(
                                            value: 'months', child: Text('Monthly')),
                                        DropdownMenuItem(
                                            value: 'years', child: Text('Annually')),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _spanUnit = v ?? 'years'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _DropdownField<int>(
                                      value: _spanValue,
                                      items: List.generate(
                                        10,
                                        (i) => DropdownMenuItem(
                                          value: i + 1,
                                          child: Text(
                                              '${i + 1} ${_spanUnitLabel(i + 1)}'),
                                        ),
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _spanValue = v ?? 1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Choose Wallet
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Choose Wallet',
                                  style: GoogleFonts.urbanist(
                                      fontSize: 13, color: AppColors.bodyText)),
                              const SizedBox(height: 4),
                              _DropdownField<Map<String, dynamic>>(
                                value: formState.selectedWallet,
                                items: formState.wallets.map((w) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: w,
                                    child: Text(w['name'] as String? ?? ''),
                                  );
                                }).toList(),
                                onChanged: (w) {
                                  if (w != null) {
                                    context.read<RecurringFormCubit>().setWallet(w);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ── Numpad (pinned at bottom) ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _NumRow(digits: const ['1', '2', '3'], onDigit: _onDigit),
                      const SizedBox(height: 4),
                      _NumRow(digits: const ['4', '5', '6'], onDigit: _onDigit),
                      const SizedBox(height: 4),
                      _NumRow(digits: const ['7', '8', '9'], onDigit: _onDigit),
                      const SizedBox(height: 4),
                      _NumLastRow(onDigit: _onDigit, onBackspace: _onBackspace),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Save button ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
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
                      onPressed:
                          formState.submitting ? null : () => _submit(formState),
                      child: formState.submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'Save',
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.placeholderText,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool hasValue;
  final bool enabled;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.hasValue,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color:
                      hasValue ? AppColors.labelText : AppColors.placeholderText,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: hasValue ? AppColors.primary : AppColors.placeholderText,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String name;
  final bool isSub;
  final double size;
  final String type;

  const _CategoryIcon({
    required this.name,
    required this.isSub,
    required this.size,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final path = isSub
        ? subCategoryIconPath(name, type: type)
        : categoryIconPath(name, type: type);
    final color = isSub
        ? subCategoryColor(name, type: type)
        : categoryColor(name, type: type);

    if (path == null) {
      return Icon(Icons.category_rounded, size: size, color: color);
    }

    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(path, color: color),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _InputField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.labelText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.urbanist(
              fontSize: 13, color: AppColors.placeholderText),
          filled: true,
          fillColor: AppColors.inputBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.placeholderText),
          style:
              GoogleFonts.urbanist(fontSize: 13, color: AppColors.labelText),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Numpad ───────────────────────────────────────────────────────────────────

class _NumRow extends StatelessWidget {
  final List<String> digits;
  final ValueChanged<String> onDigit;

  const _NumRow({required this.digits, required this.onDigit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: digits
          .expand((d) => [
                Expanded(child: _NumKey(label: d, onTap: () => onDigit(d))),
                if (d != digits.last) const SizedBox(width: 8),
              ])
          .toList(),
    );
  }
}

class _NumLastRow extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _NumLastRow({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _NumKey(label: '00', onTap: () => onDigit('00'))),
        const SizedBox(width: 8),
        Expanded(child: _NumKey(label: '0', onTap: () => onDigit('0'))),
        const SizedBox(width: 8),
        Expanded(
          child: _NumKey(label: '⌫', onTap: onBackspace, isBackspace: true),
        ),
      ],
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isBackspace;

  const _NumKey({
    required this.label,
    required this.onTap,
    this.isBackspace = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: isBackspace ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: AppColors.labelText,
          ),
        ),
      ),
    );
  }
}

// ─── Category picker sheet ────────────────────────────────────────────────────

class _ItemPickerSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final String type;
  final bool isSub;

  const _ItemPickerSheet({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.type,
    required this.isSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.labelText,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final id = item['id'] as int?;
                final name = item['name'] as String? ?? '';
                final isSelected = id == selectedId;

                final path = isSub
                    ? subCategoryIconPath(name, type: type)
                    : categoryIconPath(name, type: type);
                final color = isSub
                    ? subCategoryColor(name, type: type)
                    : categoryColor(name, type: type);

                return ListTile(
                  onTap: () => Navigator.of(context).pop(item),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: path != null
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(path, color: color),
                          )
                        : Icon(Icons.category_rounded, color: color, size: 20),
                  ),
                  title: Text(
                    name,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.labelText,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
