import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/backup_service.dart';
import '../../../core/theme/app_colors_theme.dart';
import '../../../service_locator.dart';

class RestoreDataScreen extends StatefulWidget {
  const RestoreDataScreen({super.key});

  @override
  State<RestoreDataScreen> createState() => _RestoreDataScreenState();
}

class _RestoreDataScreenState extends State<RestoreDataScreen> {
  bool _restoringJson = false;
  bool _restoringCsv = false;

  Future<void> _restoreJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _restoringJson = true);
    try {
      final entry = await ServiceLocator.authCacheDao.get();
      final userId = entry?.userId ?? '';
      await BackupService.restoreFromJson(
        filePath: result.files.single.path!,
        userId: userId,
        expenseDao: ServiceLocator.expenseDao,
        walletDao: ServiceLocator.walletDao,
        recurringDao: ServiceLocator.recurringTransactionDao,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data restored successfully')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _restoringJson = false);
    }
  }

  Future<void> _restoreCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _restoringCsv = true);
    try {
      final entry = await ServiceLocator.authCacheDao.get();
      final userId = entry?.userId ?? '';
      await BackupService.restoreFromCsv(
        filePath: result.files.single.path!,
        userId: userId,
        expenseDao: ServiceLocator.expenseDao,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transactions restored successfully')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _restoringCsv = false);
    }
  }

  Future<bool> _showConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Overwrite existing data?',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently overwrite your current data. This action cannot be undone.',
          style: GoogleFonts.urbanist(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.urbanist()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Restore',
              style: GoogleFonts.urbanist(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
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
                      'Restore Data',
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
                    // ── Warning banner ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFF59E0B), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  color: const Color(0xFF92400E),
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Warning: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: 'Restoring data will ',
                                  ),
                                  TextSpan(
                                    text: 'overwrite',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text:
                                        ' all existing data. This action ',
                                  ),
                                  TextSpan(
                                    text: 'cannot be undone',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _RestoreOption(
                      icon: Icons.upload_file_rounded,
                      title: 'Upload JSON Backup',
                      subtitle:
                          'Restore all transactions, wallets, and settings',
                      recommended: true,
                      loading: _restoringJson,
                      onTap: _restoringJson || _restoringCsv
                          ? null
                          : _restoreJson,
                    ),
                    const SizedBox(height: 16),
                    _RestoreOption(
                      icon: Icons.upload_file_rounded,
                      title: 'Upload CSV File',
                      subtitle: 'Restore only transactions from CSV',
                      recommended: false,
                      loading: _restoringCsv,
                      onTap: _restoringJson || _restoringCsv
                          ? null
                          : _restoreCsv,
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

class _RestoreOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool recommended;
  final bool loading;
  final VoidCallback? onTap;

  const _RestoreOption({
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
                color: Color(0xFFF59E0B),
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
                                color:
                                    const Color(0xFF635AFF).withAlpha(60)),
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
