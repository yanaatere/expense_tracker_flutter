import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/services/transaction_service.dart';
import '../../core/models/wallet.dart';
import '../../core/services/wallet_service.dart';
import '../../service_locator.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _type = 'income';
  String _amountStr = '0';

  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubCategory;

  List<Map<String, dynamic>> _wallets = [];
  Map<String, dynamic>? _selectedWallet;

  bool _submitting = false;

  File? _receiptFile;
  String? _receiptUrl;
  bool _uploadingReceipt = false;
  bool _receiptHovered = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wallets = await ServiceLocator.walletRepository.getWallets()
        .catchError((_) => <Wallet>[]);
    if (!mounted) return;
    setState(() {
      _categories = localCategories(type: _type);
      _wallets = wallets.map((w) => <String, dynamic>{
        'id': w.serverId != null ? int.tryParse(w.serverId!) : null,
        'name': w.name,
        'type': w.type,
        'balance': w.balance,
      }).where((m) => m['id'] != null).toList();
      if (_wallets.isNotEmpty) _selectedWallet = _wallets.first;
    });
  }

  void _reloadCategories() {
    setState(() => _categories = localCategories(type: _type));
  }

  Future<void> _showCategoryPicker() async {
    final cat = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemPickerSheet(
        title: 'Select Category',
        items: _categories,
        selectedId: _selectedCategory?['id'],
        type: _type,
        isSub: false,
      ),
    );
    if (cat == null || !mounted) return;
    setState(() {
      _selectedCategory = cat;
      _selectedSubCategory = null; // reset sub when category changes
    });
  }

  Future<void> _showSubCategoryPicker() async {
    if (_selectedCategory == null) return;
    final categoryName = _selectedCategory!['name'] as String;
    final items = localSubcategories(categoryName, type: _type);
    if (items.isEmpty) return;

    final sub = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemPickerSheet(
        title: categoryName,
        items: items,
        selectedId: _selectedSubCategory?['id'],
        type: _type,
        isSub: true,
      ),
    );
    if (sub == null || !mounted) return;
    setState(() => _selectedSubCategory = sub);
  }

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

  Future<void> _removeReceipt() async {
    final urlToDelete = _receiptUrl;
    setState(() {
      _receiptFile = null;
      _receiptUrl = null;
    });
    if (urlToDelete != null) {
      try {
        await TransactionService.deleteReceipt(urlToDelete);
      } on DioException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(WalletService.errorMessage(e))),
          );
        }
      }
    }
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _receiptFile = File(picked.path);
      _uploadingReceipt = true;
    });

    try {
      final url = await TransactionService.uploadReceipt(_receiptFile!);
      if (mounted) setState(() { _receiptUrl = url; });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(WalletService.errorMessage(e))),
        );
        setState(() { _receiptFile = null; });
      }
    } finally {
      if (mounted) setState(() { _uploadingReceipt = false; });
    }
  }

  Future<void> _showSuccessDialog() async {
    final label = _type == 'income' ? 'Income' : 'Expense';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => _SuccessDialog(label: label),
    );
    if (mounted) context.pop();
  }

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
    try {
      await TransactionService.createTransaction(
        type: _type,
        amount: _amount,
        description: _titleController.text,
        categoryId: _selectedCategory?['id'] as int?,
        subCategoryId: _selectedSubCategory?['id'] as int?,
        walletId: _selectedWallet!['id'] as int?,
        receiptImageUrl: _receiptUrl,
      );
      if (mounted) await _showSuccessDialog();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(WalletService.errorMessage(e))),
        );
      }
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == 'income';
    final label = isIncome ? 'Add Income' : 'Add Expense';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────────
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

            // ── Income / Expense toggle ────────────────────────────────────
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
                      onTap: () {
                        setState(() {
                          _type = 'income';
                          _selectedCategory = null;
                          _selectedSubCategory = null;
                        });
                        _reloadCategories();
                      },
                    ),
                    _ToggleTab(
                      label: 'Expense',
                      selected: !isIncome,
                      onTap: () {
                        setState(() {
                          _type = 'expense';
                          _selectedCategory = null;
                          _selectedSubCategory = null;
                        });
                        _reloadCategories();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Amount display ─────────────────────────────────────────────
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

            // ── Category + Sub-category pills ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _CategoryPill(
                      label: _selectedCategory != null
                          ? _selectedCategory!['name'] as String
                          : 'Category',
                      icon: _selectedCategory != null
                          ? _CategoryIcon(
                              name: _selectedCategory!['name'] as String,
                              isSub: false,
                              size: 18,
                              type: _type,
                            )
                          : const Icon(Icons.grid_view_rounded,
                              size: 16, color: AppColors.placeholderText),
                      hasValue: _selectedCategory != null,
                      enabled: _categories.isNotEmpty,
                      onTap: _showCategoryPicker,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CategoryPill(
                      label: _selectedSubCategory != null
                          ? _selectedSubCategory!['name'] as String
                          : 'Sub-category',
                      icon: _selectedSubCategory != null
                          ? _CategoryIcon(
                              name: _selectedSubCategory!['name'] as String,
                              isSub: true,
                              size: 18,
                              type: _type,
                            )
                          : const Icon(Icons.list_rounded,
                              size: 16, color: AppColors.placeholderText),
                      hasValue: _selectedSubCategory != null,
                      enabled: _selectedCategory != null,
                      onTap: _showSubCategoryPicker,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Input row 1: Title + Wallet ────────────────────────────────
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
                    wallets: _wallets,
                    selected: _selectedWallet,
                    onChanged: (w) => setState(() => _selectedWallet = w),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Input row 2: Note + Attach ─────────────────────────────────
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
                      if (_receiptUrl != null) {
                        setState(() => _receiptHovered = true);
                      }
                    },
                    onExit: (_) => setState(() => _receiptHovered = false),
                    child: GestureDetector(
                      onTap: (_uploadingReceipt || _submitting)
                          ? null
                          : (_receiptUrl != null && _receiptHovered)
                              ? _removeReceipt
                              : (_receiptUrl == null)
                                  ? _pickReceipt
                                  : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _receiptUrl != null
                              ? (_receiptHovered
                                  ? AppColors.expense.withValues(alpha: 0.12)
                                  : const Color(0xFF5AC45A).withValues(alpha: 0.15))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: _uploadingReceipt
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
                                      _receiptUrl != null
                                          ? (_receiptHovered
                                              ? Icons.delete_outline_rounded
                                              : Icons.check_circle_rounded)
                                          : Icons.attach_file_rounded,
                                      key: ValueKey(
                                        _receiptUrl != null
                                            ? (_receiptHovered ? 'remove' : 'check')
                                            : 'add',
                                      ),
                                      size: 16,
                                      color: _receiptUrl != null
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
                                      fontWeight: _receiptHovered && _receiptUrl != null
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: _receiptUrl != null
                                          ? (_receiptHovered
                                              ? AppColors.expense
                                              : const Color(0xFF5AC45A))
                                          : AppColors.placeholderText,
                                    ),
                                    child: Text(
                                      _receiptUrl != null
                                          ? (_receiptHovered ? 'Remove' : 'Receipt')
                                          : 'Add',
                                    ),
                                  ),
                                  if (_receiptUrl != null && !_receiptHovered) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: _submitting ? null : _removeReceipt,
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

            // ── Numpad ─────────────────────────────────────────────────────
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

            // ── Submit button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
        const Expanded(child: SizedBox()),
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
