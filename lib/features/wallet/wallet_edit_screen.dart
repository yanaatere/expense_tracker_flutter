import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/wallet_definitions.dart';
import '../../core/models/wallet.dart';
import '../../core/services/wallet_service.dart';
import '../../service_locator.dart';
import '../../shared/widgets/wallet_card.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class WalletEditScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletEditScreen({super.key, required this.wallet});

  @override
  State<WalletEditScreen> createState() => _WalletEditScreenState();
}

class _WalletEditScreenState extends State<WalletEditScreen> {
  late String _type;
  late String _currency;
  late final TextEditingController _nameController;
  late final TextEditingController _goalsController;
  late final TextEditingController _balanceController;

  List<WalletOption> _walletOptions = [];
  String? _selectedWalletName;
  bool _isCustomName = false;

  String? _backdropImage;

  bool _loading = false;
  String? _error;

  static const _backdropAssets = [
    'assets/images/backdrop_wallets/Card 1.webp',
    'assets/images/backdrop_wallets/Card 2.webp',
    'assets/images/backdrop_wallets/Card 3.webp',
    'assets/images/backdrop_wallets/Card 4.webp',
    'assets/images/backdrop_wallets/Card 5.webp',
    'assets/images/backdrop_wallets/Card 6.webp',
    'assets/images/backdrop_wallets/Card 7.webp',
    'assets/images/backdrop_wallets/Card 8.webp',
    'assets/images/backdrop_wallets/Card 9.webp',
    'assets/images/backdrop_wallets/Card 10.webp',
  ];

  static const _types = ['Bank', 'Credit', 'E-Wallet', 'Cash'];
  static const _currencies = [
    {'code': 'IDR', 'label': '(RP) Indonesian Rupiah'},
    {'code': 'USD', 'label': '(USD) US Dollar'},
    {'code': 'EUR', 'label': '(EUR) Euro'},
  ];

  bool get _showDropdown => _walletOptions.isNotEmpty && !_isCustomName;

  String get _effectiveName {
    if (_isCustomName) {
      return _nameController.text.isEmpty ? 'My Wallet' : _nameController.text;
    }
    return _selectedWalletName ?? _nameController.text;
  }

  double get _previewBalance =>
      double.tryParse(_balanceController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _type = w.type;
    _currency = w.currency;
    _goalsController = TextEditingController(text: w.goals ?? '');
    _balanceController = TextEditingController(
      text: w.balance == w.balance.truncateToDouble()
          ? w.balance.toInt().toString()
          : w.balance.toString(),
    );

    _backdropImage = widget.wallet.backdropImage ??
        _backdropAssets[Random().nextInt(_backdropAssets.length)];

    // Set up wallet name state
    final options = WalletDefinitions.optionsFor(_type);
    _walletOptions = options;
    final nameMatch = options.any((o) => o.name == w.name);
    if (nameMatch) {
      _selectedWalletName = w.name;
      _isCustomName = false;
      _nameController = TextEditingController(text: w.name);
    } else {
      _selectedWalletName = options.isNotEmpty ? options.first.name : null;
      _isCustomName = options.isEmpty || w.name.isNotEmpty;
      _nameController = TextEditingController(text: w.name);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalsController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? newType) {
    if (newType == null) return;
    final options = WalletDefinitions.optionsFor(newType);
    setState(() {
      _type = newType;
      _walletOptions = options;
      _selectedWalletName = options.isNotEmpty ? options.first.name : null;
      _isCustomName = options.isEmpty;
      if (!_isCustomName) _nameController.clear();
    });
  }

  void _onWalletNameSelected(String? name) {
    if (name == null) return;
    final isOther = WalletDefinitions.otherValues.contains(name);
    setState(() {
      _selectedWalletName = name;
      _isCustomName = isOther;
      if (!isOther) _nameController.clear();
    });
  }

  void _onCustomizeCard() {
    String? pending = _backdropImage;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (_, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose Card Background',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.labelText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _backdropAssets.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                    ),
                    itemBuilder: (_, i) {
                      final asset = _backdropAssets[i];
                      final isSelected = pending == asset;
                      return GestureDetector(
                        onTap: () => setSheetState(() => pending = asset),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            image: DecorationImage(
                              image: AssetImage(asset),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() => _backdropImage = pending);
                      Navigator.of(sheetCtx).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Apply',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    final name = _effectiveName.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Wallet name cannot be empty.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final updated = await ServiceLocator.walletRepository.updateWallet(
        wallet: widget.wallet,
        name: name,
        type: _type,
        currency: _currency,
        balance: double.tryParse(_balanceController.text) ?? 0,
        goals: _goalsController.text.trim().isEmpty
            ? null
            : _goalsController.text.trim(),
        backdropImage: _backdropImage,
      );

      if (!mounted) return;
      context.pop(updated);
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = WalletService.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────────
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
                      widget.wallet.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
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

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Live wallet card preview ──────────────────────────────
                    WalletCardWidget(
                      wallet: widget.wallet,
                      typeOverride: _type,
                      nameOverride: _effectiveName.isEmpty
                          ? widget.wallet.name
                          : _effectiveName,
                      balanceOverride: _previewBalance,
                      currencyOverride: _currency,
                      backdropOverride: _backdropImage,
                    ),

                    const SizedBox(height: 10),

                    // Customize Card link
                    Center(
                      child: TextButton(
                        onPressed: _onCustomizeCard,
                        child: Text(
                          'Customize Card',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ── Card Information title ───────────────────────────────
                    Center(
                      child: Text(
                        'Card Information',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.labelText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Type + Goals row ─────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _EditField(
                            label: 'Type',
                            child: _DropdownField<String>(
                              value: _type,
                              items: _types
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          t,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColors.placeholderText,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: _onTypeChanged,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EditField(
                            label: 'Goals',
                            child: _InputField(
                              controller: _goalsController,
                              hintText: 'e.g. Savings',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Wallet Name ──────────────────────────────────────────
                    _EditField(
                      label: 'Wallet Name',
                      child: _showDropdown
                          ? _DropdownField<String>(
                              value: _selectedWalletName ??
                                  _walletOptions.first.name,
                              items: _walletOptions
                                  .map((o) => DropdownMenuItem(
                                        value: o.name,
                                        child: Text(
                                          o.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColors.placeholderText,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: _onWalletNameSelected,
                            )
                          : _InputField(
                              controller: _nameController,
                              hintText: _type == 'Cash'
                                  ? 'e.g. Cash on Hand'
                                  : 'Enter wallet name',
                              onChanged: (_) => setState(() {}),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // ── Currency ─────────────────────────────────────────────
                    _EditField(
                      label: 'Currency',
                      child: _DropdownField<String>(
                        value: _currency,
                        items: _currencies
                            .map((c) => DropdownMenuItem(
                                  value: c['code'],
                                  child: Text(
                                    c['label']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.placeholderText,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _currency = v ?? _currency),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Balance ──────────────────────────────────────────────
                    _EditField(
                      label: 'Balance',
                      child: _InputField(
                        controller: _balanceController,
                        hintText: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Save button ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GestureDetector(
                onTap: _loading ? null : _save,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _loading
                        ? AppColors.primary.withAlpha(160)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  alignment: Alignment.center,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit field wrapper ────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final Widget child;

  const _EditField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.labelText,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.placeholderText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.placeholderText,
        ),
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.placeholderText,
          size: 20,
        ),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.placeholderText,
        ),
      ),
    );
  }
}
