import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/rounded_text_field.dart';
import '../../shared/widgets/social_login_buttons.dart';
import '../../service_locator.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String _errorMessage = '';

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ServiceLocator.authRepository
          .login(email: email, password: password);
      if (result.success) {
        if (mounted) context.go('/home');
      } else {
        setState(() =>
            _errorMessage = result.errorMessage ?? 'Invalid email or password');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = '';
    });
    try {
      final result = await ServiceLocator.authRepository.loginWithGoogle();
      if (result.success) {
        if (mounted) context.go('/home');
      } else {
        setState(() =>
            _errorMessage = result.errorMessage ?? 'Google sign in failed');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
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
            alignment: Alignment.bottomCenter,
          ),

          // Faint logo at top
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Opacity(
                  opacity: 0.4,
                  child: Text(
                    'monex',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom sheet card
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                // Swipe down dengan kecepatan > 300 px/s → kembali ke home
                if (velocity > 300) {
                  context.pop();
                }
              },
              child: SlideTransition(
                position: _slideAnimation,
                child: FractionallySizedBox(
                  heightFactor: 0.85,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 40,
                          offset: Offset(0, -10),
                        )
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 48,
                              height: 6,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),

                          Text('sign in', style: AppTextStyles.heading),
                          const SizedBox(height: 16),

                          // Error banner
                          if (_errorMessage.isNotEmpty) ...[
                            _ErrorBanner(message: _errorMessage),
                            const SizedBox(height: 12),
                          ],

                          RoundedTextField(
                            label: 'Email / Username',
                            placeholder: 'johndoe@sample.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          RoundedTextField(
                            label: 'Password',
                            placeholder: 'Enter your password',
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            showToggle: true,
                            onToggle: () =>
                                setState(() => _showPassword = !_showPassword),
                            textInputAction: TextInputAction.done,
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Forgot password ?',
                                style: TextStyle(
                                  color: Color(0xFF635AFF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          PrimaryButton(
                            label: _isLoading ? 'Signing in...' : 'Sign in',
                            isLoading: _isLoading,
                            onPressed: _handleSignIn,
                          ),
                          const SizedBox(height: 32),
                          SocialLoginButtons(
                            onGooglePressed:
                                _isGoogleLoading ? null : _handleGoogleSignIn,
                          ),
                          if (_isGoogleLoading) ...[
                            const SizedBox(height: 12),
                            const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF635AFF),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
