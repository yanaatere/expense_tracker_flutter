import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/wallet.dart';
import '../../core/services/wallet_service.dart';
import '../../service_locator.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

List<Color> _gradientForType(String type) {
  switch (type) {
    case 'Bank':
      return [const Color(0xFF96FBC4), const Color(0xFF74EBD5), const Color(0xFF9FACE6)];
    case 'E-Wallet':
      return [const Color(0xFF667EEA), const Color(0xFF764BA2), const Color(0xFF89F7FE)];
    case 'Cash':
      return [const Color(0xFF84FAB0), const Color(0xFF8FD3F4), const Color(0xFFE0C3FC)];
    default:
      return [const Color(0xFFA18CD1), const Color(0xFFFBC2EB), const Color(0xFFFFD6A5)];
  }
}

String _iconForType(String type) {
  switch (type) {
    case 'Bank':
      return 'assets/icons/wallets/bank.png';
    case 'E-Wallet':
      return 'assets/icons/wallets/ewallet.png';
    case 'Cash':
      return 'assets/icons/wallets/money.png';
    default:
      return 'assets/icons/wallets/creditcard.png';
  }
}

double _toUsd(double amount, String currency) {
  switch (currency) {
    case 'IDR':
      return amount / 15500;
    case 'EUR':
      return amount * 1.08;
    default:
      return amount;
  }
}

String _formatBalance(double amount, String currency) {
  switch (currency) {
    case 'IDR':
      return 'Rp. ${NumberFormat('#,##0', 'en_US').format(amount)}';
    case 'EUR':
      return '€ ${NumberFormat('#,##0.##').format(amount)}';
    default:
      return '\$ ${NumberFormat('#,##0.##').format(amount)}';
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'Bank':
      return 'Bank Account';
    case 'E-Wallet':
      return 'E-Wallet';
    case 'Cash':
      return 'Cash';
    default:
      return type;
  }
}

String _currencyLabel(String currency) {
  switch (currency) {
    case 'IDR':
      return '(RP) Indonesian Rupiah';
    case 'USD':
      return '(USD) US Dollar';
    case 'EUR':
      return '(EUR) Euro';
    default:
      return currency;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late Wallet _wallet;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => const _DeleteWalletDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ServiceLocator.walletRepository.deleteWallet(wallet: _wallet);
      if (mounted) context.pop();
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(WalletService.errorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet;
    final gradient = _gradientForType(wallet.type);
    final usdAmount = _toUsd(wallet.balance, wallet.currency);
    final usdText = '/ USD ${NumberFormat('#,##0.##').format(usdAmount)}';

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
                      wallet.name,
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
                    // ── Gradient wallet card ─────────────────────────────────
                    Container(
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.first.withAlpha(120),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                _iconForType(wallet.type),
                                width: 28,
                                height: 28,
                                color: Colors.white,
                              ),
                              Text(
                                wallet.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            _formatBalance(wallet.balance, wallet.currency),
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            usdText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

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
                      children: [
                        Expanded(
                          child: _InfoField(
                            label: 'Type',
                            value: _typeLabel(wallet.type),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoField(
                            label: 'Goals',
                            value: wallet.goals?.isNotEmpty == true
                                ? wallet.goals!
                                : '—',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Wallet Name ──────────────────────────────────────────
                    _InfoField(label: 'Wallet Name', value: wallet.name),

                    const SizedBox(height: 16),

                    // ── Currency ─────────────────────────────────────────────
                    _InfoField(
                      label: 'Currency',
                      value: _currencyLabel(wallet.currency),
                    ),

                    const SizedBox(height: 16),

                    // ── Balance ──────────────────────────────────────────────
                    _InfoField(
                      label: 'Balance',
                      value: NumberFormat('#,##0', 'en_US').format(wallet.balance),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom actions ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  // Delete button
                  GestureDetector(
                    onTap: _deleting ? null : _confirmDelete,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8776F),
                        shape: BoxShape.circle,
                      ),
                      child: _deleting
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Edit Wallet button
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final updated = await context
                            .push<Wallet>('/wallet/edit', extra: _wallet);
                        if (updated != null && mounted) {
                          setState(() => _wallet = updated);
                        }
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Wallet',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
    );
  }
}

// ── Info field ────────────────────────────────────────────────────────────────

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.placeholderText,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Delete confirmation dialog ────────────────────────────────────────────────

class _DeleteWalletDialog extends StatelessWidget {
  const _DeleteWalletDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Small header label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Delete Wallet',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.placeholderText,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Delete Wallet',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.labelText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Body
            Text(
              'By deleting this wallet you will no longer be able to see any transactions on this wallet.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.placeholderText,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                // Cancel
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7CB87A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8776F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4534A),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Delete',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
