import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/storage/local_storage.dart';

// ---------------------------------------------------------------------------
// Account Info Screen
// ---------------------------------------------------------------------------

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final username = await LocalStorage.getUsername();
    if (mounted) setState(() => _username = username ?? 'User');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────────
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
                      'Account',
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

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar + name ──────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 44,
                                  color: AppColors.primary,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '👋 $_username',
                            style: GoogleFonts.urbanist(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.labelText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Profile ────────────────────────────────────────────
                    _SectionLabel(label: 'Profile'),
                    const SizedBox(height: 8),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/EditProfile.webp',
                          label: 'Edit Profile',
                          onTap: () async {
                            final saved = await context.push<bool>('/account/edit-profile');
                            if (saved == true) _loadUser();
                          },
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/Pin.webp',
                          label: 'PIN',
                          onTap: () => context.push('/account/pin'),
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/Language.webp',
                          label: 'Language Setting',
                          onTap: () => context.push('/onboarding/language'),
                          showDivider: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Data ───────────────────────────────────────────────
                    _SectionLabel(label: 'Data'),
                    const SizedBox(height: 8),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/BackupData.webp',
                          label: 'Backup data',
                          onTap: () {},
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/DataExport.webp',
                          label: 'Data Export',
                          onTap: () {},
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/Categories.webp',
                          label: 'Categories',
                          onTap: () {},
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/Currency.webp',
                          label: 'Currency',
                          onTap: () {},
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/Wallet.webp',
                          label: 'Wallet',
                          onTap: () => context.push('/wallet'),
                          showDivider: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Appearance ─────────────────────────────────────────
                    _SectionLabel(label: 'Appearance'),
                    const SizedBox(height: 8),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/CardTheme.webp',
                          label: 'Card Theme',
                          onTap: () {},
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/LightDarkMode.webp',
                          label: 'Light / Dark Mode',
                          onTap: () {},
                          showDivider: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── General ────────────────────────────────────────────
                    _SectionLabel(label: 'General'),
                    const SizedBox(height: 8),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          label: 'Help and Support',
                          onTap: () {},
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/SendFeedback.webp',
                          label: 'Send Feedback',
                          onTap: () {},
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/About.webp',
                          label: 'About',
                          onTap: () {},
                          showDivider: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Account ────────────────────────────────────────────
                    _SectionLabel(label: 'Account'),
                    const SizedBox(height: 8),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/DeleteData.webp',
                          label: 'Delete Data',
                          onTap: () => _confirmDeleteData(context),
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/Logout.webp',
                          label: 'Logout',
                          onTap: () => _confirmLogout(context),
                          showDivider: false,
                        ),
                      ],
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

  Future<void> _confirmLogout(BuildContext context) async {
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.urbanist(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.urbanist(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.urbanist(color: AppColors.placeholderText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: GoogleFonts.urbanist(color: AppColors.expense, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // If PIN is enabled, just lock the screen — token stays so PIN can unlock.
    // "Use password instead" on the PIN screen does the full clearAll().
    if (await LocalStorage.isPinEnabled()) {
      router.go('/pin-login');
    } else {
      await LocalStorage.clearAll();
      router.go('/signin');
    }
  }

  Future<void> _confirmDeleteData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Data', style: GoogleFonts.urbanist(fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete all your local data. This cannot be undone.',
          style: GoogleFonts.urbanist(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.urbanist(color: AppColors.placeholderText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.urbanist(color: AppColors.expense, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // TODO: wire up full data deletion when data layer supports it
    messenger.showSnackBar(
      const SnackBar(content: Text('Data deletion not yet implemented.')),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.urbanist(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.labelText,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu group card
// ---------------------------------------------------------------------------

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  final bool highlighted;

  const _MenuGroup({required this.items, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Column(children: items),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu item row
// ---------------------------------------------------------------------------

class _MenuItem extends StatelessWidget {
  final String? iconAsset;
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    this.iconAsset,
    this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  }) : assert(iconAsset != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon
                SizedBox(
                  width: 32,
                  height: 32,
                  child: iconAsset != null
                      ? Image.asset(iconAsset!, fit: BoxFit.contain)
                      : Icon(icon, size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.labelText,
                    ),
                  ),
                ),
                // Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.placeholderText,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 62,
            endIndent: 16,
            color: AppColors.inputBorder.withAlpha(180),
          ),
      ],
    );
  }
}
