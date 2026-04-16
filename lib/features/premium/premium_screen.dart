import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/auth_service.dart';
import '../../core/storage/local_storage.dart';
import '../../service_locator.dart';
import '../../shared/widgets/primary_button.dart';
import '../../../core/theme/app_colors_theme.dart';

// ---------------------------------------------------------------------------
// Premium Screen
// ---------------------------------------------------------------------------

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _activating = false;

  Future<void> _activate() async {
    setState(() => _activating = true);
    try {
      // Activate premium on the backend first
      final entry = await ServiceLocator.authCacheDao.get();
      if (entry != null) {
        await AuthService.setPremium(userId: entry.userId, isPremium: true);
      }
      await LocalStorage.setPremium(true);
      await ServiceLocator.authCacheDao.updateIsPremium(true);
      // Bulk-push all locally saved data to the API now that user is premium.
      await ServiceLocator.syncService.bulkPushLocalData();
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Activation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  children: [
                    // ── Hero ─────────────────────────────────────────────────
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF635AFF), Color(0xFF9B8FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Monex Premium',
                      style: GoogleFonts.urbanist(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.labelText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-powered insights, smart tools,\nand full control of your finances.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        color: context.appColors.placeholderText,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── AI section label ─────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF635AFF), Color(0xFF9B8FFF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'AI Features',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FeatureCard(
                      icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFF635AFF),
                      title: 'AI Financial Chat',
                      subtitle: 'Ask anything about your spending in plain language',
                    ),
                    const SizedBox(height: 12),
                    _FeatureCard(
                      icon: Icons.document_scanner_rounded,
                      color: const Color(0xFF8B5CF6),
                      title: 'Smart Receipt Scan',
                      subtitle: 'Auto-fill transactions by scanning any receipt',
                    ),
                    const SizedBox(height: 12),
                    _FeatureCard(
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFFEC4899),
                      title: 'Monthly AI Report',
                      subtitle: 'Get a smart narrative summary of your monthly spend',
                    ),
                    const SizedBox(height: 12),
                    _FeatureCard(
                      icon: Icons.lightbulb_rounded,
                      color: const Color(0xFFF59E0B),
                      title: 'AI Budget Recommendations',
                      subtitle: 'AI suggests realistic limits based on your history',
                    ),

                    const SizedBox(height: 20),

                    // ── Core features label ───────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Core Features',
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.placeholderText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FeatureCard(
                      icon: Icons.sync_rounded,
                      color: const Color(0xFF10B981),
                      title: 'Unlimited Recurring Transactions',
                      subtitle: 'Free plan is limited to 3 scheduled transactions',
                    ),
                    const SizedBox(height: 12),
                    _FeatureCard(
                      icon: Icons.pie_chart_rounded,
                      color: const Color(0xFF3B82F6),
                      title: 'Monthly Budget Tracking',
                      subtitle: 'Set spending limits per category and stay on track',
                    ),
                    const SizedBox(height: 12),
                    _FeatureCard(
                      icon: Icons.file_download_rounded,
                      color: const Color(0xFF06B6D4),
                      title: 'Data Export (CSV)',
                      subtitle: 'Export your full transaction history anytime',
                    ),

                    const SizedBox(height: 36),

                    // ── CTA ──────────────────────────────────────────────────
                    PrimaryButton(
                      label: 'Activate Premium',
                      isLoading: _activating,
                      onPressed: _activate,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(false),
                      child: Text(
                        'Maybe Later',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: context.appColors.placeholderText,
                        ),
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

// ---------------------------------------------------------------------------
// Feature card
// ---------------------------------------------------------------------------

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.labelText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: context.appColors.placeholderText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
    );
  }
}
