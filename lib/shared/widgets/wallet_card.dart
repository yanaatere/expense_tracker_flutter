import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/models/wallet.dart';
import '../../core/utils/currency_formatter.dart';

// ── Private helpers ───────────────────────────────────────────────────────────

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


// ── Widget ────────────────────────────────────────────────────────────────────

/// Reusable wallet card used across wallet_screen, wallet_detail_screen,
/// wallet_edit_screen, and wallet_transaction_screen.
///
/// Override params let the edit screen show a live preview without
/// mutating the wallet model.
class WalletCardWidget extends StatelessWidget {
  final Wallet wallet;

  /// Card height. Defaults to 170.
  final double height;

  /// Optional fixed width. When null the card expands to fill its parent.
  final double? width;

  /// Live-preview overrides — used by the edit screen.
  final String? typeOverride;
  final String? nameOverride;
  final double? balanceOverride;
  final String? currencyOverride;
  final String? backdropOverride;

  /// Whether to show the drop shadow. Set to false for inactive carousel cards.
  final bool elevated;

  const WalletCardWidget({
    super.key,
    required this.wallet,
    this.height = 230,
    this.width = 310,
    this.typeOverride,
    this.nameOverride,
    this.balanceOverride,
    this.currencyOverride,
    this.backdropOverride,
    this.elevated = true,
  });

  String get _type => typeOverride ?? wallet.type;
  String get _name => nameOverride ?? wallet.name;
  double get _balance => balanceOverride ?? wallet.balance;
  String get _currency => currencyOverride ?? wallet.currency;
  String? get _backdrop => backdropOverride ?? wallet.backdropImage;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientForType(_type);
    final usd = _toUsd(_balance, _currency);
    final usdText = '/ USD ${NumberFormat('#,##0.##').format(usd)}';

    Widget card = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _backdrop == null
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: _backdrop != null
            ? DecorationImage(
                image: AssetImage(_backdrop!),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: _backdrop != null
                      ? Colors.black.withAlpha(60)
                      : gradient.first.withAlpha(120),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : [],
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
                _iconForType(_type),
                width: 28,
                height: 28,
                color: Colors.white,
              ),
              Text(
                _name,
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
            formatCurrency(_balance, _currency),
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
    );

    return width != null ? Center(child: card) : card;
  }
}
