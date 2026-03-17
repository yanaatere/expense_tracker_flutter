import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/storage/local_storage.dart';
import '../../service_locator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _username = 'User';
  // ignore: unused_field — reserved for entrance animation trigger
  bool _visible = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final username = await LocalStorage.getUsername();
    if (mounted) {
      setState(() {
        _username = username ?? 'User';
        _visible = true;
      });
      _animController.forward();
    }
  }

  Future<void> _handleSignOut() async {
    await ServiceLocator.authRepository.signOut();
    if (mounted) context.go('/signin');
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/background.webp',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(25),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(13),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(51),
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF635AFF),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Welcome text
                  Text(
                    'Login Successful!',
                    style: AppTextStyles.heading.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withAlpha(178),
                      ),
                      children: [
                        const TextSpan(text: 'Welcome back, '),
                        TextSpan(
                          text: _username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're all set to manage your finances",
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withAlpha(128),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Dashboard placeholder card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(38),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withAlpha(51),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dashboard',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withAlpha(153),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Coming soon',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withAlpha(102),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(38),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FractionallySizedBox(
                            widthFactor: 0.75,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FractionallySizedBox(
                            widthFactor: 0.5,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign out button
                  TextButton.icon(
                    onPressed: _handleSignOut,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(38),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                        side: BorderSide(
                          color: Colors.white.withAlpha(51),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.logout,
                        color: Colors.white, size: 16),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom branding
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Opacity(
                      opacity: 0.3,
                      child: Text(
                        'monex',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
