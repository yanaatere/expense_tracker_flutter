import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/wallet.dart';
import '../../service_locator.dart';

// ── Gradient palette per wallet type ────────────────────────────────────────

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

// USD conversion rates (approximate, offline)
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
      final f = NumberFormat('#,##0', 'en_US');
      return 'Rp. ${f.format(amount)}';
    case 'EUR':
      return '€ ${NumberFormat('#,##0.##').format(amount)}';
    default:
      return '\$ ${NumberFormat('#,##0.##').format(amount)}';
  }
}

String _formatUsd(double amount, String currency) {
  final usd = _toUsd(amount, currency);
  return '/ USD ${NumberFormat('#,##0.##').format(usd)}';
}

// ── Screen ───────────────────────────────────────────────────────────────────

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<Wallet> _wallets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final wallets = await ServiceLocator.walletRepository.getWallets();
    if (mounted) setState(() { _wallets = wallets; _loading = false; });
  }

  double get _totalBalance {
    // Sum everything normalised to IDR equivalents for display simplicity;
    // if all wallets are IDR just show IDR total.
    return _wallets.fold(0.0, (sum, w) => sum + w.balance);
  }

  bool get _allSameCurrency =>
      _wallets.isEmpty || _wallets.every((w) => w.currency == _wallets.first.currency);

  String get _totalCurrency => _wallets.isEmpty ? 'IDR' : _wallets.first.currency;

  Map<String, List<Wallet>> get _grouped {
    final order = ['Cash', 'Bank', 'E-Wallet'];
    final map = <String, List<Wallet>>{};
    for (final type in order) {
      final list = _wallets.where((w) => w.type == type).toList();
      if (list.isNotEmpty) map[type] = list;
    }
    // Catch any other types
    for (final w in _wallets) {
      if (!order.contains(w.type)) {
        map.putIfAbsent(w.type, () => []).add(w);
      }
    }
    return map;
  }

  String _sectionLabel(String type) {
    switch (type) {
      case 'Bank': return 'Bank Account';
      case 'E-Wallet': return 'E-Wallet';
      case 'Cash': return 'Cash';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────
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
                      'Wallet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.labelText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance the back button
                ],
              ),
            ),

            // ── Total balance ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset('assets/icons/wallets/wallet.png', width: 22, height: 22, color: Colors.white,),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Balance',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.placeholderText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _allSameCurrency
                        ? _formatBalance(_totalBalance, _totalCurrency)
                        : _formatBalance(_totalBalance, 'IDR'),
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.labelText,
                    ),
                  ),
                ],
              ),
            ),

            // ── Wallet list ───────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _wallets.isEmpty
                      ? _EmptyState(onAdd: _navigateToAdd)
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 32),
                          children: [
                            for (final entry in _grouped.entries) ...[
                              _SectionHeader(label: _sectionLabel(entry.key)),
                              _WalletTypeRow(
                                wallets: entry.value,
                                onAddWallet: () => _navigateToAdd(type: entry.key),
                                onWalletChanged: _load,
                              ),
                              const SizedBox(height: 8),
                            ],
                            // "Add Wallet" section when we have wallets
                            _AddWalletRow(onTap: _navigateToAdd),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAdd({String type = 'Bank'}) async {
    await context.push(
      '/onboarding/wallet',
      extra: <String, String>{'returnRoute': '/wallet', 'initialType': type},
    );
    _load();
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.labelText,
        ),
      ),
    );
  }
}

// ── Wallet type row (swipeable if multiple) ───────────────────────────────────

class _WalletTypeRow extends StatefulWidget {
  final List<Wallet> wallets;
  final VoidCallback onAddWallet;
  final VoidCallback onWalletChanged;

  const _WalletTypeRow({
    required this.wallets,
    required this.onAddWallet,
    required this.onWalletChanged,
  });

  @override
  State<_WalletTypeRow> createState() => _WalletTypeRowState();
}

class _WalletTypeRowState extends State<_WalletTypeRow> {
  late final PageController _controller;
  int _page = 0;

  // Total pages = wallets + 1 "Add" card
  int get _pageCount => widget.wallets.length + 1;

  @override
  void initState() {
    super.initState();
    // viewportFraction < 1 so the next card peeks
    _controller = PageController(viewportFraction: 0.82);
    _controller.addListener(() {
      final p = _controller.page?.round() ?? 0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: PageView.builder(
        controller: _controller,
        itemCount: _pageCount,
        padEnds: false,
        itemBuilder: (context, index) {
          if (index < widget.wallets.length) {
            return _WalletCard(
              wallet: widget.wallets[index],
              isActive: index == _page,
              onWalletChanged: widget.onWalletChanged,
            );
          }
          return _AddWalletCard(onTap: widget.onAddWallet);
        },
      ),
    );
  }
}

// ── Wallet card ───────────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  final bool isActive;
  final VoidCallback onWalletChanged;

  const _WalletCard({
    required this.wallet,
    required this.isActive,
    required this.onWalletChanged,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientForType(wallet.type);
    final usdText = _formatUsd(wallet.balance, wallet.currency);

    return GestureDetector(
      onTap: () async {
        await context.push('/wallet/detail', extra: wallet);
        onWalletChanged();
      },
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(
        left: 16,
        right: 8,
        top: isActive ? 0 : 10,
        bottom: isActive ? 0 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: gradient.first.withAlpha(120),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + wallet name
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
          // Balance
          Text(
            _formatBalance(wallet.balance, wallet.currency),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            usdText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withAlpha(180),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Add wallet card ───────────────────────────────────────────────────────────

class _AddWalletCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddWalletCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 16, top: 10, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.inputBorder,
            width: 1.5,
            style: BorderStyle.solid,
          ),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/icons/wallets/wallet.png', width: 22, height: 22, color: Colors.white,),
            ),
            const SizedBox(height: 6),
            RotatedBox(
              quarterTurns: 1,
              child: Text(
                'Add Wallet',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.placeholderText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add wallet row (shown below all type sections) ────────────────────────────

class _AddWalletRow extends StatelessWidget {
  final VoidCallback onTap;
  const _AddWalletRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add New Wallet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/icons/wallets/money.png', width: 64, height: 64,
              color: AppColors.inputBorder),
          const SizedBox(height: 16),
          Text(
            'No wallets yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.labelText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first wallet to get started',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.placeholderText,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                'Add Wallet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
