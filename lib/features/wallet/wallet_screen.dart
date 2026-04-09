import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/wallet.dart';
import '../../core/utils/currency_formatter.dart';
import '../../service_locator.dart';
import '../../shared/widgets/wallet_card.dart';
import '../../../core/theme/app_colors_theme.dart';


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
    final order = ['Cash', 'Bank', 'Credit', 'E-Wallet'];
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
      case 'Credit': return 'Credit';
      case 'E-Wallet': return 'E-Wallet';
      case 'Cash': return 'Cash';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    color: context.appColors.labelText,
                    onPressed: () => context.go('/home'),
                  ),
                  Expanded(
                    child: Text(
                      'Wallet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.labelText,
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
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.placeholderText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _allSameCurrency
                        ? formatCurrency(_totalBalance, _totalCurrency)
                        : formatCurrency(_totalBalance, 'IDR'),
                    style: GoogleFonts.urbanist(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: context.appColors.labelText,
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
        style: GoogleFonts.urbanist(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: context.appColors.labelText,
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

  int get _pageCount => widget.wallets.length;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
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
      height: 192,
      child: PageView.builder(
        controller: _controller,
        itemCount: _pageCount,
        padEnds: true,
        itemBuilder: (context, index) {
          return _WalletCard(
            wallet: widget.wallets[index],
            isActive: index == _page,
            onWalletChanged: widget.onWalletChanged,
          );
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
    return GestureDetector(
      onTap: () async {
        await context.push('/wallet/transactions', extra: wallet);
        onWalletChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isActive ? 0 : 10,
        ),
        child: WalletCardWidget(
          wallet: wallet,
          elevated: false,
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
            color: context.appColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add New Wallet',
                style: GoogleFonts.urbanist(
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
              color: context.appColors.inputBorder),
          const SizedBox(height: 16),
          Text(
            'No wallets yet',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.appColors.labelText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first wallet to get started',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: context.appColors.placeholderText,
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
                style: GoogleFonts.urbanist(
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
