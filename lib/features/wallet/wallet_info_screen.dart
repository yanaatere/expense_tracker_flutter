import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/wallet.dart';
import '../../core/services/wallet_service.dart';

// ── Shared helpers (mirrored from wallet_screen.dart) ─────────────────────────

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

// ── Filter ────────────────────────────────────────────────────────────────────

enum _Filter { all, income, expense }

// ── Screen ────────────────────────────────────────────────────────────────────

class WalletInfoScreen extends StatefulWidget {
  final Wallet wallet;
  const WalletInfoScreen({super.key, required this.wallet});

  @override
  State<WalletInfoScreen> createState() => _WalletInfoScreenState();
}

class _WalletInfoScreenState extends State<WalletInfoScreen> {
  _Filter _filter = _Filter.all;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  int? get _serverWalletId {
    final sid = widget.wallet.serverId;
    if (sid == null) return null;
    return int.tryParse(sid);
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final walletId = _serverWalletId;
    if (walletId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final typeParam = _filter == _Filter.income
        ? 'income'
        : _filter == _Filter.expense
            ? 'expense'
            : null;
    try {
      final txns = await WalletService.getWalletTransactions(walletId, type: typeParam);
      if (mounted) setState(() { _transactions = txns; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setFilter(_Filter f) {
    if (_filter == f) return;
    setState(() { _filter = f; _loading = true; _transactions = []; });
    _loadTransactions();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Wallet', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${widget.wallet.name}"? This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.placeholderText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.expense, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final walletId = _serverWalletId;
    if (walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet not synced yet. Cannot delete.')),
      );
      return;
    }
    try {
      await WalletService.deleteWallet(walletId);
      if (mounted) context.pop();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(WalletService.errorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;
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

            // ── Wallet card ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 160,
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
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
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
            ),

            const SizedBox(height: 16),

            // ── Filter tabs ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterTab(
                    label: 'All',
                    icon: Icons.credit_card_rounded,
                    selected: _filter == _Filter.all,
                    onTap: () => _setFilter(_Filter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Income',
                    icon: Icons.arrow_downward_rounded,
                    selected: _filter == _Filter.income,
                    onTap: () => _setFilter(_Filter.income),
                    selectedColor: AppColors.income,
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Expense',
                    icon: Icons.arrow_upward_rounded,
                    selected: _filter == _Filter.expense,
                    onTap: () => _setFilter(_Filter.expense),
                    selectedColor: AppColors.expense,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Section header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${wallet.name} Recent Transaction',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.labelText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Transaction list ─────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _serverWalletId == null
                      ? Center(
                          child: Text(
                            'Wallet not synced yet.',
                            style: GoogleFonts.inter(color: AppColors.placeholderText),
                          ),
                        )
                      : _transactions.isEmpty
                          ? Center(
                              child: Text(
                                'No transactions found.',
                                style: GoogleFonts.inter(color: AppColors.placeholderText),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _transactions.length,
                              itemBuilder: (_, i) => _TransactionItem(data: _transactions[i]),
                            ),
            ),

            // ── Bottom actions ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  // Delete button
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.expense,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Edit wallet button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push(
                        '/onboarding/wallet',
                        extra: <String, String>{
                          'returnRoute': '/wallet',
                          'initialType': wallet.type,
                        },
                      ),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A017),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
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

// ── Filter tab ────────────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _FilterTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(40),
          border: selected
              ? Border.all(color: activeColor.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? activeColor : AppColors.placeholderText),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? activeColor : AppColors.placeholderText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction list item ─────────────────────────────────────────────────────

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TransactionItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? 'expense';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final description = data['description'] as String? ?? '';
    final categoryName = data['category_name'] as String? ?? '';
    final dateStr = data['transaction_date'] as String? ?? '';
    final isIncome = type == 'income';

    final amountText = isIncome
        ? '+\$${NumberFormat('#,##0.##').format(amount)}'
        : '-\$${NumberFormat('#,##0.##').format(amount)}';
    final amountColor = isIncome ? AppColors.income : AppColors.expense;

    String formattedDate = dateStr;
    try {
      final d = DateTime.parse(dateStr);
      formattedDate = DateFormat('d MMMM yyyy').format(d);
    } catch (_) {}

    final title = description.isNotEmpty ? description : categoryName;
    final subtitle = description.isNotEmpty && categoryName.isNotEmpty ? categoryName : formattedDate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Category icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 18,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 12),
          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : 'Transaction',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.isNotEmpty ? subtitle : formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.placeholderText,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            amountText,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
