import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/models/wallet.dart';
import '../../core/services/api_client.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/wallet_service.dart';
import '../../service_locator.dart';

class EditTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const EditTransactionScreen({super.key, required this.data});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late String _type;
  late double _amount;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubCategory;

  List<Map<String, dynamic>> _wallets = [];
  Map<String, dynamic>? _selectedWallet;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  String? _receiptUrl;
  File? _receiptFile;
  bool _uploadingReceipt = false;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _type = d['type'] as String? ?? 'expense';

    final raw = d['amount'];
    _amount = (raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0).abs();

    _titleController = TextEditingController(text: d['description'] as String? ?? '');
    _noteController = TextEditingController(text: d['notes'] as String? ?? '');
    _receiptUrl = (d['receipt_image_url'] as String? ?? '').isEmpty ? null : d['receipt_image_url'] as String?;

    // Resolve date
    try {
      _selectedDate = DateTime.parse(d['transaction_date'] as String? ?? '');
    } catch (_) {
      _selectedDate = DateTime.now();
    }

    // Resolve time from created_at
    try {
      final dt = DateTime.parse(d['created_at'] as String? ?? '');
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      _selectedTime = TimeOfDay.now();
    }

    // Resolve pre-selected category
    final rawCatId = d['category_id'];
    if (rawCatId != null) {
      final catId = rawCatId is int ? rawCatId : int.tryParse(rawCatId.toString());
      if (catId != null) {
        final cats = localCategories(type: _type);
        final match = cats.firstWhere((c) => c['id'] == catId, orElse: () => {});
        if (match.isNotEmpty) _selectedCategory = match;
      }
    }

    // Resolve pre-selected subcategory
    final rawSubId = d['sub_category_id'];
    if (rawSubId != null && _selectedCategory != null) {
      final subId = rawSubId is int ? rawSubId : int.tryParse(rawSubId.toString());
      if (subId != null) {
        final subs = localSubcategories(_selectedCategory!['name'] as String, type: _type);
        final match = subs.firstWhere((s) => s['id'] == subId, orElse: () => {});
        if (match.isNotEmpty) _selectedSubCategory = match;
      }
    }

    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await ServiceLocator.walletRepository
        .getWallets()
        .catchError((_) => <Wallet>[]);
    if (!mounted) return;
    final rawWalletId = widget.data['wallet_id'];
    final walletId = rawWalletId is int ? rawWalletId : int.tryParse(rawWalletId.toString());

    final mapped = wallets
        .map((w) => <String, dynamic>{
              'id': w.serverId != null ? int.tryParse(w.serverId!) : null,
              'name': w.name,
            })
        .where((m) => m['id'] != null)
        .toList();

    Map<String, dynamic>? matched;
    if (walletId != null) {
      try {
        matched = mapped.firstWhere((w) => w['id'] == walletId);
      } catch (_) {}
    }

    setState(() {
      _wallets = mapped;
      _selectedWallet = matched ?? (mapped.isNotEmpty ? mapped.first : null);
    });
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

  Future<void> _pickCategory() async {
    final cats = localCategories(type: _type);
    final cat = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Select Category',
        items: cats,
        selectedId: _selectedCategory?['id'],
        type: _type,
        isSub: false,
      ),
    );
    if (cat == null || !mounted) return;
    setState(() {
      _selectedCategory = cat;
      _selectedSubCategory = null;
    });
  }

  Future<void> _pickSubCategory() async {
    if (_selectedCategory == null) return;
    final name = _selectedCategory!['name'] as String;
    final subs = localSubcategories(name, type: _type);
    if (subs.isEmpty) return;
    final sub = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: name,
        items: subs,
        selectedId: _selectedSubCategory?['id'],
        type: _type,
        isSub: true,
      ),
    );
    if (sub == null || !mounted) return;
    setState(() => _selectedSubCategory = sub);
  }

  Future<void> _pickWallet() async {
    if (_wallets.isEmpty) return;
    final w = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletSheet(
        wallets: _wallets,
        selectedId: _selectedWallet?['id'],
      ),
    );
    if (w == null || !mounted) return;
    setState(() => _selectedWallet = w);
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

  // ── Receipt ──────────────────────────────────────────────────────────────────

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() { _receiptFile = File(picked.path); _uploadingReceipt = true; });
    try {
      final url = await TransactionService.uploadReceipt(_receiptFile!);
      if (mounted) setState(() => _receiptUrl = url);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(WalletService.errorMessage(e))),
        );
        setState(() => _receiptFile = null);
      }
    } finally {
      if (mounted) setState(() => _uploadingReceipt = false);
    }
  }

  Future<void> _removeReceipt() async {
    final urlToDelete = _receiptUrl;
    setState(() { _receiptFile = null; _receiptUrl = null; });
    if (urlToDelete != null) {
      try {
        await TransactionService.deleteReceipt(urlToDelete);
      } catch (_) {}
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet')),
      );
      return;
    }

    setState(() => _submitting = true);

    final rawId = widget.data['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null) {
      setState(() => _submitting = false);
      return;
    }

    final dateStr =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    try {
      await TransactionService.updateTransaction(
        id: id,
        type: _type,
        amount: _amount,
        description: _titleController.text,
        categoryId: _selectedCategory?['id'] as int?,
        subCategoryId: _selectedSubCategory?['id'] as int?,
        walletId: _selectedWallet!['id'] as int?,
        date: dateStr,
        receiptImageUrl: _receiptUrl,
      );
      if (mounted) {
        await _showSuccessDialog();
        context.pop(true); // signal detail screen to refresh
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(WalletService.errorMessage(e))),
        );
        setState(() => _submitting = false);
      }
    }
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

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == 'income';
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final typeLabel = isIncome ? 'Income' : 'Spending';
    final amountPrefix = isIncome ? '+Rp.' : '-Rp.';
    final formattedAmount = NumberFormat('#,##0', 'en_US').format(_amount);
    final categoryIconP = _selectedCategory != null
        ? categoryIconPath(_selectedCategory!['name'] as String, type: _type)
        : null;
    final dateLabel = DateFormat('d MMM yyyy').format(_selectedDate);
    final timeLabel = _selectedTime.format(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ───────────────────────────────────────────────────────
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

            // ── Amount banner (tap to edit) ───────────────────────────────────
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
                              Icon(Icons.edit_outlined, size: 14, color: amountColor.withAlpha(160)),
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

            // ── Form ─────────────────────────────────────────────────────────
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
                        iconPath: _selectedCategory != null
                            ? categoryIconPath(_selectedCategory!['name'] as String, type: _type)
                            : null,
                        label: _selectedCategory?['name'] as String? ?? 'Category',
                        hasValue: _selectedCategory != null,
                        onTap: _pickCategory,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FormRow(
                      label: 'For',
                      child: _DropdownField(
                        iconPath: _selectedSubCategory != null
                            ? subCategoryIconPath(_selectedSubCategory!['name'] as String, type: _type)
                            : null,
                        label: _selectedSubCategory?['name'] as String? ?? 'Sub-category',
                        hasValue: _selectedSubCategory != null,
                        enabled: _selectedCategory != null,
                        onTap: _pickSubCategory,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FormRow(
                      label: 'Wallet',
                      child: _DropdownField(
                        label: _selectedWallet?['name'] as String? ?? 'Wallet',
                        hasValue: _selectedWallet != null,
                        onTap: _pickWallet,
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

                    // ── Attachment ──────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Existing receipt
                        if (_receiptUrl != null || _receiptFile != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: _receiptUrl != null
                                      ? () => _showFullImage(context, _receiptUrl!)
                                      : null,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _receiptFile != null
                                        ? Image.file(_receiptFile!,
                                            width: 80, height: 80, fit: BoxFit.cover)
                                        : Image.network(
                                            ApiClient.resolveMediaUrl(_receiptUrl!),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
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

                        // Add button
                        if (_receiptUrl == null && _receiptFile == null)
                          GestureDetector(
                            onTap: _uploadingReceipt ? null : _pickReceipt,
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
                              child: _uploadingReceipt
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
                            onTap: _uploadingReceipt ? null : _pickReceipt,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(120),
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                ),
                                color: AppColors.primary.withAlpha(10),
                              ),
                              child: _uploadingReceipt
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

                    // ── Save ────────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withAlpha(120),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                        child: _submitting
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
