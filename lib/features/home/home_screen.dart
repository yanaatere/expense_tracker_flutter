import 'dart:ui';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_colors_theme.dart';
import '../../core/constants/category_definitions.dart';
import '../../core/models/transaction.dart';
import '../../core/storage/local_storage.dart';
import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with WidgetsBindingObserver {
  bool _isScrolled = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 10;
      if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeCubit>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final cubit = context.read<HomeCubit>();
        return Scaffold(
          backgroundColor: context.appColors.pageBg,
          extendBody: true,
          bottomNavigationBar: _GlassBottomNav(onAddTransaction: cubit.refresh),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Sticky header ────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  expandedHeight: topPadding + 80,
                  toolbarHeight: topPadding + 68,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: _Header(
                    username: state.username,
                    isScrolled: _isScrolled,
                  ),
                ),

                // ── Total expense card ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _TotalExpenseCard(
                      summary: state.summary,
                      isLoading: state.loadingSummary,
                    ),
                  ),
                ),

                // ── Balance + Income card ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _BalanceIncomeCard(
                      summary: state.summary,
                      isLoading: state.loadingSummary,
                    ),
                  ),
                ),

                // ── Quick actions ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _QuickActions(onWalletReturn: cubit.refresh),
                  ),
                ),

                // ── AI Report card (premium only) ─────────────────────────
                const SliverToBoxAdapter(child: _AiReportCard()),

                // ── Recent Transactions ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _RecentTransactionSection(
                      transactions: state.transactions,
                      isLoading: state.loadingTransactions,
                      error: state.transactionError,
                      onTransactionChanged: cubit.refresh,
                    ),
                  ),
                ),

                // ── Bottom padding ───────────────────────────────────────
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
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
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.labelText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.appColors.placeholderText,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/account'),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: context.appColors.cardBg,
                  child: Icon(Icons.person, color: AppColors.primary, size: 24),
                ),
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
  final Map<String, dynamic>? summary;
  final bool isLoading;

  const _TotalExpenseCard({this.summary, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rp. ', decimalDigits: 0);
    final monthLabel = summary?['current_month_label'] as String? ?? DateFormat('MMMM yyyy').format(DateTime.now());
    final totalExpense = (summary?['total_expense'] as num?)?.toDouble() ?? 0;
    final prevExpense = (summary?['prev_month_expense'] as num?)?.toDouble() ?? 0;
    final pctChange = (summary?['expense_percent_change'] as num?)?.toDouble() ?? 0;
    final pctLabel = '${pctChange >= 0 ? '+' : ''}${pctChange.toStringAsFixed(0)}%';
    final pctPositive = pctChange >= 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
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
      child: isLoading
          ? SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Expense In $monthLabel',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.placeholderText,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      currency.format(totalExpense),
                      style: GoogleFonts.urbanist(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.labelText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pctPositive ? const Color(0xFFFFE4E6) : const Color(0xFFE4FFE8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pctLabel,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: pctPositive ? AppColors.expense : AppColors.income,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${currency.format(prevExpense)} of Last Month',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: context.appColors.placeholderText,
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
  final Map<String, dynamic>? summary;
  final bool isLoading;

  const _BalanceIncomeCard({this.summary, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rp. ', decimalDigits: 0);
    final totalBalance = (summary?['total_balance'] as num?)?.toDouble() ?? 0;
    final totalIncome = (summary?['total_income'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: isLoading
          ? SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
            )
          : IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _StatColumn(
                    icon: Icons.account_balance_wallet,
                    label: 'Total Balance',
                    amount: currency.format(totalBalance),
                    amountColor: context.appColors.labelText,
                  )),
                  VerticalDivider(
                    color: AppColors.primary.withAlpha(51),
                    thickness: 1,
                    width: 32,
                  ),
                  Expanded(child: _StatColumn(
                    icon: Icons.trending_up,
                    label: 'Total Income',
                    amount: currency.format(totalIncome),
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
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.placeholderText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: GoogleFonts.urbanist(
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

// ---------------------------------------------------------------------------
// AI Report Card
// ---------------------------------------------------------------------------

class _AiReportCard extends StatefulWidget {
  const _AiReportCard();

  @override
  State<_AiReportCard> createState() => _AiReportCardState();
}

class _AiReportCardState extends State<_AiReportCard> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    LocalStorage.isPremium().then((v) {
      if (mounted) setState(() => _isPremium = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPremium) return const SizedBox.shrink();

    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthLabel = months[now.month - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/ai/report'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF635AFF), Color(0xFF9B8FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthLabel AI Report',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'See your spending insights',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  final VoidCallback onWalletReturn;
  const _QuickActions({required this.onWalletReturn});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionButton(icon: Icons.attach_money, label: 'Budgeting', onTap: () {})),
        const SizedBox(width: 8),
        Expanded(child: _ActionButton(icon: Icons.sync, label: 'Recurring', onTap: () => context.push('/recurring'))),
        const SizedBox(width: 8),
        Expanded(child: _ActionButton(
          icon: Icons.account_balance_wallet,
          label: 'Wallet',
          onTap: () async {
            await context.push('/wallet');
            onWalletReturn();
          },
        )),
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
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: context.appColors.inputBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.appColors.labelText,
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
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final VoidCallback? onTransactionChanged;
  const _RecentTransactionSection({
    required this.transactions,
    this.isLoading = false,
    this.error,
    this.onTransactionChanged,
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
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.appColors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recent Transaction',
                style: GoogleFonts.urbanist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.labelText,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/transactions/recent'),
              child: Text(
                'See More',
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: context.appColors.placeholderText,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 14),

        // ── Flat list inside one white card ────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isLoading
              ? Padding(
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
                      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Center(
                        child: Text(
                          error!,
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            color: context.appColors.placeholderText,
                          ),
                        ),
                      ),
                    )
                  : transactions.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Center(
                            child: Text(
                              'No transactions yet',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: context.appColors.placeholderText,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < transactions.length; i++) ...[
                              _TransactionRow(transaction: transactions[i], onDeleted: onTransactionChanged),
                              if (i < transactions.length - 1)
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  indent: 64,
                                  endIndent: 16,
                                  color: context.appColors.inputBorder.withAlpha(180),
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
  final Transaction transaction;
  final VoidCallback? onDeleted;
  const _TransactionRow({required this.transaction, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amount > 0;
    final amt = transaction.amount.abs();
    final formatted = NumberFormat('#,##0', 'en_US').format(amt);
    final amountStr = isIncome ? '+Rp. $formatted' : '-Rp. $formatted';
    final dateStr = DateFormat('d MMMM yyyy').format(transaction.date);
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final iconPath = categoryIconPath(transaction.category, type: transaction.type);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final deleted = await context.push<bool>(
          '/transactions/detail',
          extra: transaction.rawData,
        );
        if (deleted == true) onDeleted?.call();
      },
      child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: iconPath != null
                ? Image.asset(
                    iconPath,
                    color: categoryColor(transaction.category, type: transaction.type),
                    colorBlendMode: BlendMode.srcIn,
                  )
                : Icon(
                    isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 18,
                    color: amountColor,
                  ),
          ),
          SizedBox(width: 12),
          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.labelText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: context.appColors.placeholderText,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            amountStr,
            style: GoogleFonts.urbanist(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
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
        : context.appColors.placeholderText.withAlpha(160);

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
              style: GoogleFonts.urbanist(
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
