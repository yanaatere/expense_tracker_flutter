import 'dart:ui';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/transaction_service.dart';
import '../../core/storage/local_storage.dart';

// ---------------------------------------------------------------------------
// Transaction model (mapped from API)
// ---------------------------------------------------------------------------

class _Transaction {
  final String title;
  final String category;
  final double amount;
  final DateTime date;

  const _Transaction(this.title, this.category, this.amount, this.date);

  factory _Transaction.fromApi(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'expense';
    final raw = map['amount'];
    double amount = raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0;
    if (type == 'expense') amount = -amount.abs();

    final categoryName = map['category_name'] as String? ?? '';
    final dateStr = map['transaction_date'] as String? ?? '';
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }

    return _Transaction(
      map['description'] as String? ?? '',
      categoryName,
      amount,
      date,
    );
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'User';
  bool _isScrolled = false;
  late final ScrollController _scrollController;

  List<_Transaction> _transactions = [];
  bool _loadingTransactions = true;
  String? _transactionError;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 10;
      if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
    });
    _loadUser();
    _loadTransactions();
  }

  Future<void> _loadUser() async {
    final username = await LocalStorage.getUsername();
    if (mounted) setState(() => _username = username ?? 'User');
  }

  Future<void> _loadTransactions() async {
    try {
      final data = await TransactionService.getRecentTransactions(limit: 10);
      if (!mounted) return;
      setState(() {
        _transactions = data.map(_Transaction.fromApi).toList();
        _loadingTransactions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transactionError = 'Failed to load transactions';
        _loadingTransactions = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // topPadding = status bar height (accounts for notch / Dynamic Island on iOS,
    // and the status bar on Android). We add it to expandedHeight so the
    // SliverAppBar is tall enough to place content *below* the notch.
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      extendBody: true,
      bottomNavigationBar: _GlassBottomNav(onAddTransaction: _loadTransactions),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Sticky header ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            // 80 px of visible content + the device's top inset (notch / status bar)
            expandedHeight: topPadding + 80,
            // Match collapsedHeight so pinned bar never clips content
            toolbarHeight: topPadding + 68,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: _Header(
              username: _username,
              isScrolled: _isScrolled,
            ),
          ),

          // ── Total expense card ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _TotalExpenseCard(),
            ),
          ),

          // ── Balance + Income card ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _BalanceIncomeCard(),
            ),
          ),

          // ── Quick actions ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _QuickActions(),
            ),
          ),

          // ── Recent Transactions (header + flat list in one card) ──────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _RecentTransactionSection(
                transactions: _transactions,
                isLoading: _loadingTransactions,
                error: _transactionError,
              ),
            ),
          ),

          // ── Bottom padding so content clears the nav bar ──────────────
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String username;
  final bool isScrolled;

  const _Header({required this.username, required this.isScrolled});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return ClipRect(
      child: BackdropFilter(
        filter: isScrolled
            ? ImageFilter.blur(sigmaX: 12, sigmaY: 12)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          color: isScrolled ? Colors.white.withAlpha(178) : Colors.transparent,
          // topPadding pushes content below the notch / status bar on every device
          padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome, $username',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.labelText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.placeholderText,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.cardBg,
                child: const Icon(Icons.person, color: AppColors.primary, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Total Expense Card
// ---------------------------------------------------------------------------

class _TotalExpenseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthYear = DateFormat('MMMM yyyy').format(now);
    final currency = NumberFormat.currency(symbol: 'Rp. ', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Expense In $monthYear',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.placeholderText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                currency.format(12000000),
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelText,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+27%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.expense,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${currency.format(2123999)} of Last Month',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.placeholderText,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance + Income Card
// ---------------------------------------------------------------------------

class _BalanceIncomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rp. ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _StatColumn(
              icon: Icons.account_balance_wallet,
              label: 'Total Balance',
              amount: currency.format(13000000),
              amountColor: AppColors.labelText,
            )),
            VerticalDivider(
              color: AppColors.primary.withAlpha(51),
              thickness: 1,
              width: 32,
            ),
            Expanded(child: _StatColumn(
              icon: Icons.trending_up,
              label: 'Total Income',
              amount: currency.format(25000000),
              amountColor: AppColors.income,
            )),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color amountColor;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.placeholderText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionButton(icon: Icons.attach_money, label: 'Budgeting', onTap: () {})),
        const SizedBox(width: 8),
        Expanded(child: _ActionButton(icon: Icons.sync, label: 'Recurring', onTap: () {})),
        const SizedBox(width: 8),
        Expanded(child: _ActionButton(icon: Icons.account_balance_wallet, label: 'Wallet', onTap: () => context.push('/wallet'))),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.labelText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Transaction Section
// ---------------------------------------------------------------------------

class _RecentTransactionSection extends StatelessWidget {
  final List<_Transaction> transactions;
  final bool isLoading;
  final String? error;
  const _RecentTransactionSection({
    required this.transactions,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────
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
            Expanded(
              child: Text(
                'Recent Transaction',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelText,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'See More',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.placeholderText,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Flat list inside one white card ────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : error != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Center(
                        child: Text(
                          error!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.placeholderText,
                          ),
                        ),
                      ),
                    )
                  : transactions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Center(
                            child: Text(
                              'No transactions yet',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.placeholderText,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < transactions.length; i++) ...[
                              _TransactionRow(transaction: transactions[i]),
                              if (i < transactions.length - 1)
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
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final _Transaction transaction;
  const _TransactionRow({required this.transaction});

  IconData get _icon {
    switch (transaction.category.toLowerCase()) {
      case 'income':   return Icons.trending_up_rounded;
      case 'travel':   return Icons.flight_rounded;
      case 'charity':  return Icons.favorite_rounded;
      case 'business': return Icons.work_rounded;
      case 'internet': return Icons.language_rounded;
      default:         return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amount > 0;
    final amt = transaction.amount.abs();
    final formatted = NumberFormat('#,##0', 'en_US').format(amt);
    final amountStr = isIncome ? '+Rp. $formatted' : '-Rp. $formatted';
    final dateStr = DateFormat('d MMMM yyyy').format(transaction.date);
    final amountColor = isIncome ? AppColors.income : AppColors.expense;

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
            child: Icon(_icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
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
            amountStr,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Liquid Glass Bottom Navigation (full-width tab bar)
// ---------------------------------------------------------------------------

class _GlassBottomNav extends StatelessWidget {
  final VoidCallback? onAddTransaction;
  const _GlassBottomNav({this.onAddTransaction});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // On iOS 26+: AdaptiveBlurView uses native UIVisualEffectView (bypasses
    // Flutter compositing boundaries → real Liquid Glass blur).
    // On older iOS / Android: falls back to BackdropFilter + gradient overlay.
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AdaptiveBlurView(
        blurStyle: BlurStyle.systemUltraThinMaterial,
        child: Container(
          // Figma: #DEE3FF @ 20% tint on top of the blur
          color: const Color(0xFFDEE3FF).withAlpha(51),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: 69,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Home
                _NavItem(
                  imagePath: 'assets/icons/home.png',
                  label: 'Home',
                  active: true,
                  onTap: () {},
                ),

                // FAB
                GestureDetector(
                  onTap: () async {
                    await context.push('/add-transaction');
                    onAddTransaction?.call();
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(100),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                // Report
                _NavItem(
                  imagePath: 'assets/icons/reports.png',
                  label: 'Report',
                  active: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.imagePath,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primary
        : AppColors.placeholderText.withAlpha(160);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 26,
              height: 26,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
