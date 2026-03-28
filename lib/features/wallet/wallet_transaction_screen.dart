import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/wallet.dart';
import '../../core/services/wallet_service.dart';
import '../../service_locator.dart';
import '../../shared/widgets/wallet_card.dart';

String _txIconAsset(String type) {
  if (type == 'income') return 'assets/icons/wallets/wallet_transaction/up.webp';
  return 'assets/icons/wallets/wallet_transaction/bottom.webp';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class WalletTransactionScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletTransactionScreen({super.key, required this.wallet});

  @override
  State<WalletTransactionScreen> createState() =>
      _WalletTransactionScreenState();
}

class _WalletTransactionScreenState extends State<WalletTransactionScreen> {
  Wallet? _walletOverride;
  Wallet get _wallet => _walletOverride ?? widget.wallet;
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _reloadWallet() async {
    final wallets = await ServiceLocator.walletRepository.getWallets();
    final updated = wallets.where((w) => w.id == _wallet.id).firstOrNull;
    if (updated != null && mounted) setState(() => _walletOverride = updated);
  }

  Future<void> _load() async {
    final serverId = widget.wallet.serverId != null
        ? int.tryParse(widget.wallet.serverId!)
        : null;
    if (serverId == null) {
      setState(() {
        _loading = false;
        _error = 'Wallet not synced yet';
      });
      return;
    }
    try {
      final data = await WalletService.getWalletTransactions(serverId);
      if (mounted) setState(() { _all = data; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load transactions';
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _all.where((t) {
      final desc = (t['description'] as String? ?? '').toLowerCase();
      return _searchQuery.isEmpty || desc.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _wallet;

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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Wallet card ──────────────────────────────────────────
                    WalletCardWidget(wallet: _wallet, height: 192, width: null),

                    const SizedBox(height: 20),

                    // ── Filter tabs ──────────────────────────────────────────
                    Row(
                      children: [
                        _FilterTab(
                          icon: 'assets/icons/wallets/wallet_transaction/credit_card.webp',
                          label: 'Card Detail',
                          selected: false,
                          onTap: () async {
                            await context.push('/wallet/detail', extra: wallet);
                            await _reloadWallet();
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterTab(
                          icon: 'assets/icons/wallets/wallet_transaction/bottom.webp',
                          label: 'Income',
                          selected: false,
                          onTap: () => context.push('/wallet/income', extra: wallet),
                        ),
                        const SizedBox(width: 8),
                        _FilterTab(
                          icon: 'assets/icons/wallets/wallet_transaction/up.webp',
                          label: 'Expense',
                          selected: false,
                          onTap: () => context.push('/wallet/expense', extra: wallet),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Section header ───────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${wallet.name} Recent Transaction',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.labelText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Search ───────────────────────────────────────────────
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.urbanist(
                          fontSize: 14, color: AppColors.labelText),
                      decoration: InputDecoration(
                        hintText: 'Search Transaction',
                        hintStyle: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: AppColors.placeholderText,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.placeholderText,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
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
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Transaction list ─────────────────────────────────────
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            _error!,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: AppColors.placeholderText,
                            ),
                          ),
                        ),
                      )
                    else if (_filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No transactions found',
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: AppColors.placeholderText,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < _filtered.length; i++) ...[
                              _TxRow(data: _filtered[i]),
                              if (i < _filtered.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  indent: 64,
                                  endIndent: 16,
                                  color: AppColors.inputBorder.withAlpha(180),
                                ),
                            ],
                          ],
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
}

// ── Filter tab pill ───────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(icon, width: 16, height: 16,
                  color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 12,
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

// ── Transaction row ───────────────────────────────────────────────────────────

class _TxRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TxRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] as String? ?? 'expense').toLowerCase();
    final isIncome = type == 'income';
    final rawAmount = data['amount'];
    final double amount =
        rawAmount is num ? rawAmount.toDouble() : double.tryParse(rawAmount.toString()) ?? 0;
    final description = data['description'] as String? ?? '—';
    final dateStr = data['transaction_date'] as String? ?? '';
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }
    final formatted = NumberFormat('#,##0.##').format(amount);
    final amountStr = isIncome ? '+\$$formatted' : '-\$$formatted';
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final dateLabel = DateFormat('d MMMM yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              _txIconAsset(type),
              color: isIncome ? AppColors.income : AppColors.placeholderText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: AppColors.placeholderText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountStr,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
