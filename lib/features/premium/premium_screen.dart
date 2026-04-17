import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/auth_service.dart';
import '../../core/storage/local_storage.dart';
import '../../service_locator.dart';
import '../../shared/widgets/primary_button.dart';
import '../../../core/theme/app_colors_theme.dart';

enum _Plan { monthly, annual, lifetime }

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  _Plan _selected = _Plan.monthly;
  bool _subscribing = false;

  Future<void> _subscribe() async {
    // Local-mode users must create an account before going premium.
    if (await LocalStorage.isLocalMode()) {
      if (mounted) _showAccountRequiredSheet();
      return;
    }

    setState(() => _subscribing = true);
    try {
      final entry = await ServiceLocator.authCacheDao.get();
      if (entry != null) {
        await AuthService.setPremium(userId: entry.userId, isPremium: true);
      }
      await LocalStorage.setPremium(true);
      await ServiceLocator.authCacheDao.updateIsPremium(true);
      await ServiceLocator.syncService.bulkPushLocalData();
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  void _showAccountRequiredSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Icon(Icons.lock_outline_rounded,
                size: 40, color: Color(0xFF635AFF)),
            const SizedBox(height: 12),
            Text(
              'Account required',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.appColors.labelText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a free account to subscribe to premium. Your local data will be preserved and synced.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.appColors.placeholderText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Create Account',
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/create-account');
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Not now',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.appColors.placeholderText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
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
                    color: context.appColors.labelText,
                    onPressed: () => context.pop(false),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        'Premium',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.labelText,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Scrollable content ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  children: [
                    Text(
                      'Choose Your Plan',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.labelText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take full control of your wealth with advanced financial tools',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.appColors.placeholderText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Plan cards ───────────────────────────────────────────
                    _PlanCard(
                      selected: _selected == _Plan.monthly,
                      onTap: () => setState(() => _selected = _Plan.monthly),
                      title: 'Premium Monthly Plan',
                      price: 'Rp. 9,900',
                      period: '/ Month',
                      badges: const [_Badge(label: '7 Days Free')],
                      billingNote: 'Billed Monthly',
                    ),
                    const SizedBox(height: 16),
                    _PlanCard(
                      selected: _selected == _Plan.annual,
                      onTap: () => setState(() => _selected = _Plan.annual),
                      title: 'Premium Anually Plan',
                      price: 'Rp. 99,000',
                      period: '/ Year',
                      badges: const [
                        _Badge(label: '7 Days Free'),
                        _Badge(label: 'Save 16%'),
                      ],
                      billingNote: 'Billed every Year',
                    ),
                    const SizedBox(height: 16),
                    _PlanCard(
                      selected: _selected == _Plan.lifetime,
                      onTap: () => setState(() => _selected = _Plan.lifetime),
                      title: 'Lifetime access',
                      price: 'Rp. 199,000',
                      period: '',
                      badges: const [_Badge(label: 'One Time Payment')],
                      billingNote: '',
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Subscribe button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: PrimaryButton(
                label: 'Subscribe',
                isLoading: _subscribing,
                onPressed: _subscribe,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String price;
  final String period;
  final List<_Badge> badges;
  final String billingNote;

  const _PlanCard({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.price,
    required this.period,
    required this.badges,
    required this.billingNote,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF635AFF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                if (period.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      period,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...badges,
                if (billingNote.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    billingNote,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge pill
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF635AFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
