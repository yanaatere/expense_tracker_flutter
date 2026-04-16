import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_colors_theme.dart';
import '../../service_locator.dart';

const _kCardBackdrops = [
  'assets/images/backdrop_wallets/Card 1.webp',
  'assets/images/backdrop_wallets/Card 2.webp',
  'assets/images/backdrop_wallets/Card 3.webp',
  'assets/images/backdrop_wallets/Card 4.webp',
  'assets/images/backdrop_wallets/Card 5.webp',
  'assets/images/backdrop_wallets/Card 6.webp',
  'assets/images/backdrop_wallets/Card 7.webp',
  'assets/images/backdrop_wallets/Card 8.webp',
  'assets/images/backdrop_wallets/Card 9.webp',
  'assets/images/backdrop_wallets/Card 10.webp',
];

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
  String? _avatarPath;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final username = await LocalStorage.getUsername();
    final avatarPath = await LocalStorage.getAvatarPath();
    final isPremium = await LocalStorage.isPremium();
    if (mounted) {
      setState(() {
        _username = username ?? 'User';
        _avatarPath = avatarPath;
        _isPremium = isPremium;
      });
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    // Copy to app documents so it survives cache clears
    final docsDir = await getApplicationDocumentsDirectory();
    final dest = p.join(docsDir.path, 'avatar.jpg');
    await File(picked.path).copy(dest);
    await LocalStorage.saveAvatarPath(dest);
    if (mounted) setState(() => _avatarPath = dest);
  }

  void _showAvatarOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text('Take Photo', style: GoogleFonts.urbanist(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text('Choose from Gallery', style: GoogleFonts.urbanist(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                title: Text('Remove Photo', style: GoogleFonts.urbanist(color: AppColors.expense, fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  await LocalStorage.clearAvatarPath();
                  if (mounted) setState(() => _avatarPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, size: 28),
                    color: context.appColors.labelText,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Account',
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

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar + name ──────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showAvatarOptions,
                            child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: context.appColors.cardBg,
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _avatarPath != null
                                    ? Image.file(
                                        File(_avatarPath!),
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                      )
                                    : const Icon(
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
                          ),
                          SizedBox(height: 12),
                          Text(
                            '👋 $_username',
                            style: GoogleFonts.urbanist(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: context.appColors.labelText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Premium banner ─────────────────────────────────────
                    if (!_isPremium)
                      GestureDetector(
                        onTap: () async {
                          final upgraded = await context.push<bool>('/premium');
                          if (upgraded == true) _loadUser();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
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
                              const Icon(Icons.workspace_premium_rounded,
                                  color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Go Premium',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Unlock budgets, exports & more',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Colors.white70),
                            ],
                          ),
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
                          onTap: () => context.push('/backup'),
                        ),
                        _MenuItem(
                          icon: Icons.cleaning_services_rounded,
                          label: 'Storage Maintenance',
                          onTap: () => context.push('/account/storage'),
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/Categories.webp',
                          label: 'Categories',
                          onTap: () => context.push('/account/categories'),
                        ),
                        _MenuItem(
                          iconAsset: 'assets/icons/accountinfo/Categories.webp',
                          label: 'Budget',
                          onTap: _isPremium
                              ? () => context.push('/budget')
                              : () => context.push('/premium'),
                          trailing: _isPremium ? null : const _PremiumBadge(),
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
                          onTap: () => _showCardThemePicker(context),
                        ),
                        _ThemeModeItem(),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── General ────────────────────────────────────────────
                    _SectionLabel(label: 'General'),
                    const SizedBox(height: 8),
                    _MenuGroup(
                      items: [
                        _MenuItem(
                          icon: Icons.auto_awesome_rounded,
                          label: 'AI Assistant',
                          onTap: _isPremium
                              ? () => context.push('/ai/chat')
                              : () => context.push('/premium'),
                          trailing: _isPremium ? null : const _PremiumBadge(),
                        ),
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

  void _showCardThemePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CardThemeSheet(),
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
            child: Text('Cancel', style: GoogleFonts.urbanist(color: context.appColors.placeholderText)),
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
            child: Text('Cancel', style: GoogleFonts.urbanist(color: context.appColors.placeholderText)),
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
        color: context.appColors.labelText,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu group card
// ---------------------------------------------------------------------------

class _MenuGroup extends StatelessWidget {
  final List<Widget> items;

  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.cardBg,
        borderRadius: BorderRadius.circular(16),
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
  final Widget? trailing;

  const _MenuItem({
    this.iconAsset,
    this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
    this.trailing,
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                SizedBox(width: 14),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.labelText,
                    ),
                  ),
                ),
                // Trailing widget or default chevron
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: context.appColors.placeholderText,
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
            color: context.appColors.inputBorder.withAlpha(180),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card theme picker sheet
// ---------------------------------------------------------------------------

class _CardThemeSheet extends StatelessWidget {
  const _CardThemeSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: context.appColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.appColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Card Theme',
                  style: GoogleFonts.urbanist(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.labelText,
                  ),
                ),
                const Spacer(),
                // "No theme" / reset option
                ValueListenableBuilder<String?>(
                  valueListenable: ServiceLocator.cardThemeNotifier,
                  builder: (context, current, _) => TextButton(
                    onPressed: current == null
                        ? null
                        : () async {
                            ServiceLocator.cardThemeNotifier.value = null;
                            await LocalStorage.setDefaultCardTheme('');
                          },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: current == null
                            ? context.appColors.placeholderText
                            : AppColors.expense,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: ServiceLocator.cardThemeNotifier,
              builder: (context, selected, _) {
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _kCardBackdrops.length,
                  itemBuilder: (context, i) {
                    final path = _kCardBackdrops[i];
                    final isSelected = selected == path;
                    return GestureDetector(
                      onTap: () async {
                        ServiceLocator.cardThemeNotifier.value = path;
                        await LocalStorage.setDefaultCardTheme(path);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(path, fit: BoxFit.cover),
                              if (isSelected)
                                Container(
                                  color: AppColors.primary.withAlpha(40),
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.all(6),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme mode toggle item
// ---------------------------------------------------------------------------

class _ThemeModeItem extends StatelessWidget {
  const _ThemeModeItem();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ServiceLocator.themeNotifier,
      builder: (context, current, _) {
        final isDark = current == ThemeMode.dark ||
            (current == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return InkWell(
          onTap: () async {
            final next = isDark ? ThemeMode.light : ThemeMode.dark;
            ServiceLocator.themeNotifier.value = next;
            await LocalStorage.setThemeMode(
                next == ThemeMode.dark ? 'dark' : 'light');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Image.asset(
                    'assets/icons/accountinfo/LightDarkMode.webp',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Light / Dark Mode',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.labelText,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) async {
                    final next = val ? ThemeMode.dark : ThemeMode.light;
                    ServiceLocator.themeNotifier.value = next;
                    await LocalStorage.setThemeMode(val ? 'dark' : 'light');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Premium badge chip
// ---------------------------------------------------------------------------

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF635AFF), Color(0xFF9B8FFF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'PRO',
        style: GoogleFonts.urbanist(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
