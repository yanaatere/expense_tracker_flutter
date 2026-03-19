import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/wallet_service.dart';
import '../../core/storage/local_storage.dart';
import '../../shared/widgets/primary_button.dart';

class SetupWalletScreen extends StatefulWidget {
  const SetupWalletScreen({super.key});

  @override
  State<SetupWalletScreen> createState() => _SetupWalletScreenState();
}

class _SetupWalletScreenState extends State<SetupWalletScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _goalsController = TextEditingController();

  String _currency = 'IDR';
  String _type = 'Bank';
  bool _loading = false;
  String? _error;

  static const _currencies = [
    {'code': 'IDR', 'label': 'Indonesian Rupiah (Rp)'},
    {'code': 'USD', 'label': 'US Dollar (\$)'},
    {'code': 'EUR', 'label': 'Euro (€)'},
  ];

  static const _types = ['Bank', 'E-Wallet', 'Cash'];

  String get _walletNamePreview =>
      _nameController.text.isEmpty ? 'Wallet' : _nameController.text;

  String get _balancePreview {
    final raw = _balanceController.text.isEmpty ? '0' : _balanceController.text;
    final amount = double.tryParse(raw) ?? 0;
    if (_currency == 'IDR') {
      return 'Rp. ${_formatAmount(amount)}';
    } else if (_currency == 'USD') {
      return '\$ ${_formatAmount(amount)}';
    } else {
      return '€ ${_formatAmount(amount)}';
    }
  }

  String _formatAmount(double amount) {
    if (amount == amount.truncate()) {
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return amount.toString();
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WalletService.createWallet(
        name: _nameController.text.isEmpty ? 'My Wallet' : _nameController.text,
        type: _type,
        currency: _currency,
        balance: double.tryParse(_balanceController.text) ?? 0,
        goals: _goalsController.text,
      );
      await LocalStorage.setOnboardingCompleted();
      if (mounted) context.go('/home');
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addLater() async {
    await LocalStorage.setOnboardingCompleted();
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(l10n.settingUpWallet, style: AppTextStyles.heading),
              const SizedBox(height: 24),

              // Wallet card preview
              _WalletCardPreview(
                name: _walletNamePreview,
                balance: _balancePreview,
              ),
              const SizedBox(height: 32),

              // Wallet Name
              _FieldLabel(l10n.walletName),
              const SizedBox(height: 8),
              _TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                hintText: 'e.g. Mandiri',
              ),
              const SizedBox(height: 20),

              // Currency
              _FieldLabel(l10n.currency),
              const SizedBox(height: 8),
              _Dropdown<String>(
                value: _currency,
                items: _currencies
                    .map((c) => DropdownMenuItem<String>(
                          value: c['code'],
                          child: Text(c['label']!),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? _currency),
              ),
              const SizedBox(height: 20),

              // Balance
              _FieldLabel(l10n.balance),
              const SizedBox(height: 8),
              _TextField(
                controller: _balanceController,
                onChanged: (_) => setState(() {}),
                hintText: '0',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Type
              _FieldLabel(l10n.type),
              const SizedBox(height: 8),
              _Dropdown<String>(
                value: _type,
                items: _types
                    .map((t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 20),

              // Goals
              _FieldLabel(l10n.goals),
              const SizedBox(height: 8),
              _TextField(
                controller: _goalsController,
                hintText: 'e.g. Save for holiday',
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],

              // Add Later
              Center(
                child: TextButton(
                  onPressed: _loading ? null : _addLater,
                  child: Text(
                    l10n.addLater,
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Save
              PrimaryButton(
                label: l10n.save,
                onPressed: _loading ? null : _save,
                isLoading: _loading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletCardPreview extends StatelessWidget {
  final String name;
  final String balance;

  const _WalletCardPreview({required this.name, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFF9A825), Color(0xFFFB8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF9A825).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Balance',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                balance,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF7B5EA7), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF7B5EA7), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
