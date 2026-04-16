import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_colors.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors_theme.dart';
import '../../service_locator.dart';
import '../../shared/widgets/primary_button.dart';

class StorageMaintenanceScreen extends StatefulWidget {
  const StorageMaintenanceScreen({super.key});

  @override
  State<StorageMaintenanceScreen> createState() =>
      _StorageMaintenanceScreenState();
}

class _StorageMaintenanceScreenState extends State<StorageMaintenanceScreen> {
  bool _isPremium = false;
  bool _loading = true;
  bool _cleaning = false;

  int _retentionMonths = 3;
  int _expenseCount = 0;
  double _dbSizeMb = 0;

  static const _retentionOptions = [1, 3, 6, 12, 0]; // 0 = keep all
  static const _retentionLabels = ['1 month', '3 months', '6 months', '1 year', 'Keep all'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final isPremium = await LocalStorage.isPremium();
    final retention = await LocalStorage.getRetentionMonths();

    int count = 0;
    double sizeMb = 0;
    if (isPremium) {
      try {
        final entry = await ServiceLocator.authCacheDao.get();
        if (entry != null) {
          count = await ServiceLocator.expenseDao.countAll(entry.userId);
        }
        final dbPath = p.join(await getDatabasesPath(), 'monex.db');
        final stat = await File(dbPath).stat();
        sizeMb = stat.size / (1024 * 1024);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _retentionMonths = retention;
        _expenseCount = count;
        _dbSizeMb = sizeMb;
        _loading = false;
      });
    }
  }

  Future<void> _cleanUp() async {
    if (_retentionMonths == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retention is set to "Keep all" — nothing to clean.',
              style: GoogleFonts.urbanist()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _cleaning = true);
    try {
      final entry = await ServiceLocator.authCacheDao.get();
      if (entry == null) return;
      final result = await ServiceLocator.syncService
          .maintenanceLocalData(entry.userId, _retentionMonths);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.total > 0
                  ? 'Cleaned up ${result.total} records. Storage freed!'
                  : 'Nothing to clean up — your data is already lean.',
              style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reload stats
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleanup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cleaning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
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
                      'Storage Maintenance',
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

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (!_isPremium)
              _buildPremiumGate(context)
            else
              _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumGate(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF635AFF), Color(0xFF9B8FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Premium Feature',
              style: GoogleFonts.urbanist(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.appColors.labelText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Storage maintenance is available for premium users. Upgrade to keep your local database lean.',
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: context.appColors.placeholderText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Upgrade to Premium',
              onPressed: () => context.push('/premium'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _StatTile(
                    label: 'DB Size',
                    value: '${_dbSizeMb.toStringAsFixed(1)} MB',
                    icon: Icons.storage_rounded,
                    color: AppColors.primary,
                  ),
                  Container(width: 1, height: 40, color: context.appColors.inputBorder),
                  _StatTile(
                    label: 'Transactions',
                    value: '$_expenseCount records',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Retention picker ─────────────────────────────────────────
            Text(
              'Data Retention',
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.appColors.labelText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keep synced transactions locally for this duration.',
              style: GoogleFonts.urbanist(
                fontSize: 12,
                color: context.appColors.placeholderText,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: context.appColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: List.generate(_retentionOptions.length, (i) {
                  final val = _retentionOptions[i];
                  final label = _retentionLabels[i];
                  final selected = _retentionMonths == val;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      setState(() => _retentionMonths = val);
                      await LocalStorage.setRetentionMonths(val);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.primary
                                    : context.appColors.labelText,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20)
                          else
                            Icon(Icons.radio_button_unchecked_rounded,
                                color: context.appColors.inputBorder, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // ── Info note ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withAlpha(60)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Only synced data is removed. Your unsynced and recent data is always kept safe. You can re-fetch older records from the server at any time.',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Clean up button ──────────────────────────────────────────
            PrimaryButton(
              label: 'Clean Up Now',
              isLoading: _cleaning,
              onPressed: _cleaning ? null : _cleanUp,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat tile
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.appColors.labelText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 11,
              color: context.appColors.placeholderText,
            ),
          ),
        ],
      ),
    );
  }
}
