import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/services/api_client.dart';
import 'cubit/transaction_form_cubit.dart';
import 'cubit/transaction_form_state.dart';

class EditTransactionScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const EditTransactionScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? 'expense';
    final rawReceipt = data['receipt_image_url'] as String?;
    return BlocProvider(
      create: (_) => TransactionFormCubit()
        ..loadData(
          type: type,
          existingData: data,
          existingReceiptUrl: (rawReceipt?.isNotEmpty ?? false) ? rawReceipt : null,
        ),
      child: _EditTransactionView(data: data),
    );
  }
}

class _EditTransactionView extends StatefulWidget {
  final Map<String, dynamic> data;
  const _EditTransactionView({required this.data});

  @override
  State<_EditTransactionView> createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<_EditTransactionView> {
  late final String _type;
  late double _amount;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  File? _receiptFile;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _type = d['type'] as String? ?? 'expense';

    final raw = d['amount'];
    _amount = (raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0).abs();

    _titleController = TextEditingController(text: d['description'] as String? ?? '');
    _noteController = TextEditingController(text: d['notes'] as String? ?? '');

    try {
      _selectedDate = DateTime.parse(d['transaction_date'] as String? ?? '');
    } catch (_) {
      _selectedDate = DateTime.now();
    }

    try {
      final dt = DateTime.parse(d['created_at'] as String? ?? '');
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Pickers ──────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  Future<void> _pickCategory(TransactionFormState formState) async {
    final cats = localCategories(type: _type);
    final cat = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Select Category',
        items: cats,
        selectedId: formState.selectedCategory?['id'],
        type: _type,
        isSub: false,
      ),
    );
    if (cat == null || !mounted) return;
    context.read<TransactionFormCubit>().setCategory(cat);
  }

  Future<void> _pickSubCategory(TransactionFormState formState) async {
    if (formState.selectedCategory == null) return;
    final name = formState.selectedCategory!['name'] as String;
    final subs = localSubcategories(name, type: _type);
    if (subs.isEmpty) return;
    final sub = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: name,
        items: subs,
        selectedId: formState.selectedSubCategory?['id'],
        type: _type,
        isSub: true,
      ),
    );
    if (sub == null || !mounted) return;
    context.read<TransactionFormCubit>().setSubCategory(sub);
  }

  Future<void> _pickWallet(TransactionFormState formState) async {
    if (formState.wallets.isEmpty) return;
    final w = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletSheet(
        wallets: formState.wallets,
        selectedId: formState.selectedWallet?['id'],
      ),
    );
    if (w == null || !mounted) return;
    context.read<TransactionFormCubit>().setWallet(w);
  }

  Future<void> _editAmount() async {
    final ctrl = TextEditingController(
      text: _amount == 0 ? '' : _amount.toStringAsFixed(0),
    );
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AmountSheet(controller: ctrl),
    );
    if (result != null && mounted) setState(() => _amount = result);
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
    final rawId = widget.data['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null) return;

    await context.read<TransactionFormCubit>().update(
      transactionId: id,
      amount: _amount,
      description: _titleController.text,
      date: _selectedDate,
      time: _selectedTime,
    );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => Dialog(
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
                  color: AppColors.income,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Transaction updated\nsuccessfully',
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
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionFormCubit, TransactionFormState>(
      listenWhen: (prev, curr) =>
          curr.submitSuccess != prev.submitSuccess ||
          curr.submitError != prev.submitError,
      listener: (listenerContext, state) async {
        if (state.submitSuccess) {
          final router = GoRouter.of(listenerContext);
          await _showSuccessDialog();
          if (!mounted) return;
          router.pop(true);
        } else if (state.submitError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.submitError!)),
          );
        }
      },
      builder: (context, formState) {
        final isIncome = _type == 'income';
        final amountColor = isIncome ? AppColors.income : AppColors.expense;
        final typeLabel = isIncome ? 'Income' : 'Spending';
        final amountPrefix = isIncome ? '+Rp.' : '-Rp.';
        final formattedAmount = NumberFormat('#,##0', 'en_US').format(_amount);
        final categoryIconP = formState.selectedCategory != null
            ? categoryIconPath(formState.selectedCategory!['name'] as String,
                type: _type)
            : null;
        final dateLabel = DateFormat('d MMM yyyy').format(_selectedDate);
        final timeLabel = _selectedTime.format(context);
        final receiptUrl = formState.receiptUrl;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ── App bar ─────────────────────────────────────────────────
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
                          'Transaction Detail',
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

                // ── Amount banner ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: GestureDetector(
                    onTap: _editAmount,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: amountColor.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(14),
                          child: categoryIconP != null
                              ? Image.asset(categoryIconP)
                              : Icon(
                                  isIncome
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: amountColor,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                typeLabel,
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  color: AppColors.placeholderText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '$amountPrefix $formattedAmount',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: amountColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit_outlined,
                                      size: 14, color: amountColor.withAlpha(160)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, thickness: 0.5),

                // ── Form ─────────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        _FormRow(
                          label: 'Title',
                          child: _TextInput(controller: _titleController, hint: 'Title'),
                        ),
                        const SizedBox(height: 12),
                        _FormRow(
                          label: 'Category',
                          child: _DropdownField(
                            iconPath: formState.selectedCategory != null
                                ? categoryIconPath(
                                    formState.selectedCategory!['name'] as String,
                                    type: _type)
                                : null,
                            label: formState.selectedCategory?['name'] as String? ??
                                'Category',
                            hasValue: formState.selectedCategory != null,
                            onTap: () => _pickCategory(formState),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FormRow(
                          label: 'For',
                          child: _DropdownField(
                            iconPath: formState.selectedSubCategory != null
                                ? subCategoryIconPath(
                                    formState.selectedSubCategory!['name'] as String,
                                    type: _type)
                                : null,
                            label: formState.selectedSubCategory?['name'] as String? ??
                                'Sub-category',
                            hasValue: formState.selectedSubCategory != null,
                            enabled: formState.selectedCategory != null,
                            onTap: () => _pickSubCategory(formState),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FormRow(
                          label: 'Wallet',
                          child: _DropdownField(
                            label: formState.selectedWallet?['name'] as String? ??
                                'Wallet',
                            hasValue: formState.selectedWallet != null,
                            onTap: () => _pickWallet(formState),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FormRow(
                          label: 'Date',
                          child: _DropdownField(
                            label: dateLabel,
                            hasValue: true,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FormRow(
                          label: 'Time',
                          child: _DropdownField(
                            label: timeLabel,
                            hasValue: true,
                            onTap: _pickTime,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FormRow(
                          label: 'Note',
                          child: _TextInput(controller: _noteController, hint: 'Note'),
                        ),
                        const SizedBox(height: 20),

                        // ── Attachment ────────────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (receiptUrl != null || _receiptFile != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: receiptUrl != null
                                          ? () => _showFullImage(context, receiptUrl)
                                          : null,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: _receiptFile != null
                                            ? Image.file(_receiptFile!,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover)
                                            : Image.network(
                                                ApiClient.resolveMediaUrl(receiptUrl!),
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, stack) => Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: AppColors.cardBg,
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                    color: AppColors.placeholderText,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: _removeReceipt,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(Icons.close_rounded,
                                              size: 14, color: AppColors.expense),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (receiptUrl == null && _receiptFile == null)
                              GestureDetector(
                                onTap: formState.uploadingReceipt ? null : _pickReceipt,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primary.withAlpha(120),
                                      width: 1.5,
                                      strokeAlign: BorderSide.strokeAlignInside,
                                    ),
                                    color: AppColors.primary.withAlpha(10),
                                  ),
                                  child: formState.uploadingReceipt
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : const Icon(Icons.add_rounded,
                                          color: AppColors.primary, size: 28),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: formState.uploadingReceipt ? null : _pickReceipt,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primary.withAlpha(120),
                                      width: 1.5,
                                    ),
                                    color: AppColors.primary.withAlpha(10),
                                  ),
                                  child: formState.uploadingReceipt
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : const Icon(Icons.add_rounded,
                                          color: AppColors.primary, size: 28),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              'Attachment',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                color: AppColors.placeholderText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Save ──────────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: formState.submitting
                                ? null
                                : () => _submit(formState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary.withAlpha(120),
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
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Save',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  void _showFullImage(BuildContext context, String url) {
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
                ApiClient.resolveMediaUrl(url),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Form row ──────────────────────────────────────────────────────────────────

class _FormRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: AppColors.placeholderText,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

// ── Text input ────────────────────────────────────────────────────────────────

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _TextInput({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.labelText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.urbanist(
            fontSize: 14,
            color: AppColors.placeholderText,
          ),
          filled: true,
          fillColor: AppColors.cardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

// ── Dropdown field ────────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String? iconPath;
  final String label;
  final bool hasValue;
  final bool enabled;
  final VoidCallback onTap;

  const _DropdownField({
    this.iconPath,
    required this.label,
    required this.hasValue,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            if (iconPath != null) ...[
              Image.asset(iconPath!, width: 20, height: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                  color: hasValue ? AppColors.labelText : AppColors.placeholderText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: enabled ? AppColors.placeholderText : AppColors.inputBorder,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Amount edit sheet ─────────────────────────────────────────────────────────

class _AmountSheet extends StatelessWidget {
  final TextEditingController controller;
  const _AmountSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Edit Amount',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.labelText,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.labelText,
            ),
            decoration: InputDecoration(
              prefixText: 'Rp. ',
              prefixStyle: GoogleFonts.urbanist(
                fontSize: 16,
                color: AppColors.placeholderText,
              ),
              filled: true,
              fillColor: AppColors.cardBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                Navigator.of(context).pop(val);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category/Subcategory picker sheet ─────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final String type;
  final bool isSub;

  const _PickerSheet({
    required this.title,
    required this.items,
    this.selectedId,
    required this.type,
    required this.isSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.labelText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final name = item['name'] as String;
                final id = item['id'] as int;
                final isSelected = id == selectedId;
                final iconPath = isSub
                    ? subCategoryIconPath(name, type: type)
                    : categoryIconPath(name, type: type);
                return ListTile(
                  leading: iconPath != null
                      ? Image.asset(iconPath, width: 28, height: 28)
                      : Icon(Icons.category_rounded,
                          size: 24, color: AppColors.placeholderText),
                  title: Text(
                    name,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.labelText,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 18)
                      : null,
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Wallet picker sheet ───────────────────────────────────────────────────────

class _WalletSheet extends StatelessWidget {
  final List<Map<String, dynamic>> wallets;
  final int? selectedId;
  const _WalletSheet({required this.wallets, this.selectedId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select Wallet',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.labelText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...wallets.map((w) {
            final isSelected = w['id'] == selectedId;
            return ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.primary, size: 24),
              title: Text(
                w['name'] as String,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.labelText,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 18)
                  : null,
              onTap: () => Navigator.of(context).pop(w),
            );
          }),
        ],
      ),
    );
  }
}
