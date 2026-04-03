import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import 'cubit/transaction_form_cubit.dart';
import 'cubit/transaction_form_state.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionFormCubit()..loadData(type: 'income'),
      child: const _AddTransactionView(),
    );
  }
}

class _AddTransactionView extends StatefulWidget {
  const _AddTransactionView();

  @override
  State<_AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<_AddTransactionView> {
  String _amountStr = '0';
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  File? _receiptFile;
  bool _receiptHovered = false;

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

  Future<void> _showCategoryPicker(TransactionFormState formState) async {
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
    context.read<TransactionFormCubit>().setCategory(cat);
  }

  Future<void> _showSubCategoryPicker(TransactionFormState formState) async {
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
    context.read<TransactionFormCubit>().setSubCategory(sub);
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _receiptFile = File(picked.path));
    if (!mounted) return;
    await context.read<TransactionFormCubit>().uploadReceipt(_receiptFile!);
    if (mounted && context.read<TransactionFormCubit>().state.receiptUrl == null) {
      setState(() => _receiptFile = null);
    }
  }

  Future<void> _removeReceipt() async {
    setState(() => _receiptFile = null);
    await context.read<TransactionFormCubit>().deleteReceipt();
  }

  Future<void> _showSuccessDialog(String type) async {
    final label = type == 'income' ? 'Income' : 'Expense';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => _SuccessDialog(label: label),
    );
    if (mounted) context.pop();
  }

  Future<void> _submit(TransactionFormState formState) async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }
    if (formState.selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet')),
      );
      return;
    }
    await context.read<TransactionFormCubit>().submit(
      amount: _amount,
      description: _titleController.text,
      note: _noteController.text,
      date: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionFormCubit, TransactionFormState>(
      listenWhen: (prev, curr) =>
          curr.submitSuccess != prev.submitSuccess ||
          curr.submitError != prev.submitError,
      listener: (context, state) {
        if (state.submitSuccess) {
          _showSuccessDialog(state.transactionType);
        } else if (state.submitError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.submitError!)),
          );
        }
      },
      builder: (context, formState) {
        final isIncome = formState.transactionType == 'income';
        final label = isIncome ? 'Add Income' : 'Add Expense';
        final receiptUrl = formState.receiptUrl;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ── App bar ──────────────────────────────────────────────
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
                          'Add Transaction',
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

                // ── Income / Expense toggle ──────────────────────────────
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
                          onTap: () => context
                              .read<TransactionFormCubit>()
                              .setType('income'),
                        ),
                        _ToggleTab(
                          label: 'Expense',
                          selected: !isIncome,
                          onTap: () => context
                              .read<TransactionFormCubit>()
                              .setType('expense'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Amount display ───────────────────────────────────────
                Column(
                  children: [
                    Text(
                      label,
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

                const SizedBox(height: 24),

                // ── Category + Sub-category pills ────────────────────────
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

                const SizedBox(height: 10),

                // ── Input row 1: Title + Wallet ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: _titleController,
                          hint: 'Title',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _WalletPicker(
                        wallets: formState.wallets,
                        selected: formState.selectedWallet,
                        onChanged: (w) =>
                            context.read<TransactionFormCubit>().setWallet(w),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Input row 2: Note + Attach ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: _noteController,
                          hint: 'Note',
                        ),
                      ),
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) {
                          if (receiptUrl != null) {
                            setState(() => _receiptHovered = true);
                          }
                        },
                        onExit: (_) => setState(() => _receiptHovered = false),
                        child: GestureDetector(
                          onTap: (formState.uploadingReceipt || formState.submitting)
                              ? null
                              : (receiptUrl != null && _receiptHovered)
                                  ? _removeReceipt
                                  : (receiptUrl == null)
                                      ? _pickReceipt
                                      : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: receiptUrl != null
                                  ? (_receiptHovered
                                      ? AppColors.expense.withValues(alpha: 0.12)
                                      : const Color(0xFF5AC45A).withValues(alpha: 0.15))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: formState.uploadingReceipt
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          receiptUrl != null
                                              ? (_receiptHovered
                                                  ? Icons.delete_outline_rounded
                                                  : Icons.check_circle_rounded)
                                              : Icons.attach_file_rounded,
                                          key: ValueKey(
                                            receiptUrl != null
                                                ? (_receiptHovered ? 'remove' : 'check')
                                                : 'add',
                                          ),
                                          size: 16,
                                          color: receiptUrl != null
                                              ? (_receiptHovered
                                                  ? AppColors.expense
                                                  : const Color(0xFF5AC45A))
                                              : AppColors.placeholderText,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: GoogleFonts.urbanist(
                                          fontSize: 13,
                                          fontWeight: _receiptHovered && receiptUrl != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: receiptUrl != null
                                              ? (_receiptHovered
                                                  ? AppColors.expense
                                                  : const Color(0xFF5AC45A))
                                              : AppColors.placeholderText,
                                        ),
                                        child: Text(
                                          receiptUrl != null
                                              ? (_receiptHovered ? 'Remove' : 'Receipt')
                                              : 'Add',
                                        ),
                                      ),
                                      if (receiptUrl != null && !_receiptHovered) ...[
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: formState.submitting
                                              ? null
                                              : _removeReceipt,
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Color(0xFF5AC45A),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Numpad ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _NumRow(keys: ['1', '2', '3'], onDigit: _onDigit, onBackspace: _onBackspace),
                      const SizedBox(height: 10),
                      _NumRow(keys: ['4', '5', '6'], onDigit: _onDigit, onBackspace: _onBackspace),
                      const SizedBox(height: 10),
                      _NumRow(keys: ['7', '8', '9'], onDigit: _onDigit, onBackspace: _onBackspace),
                      const SizedBox(height: 10),
                      _NumLastRow(onDigit: _onDigit, onBackspace: _onBackspace),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Submit button ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: formState.submitting
                          ? null
                          : () => _submit(formState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 0,
                      ),
                      child: formState.submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              label,
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Success dialog ────────────────────────────────────────────────────────────

class _SuccessDialog extends StatefulWidget {
  final String label;
  const _SuccessDialog({required this.label});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF5AC45A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.label} transactions\nhave been added',
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.labelText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle tab ────────────────────────────────────────────────────────────────

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
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.placeholderText,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category icon helper ──────────────────────────────────────────────────────

class _CategoryIcon extends StatelessWidget {
  final String name;
  final bool isSub;
  final double size;
  final String type;

  const _CategoryIcon({
    required this.name,
    required this.isSub,
    this.size = 28,
    this.type = 'income',
  });

  @override
  Widget build(BuildContext context) {
    final path = isSub
        ? subCategoryIconPath(name, type: type)
        : categoryIconPath(name, type: type);
    if (path == null) {
      return Icon(Icons.category_rounded,
          size: size, color: AppColors.placeholderText);
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      errorBuilder: (context, error, stack) => Icon(Icons.category_rounded,
          size: size, color: AppColors.placeholderText),
    );
  }
}

// ── Category pill button ──────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  color: hasValue
                      ? AppColors.labelText
                      : AppColors.placeholderText,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: enabled
                  ? AppColors.placeholderText
                  : AppColors.placeholderText.withAlpha(80),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item picker bottom sheet (category or sub-category) ───────────────────────

class _ItemPickerSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final String type;
  final bool isSub;

  const _ItemPickerSheet({
    required this.title,
    required this.items,
    required this.type,
    required this.isSub,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle + title (fixed, doesn't scroll) ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.inputBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.labelText,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // ── Scrollable list ──────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
            ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final name = item['name'] as String;
            final isSelected = item['id'] != null && item['id'] == selectedId;
            final color = isSub
                ? subCategoryColor(name, type: type, fallbackIndex: index)
                : categoryColor(name, type: type, fallbackIndex: index);

            return GestureDetector(
              onTap: () => Navigator.pop(context, item),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withAlpha(20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Colored left accent bar (categories only)
                    if (!isSub)
                      Container(
                        width: 4,
                        height: 52,
                        margin: const EdgeInsets.only(left: 4, right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _CategoryIcon(
                          name: name, isSub: isSub, size: 24, type: type),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : AppColors.labelText,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.check_rounded, size: 18, color: color),
                      ),
                  ],
                ),
              ),
            );
          }),
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

// ── Input field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _InputField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(40),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.labelText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.urbanist(
            fontSize: 13,
            color: AppColors.placeholderText,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}

// ── Wallet picker ─────────────────────────────────────────────────────────────

class _WalletPicker extends StatelessWidget {
  final List<Map<String, dynamic>> wallets;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _WalletPicker({
    required this.wallets,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: wallets.isEmpty
          ? null
          : () => showDialog<void>(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.4),
                builder: (_) => _WalletDialog(
                  wallets: wallets,
                  selected: selected,
                  onSelect: (w) {
                    onChanged(w);
                    Navigator.pop(context);
                  },
                ),
              ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected?['name'] as String? ?? 'Wallet',
              style: GoogleFonts.urbanist(
                fontSize: 13,
                color: AppColors.labelText,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.placeholderText),
          ],
        ),
      ),
    );
  }
}

class _WalletDialog extends StatelessWidget {
  final List<Map<String, dynamic>> wallets;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _WalletDialog({
    required this.wallets,
    required this.selected,
    required this.onSelect,
  });

  String _formatType(String type) {
    return type
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatBalance(dynamic raw) {
    final num value = raw is num ? raw : num.tryParse(raw.toString()) ?? 0;
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp. $formatted,-';
  }

  @override
  Widget build(BuildContext context) {
    // Group wallets by type
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final w in wallets) {
      final type = w['type'] as String? ?? 'other';
      grouped.putIfAbsent(type, () => []).add(w);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Center(
              child: Text(
                'Select Wallet',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelText,
                ),
              ),
            ),
          ),

          // Groups
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                _formatType(entry.key),
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelText,
                ),
              ),
            ),
            for (final w in entry.value)
              _WalletRow(
                wallet: w,
                isSelected: selected?['id'] == w['id'],
                onTap: () => onSelect(w),
                formatBalance: _formatBalance,
              ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WalletRow extends StatelessWidget {
  final Map<String, dynamic> wallet;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(dynamic) formatBalance;

  const _WalletRow({
    required this.wallet,
    required this.isSelected,
    required this.onTap,
    required this.formatBalance,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                wallet['name'] as String? ?? '',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.labelText,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Balance',
                  style: GoogleFonts.urbanist(
                    fontSize: 11,
                    color: AppColors.placeholderText,
                  ),
                ),
                Text(
                  formatBalance(wallet['balance']),
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.labelText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Numpad ────────────────────────────────────────────────────────────────────

class _NumRow extends StatelessWidget {
  final List<String> keys;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _NumRow({
    required this.keys,
    required this.onDigit,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: keys.map((k) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _NumKey(
              label: k,
              onTap: () => onDigit(k),
            ),
          ),
        );
      }).toList(),
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _NumKey(
              label: '⌫',
              isAction: true,
              onTap: onBackspace,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _NumKey(label: '0', onTap: () => onDigit('0')),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _NumKey(label: '00', onTap: () => onDigit('00')),
          ),
        ),
      ],
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;

  const _NumKey({
    required this.label,
    required this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: isAction ? 20 : 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
