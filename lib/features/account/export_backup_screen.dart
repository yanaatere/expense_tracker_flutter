import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/backup_service.dart';
import '../../../core/theme/app_colors_theme.dart';
import '../../../service_locator.dart';

class ExportBackupScreen extends StatefulWidget {
  const ExportBackupScreen({super.key});

  @override
  State<ExportBackupScreen> createState() => _ExportBackupScreenState();
}

class _ExportBackupScreenState extends State<ExportBackupScreen> {
  bool _exportingJson = false;
  bool _exportingCsv = false;

  Future<void> _exportJson() async {
    setState(() => _exportingJson = true);
    try {
      final entry = await ServiceLocator.authCacheDao.get();
      final userId = entry?.userId ?? '';
      final path = await BackupService.exportToJson(
        userId: userId,
        expenseDao: ServiceLocator.expenseDao,
        walletDao: ServiceLocator.walletDao,
        recurringDao: ServiceLocator.recurringTransactionDao,
      );
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)], text: 'Monex Backup (JSON)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportingJson = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _exportingCsv = true);
    try {
      final entry = await ServiceLocator.authCacheDao.get();
      final userId = entry?.userId ?? '';
      final path = await BackupService.exportToCsv(
        userId: userId,
        expenseDao: ServiceLocator.expenseDao,
      );
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)], text: 'Monex Export (CSV)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
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
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Export Backup Data',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.labelText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  children: [
                    _ExportOption(
                      icon: Icons.download_rounded,
                      title: 'Export to JSON',
                      subtitle: 'Export all transactions and settings to a JSON file',
                      recommended: true,
                      loading: _exportingJson,
                      onTap: _exportingJson || _exportingCsv ? null : _exportJson,
                    ),
                    const SizedBox(height: 16),
                    _ExportOption(
                      icon: Icons.download_rounded,
                      title: 'Export to CSV',
                      subtitle: 'Export only the transaction to CSV File',
                      recommended: false,
                      loading: _exportingCsv,
                      onTap: _exportingJson || _exportingCsv ? null : _exportCsv,
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

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool recommended;
  final bool loading;
  final VoidCallback? onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.recommended,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.appColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF635AFF),
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.labelText,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF635AFF).withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF635AFF).withAlpha(60)),
                          ),
                          child: Text(
                            'Recommended',
                            style: GoogleFonts.urbanist(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF635AFF),
                            ),
                          ),
                        ),
                      ],
                    ],
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
          ],
        ),
      ),
    );
  }
}
