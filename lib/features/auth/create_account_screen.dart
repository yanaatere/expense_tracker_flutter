import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/rounded_text_field.dart';
import '../../service_locator.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (password.length < 6) {
      setState(
          () => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ServiceLocator.authRepository.register(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: password,
      );
      if (result.success) {
        if (mounted) context.go('/signin');
      } else {
        setState(() => _errorMessage =
            result.errorMessage ?? 'Registration failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

          // Faint logo
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
            child: SlideTransition(
              position: _slideAnimation,
              child: FractionallySizedBox(
                heightFactor: 0.90,
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

                        Text('Create Account', style: AppTextStyles.heading),
                        const SizedBox(height: 16),

                        // Error banner
                        if (_errorMessage.isNotEmpty) ...[
                          _ErrorBanner(message: _errorMessage),
                          const SizedBox(height: 12),
                        ],

                        RoundedTextField(
                          label: 'Full Name',
                          placeholder: 'Name',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 16),
                        RoundedTextField(
                          label: 'Email',
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
                        ),
                        const SizedBox(height: 16),
                        RoundedTextField(
                          label: 'Confirm Password',
                          placeholder: 'Enter your password',
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          showToggle: true,
                          onToggle: () => setState(
                              () => _showConfirmPassword = !_showConfirmPassword),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 16),

                        // Terms checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => setState(
                                  () => _agreedToTerms = !_agreedToTerms),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _agreedToTerms
                                      ? AppColors.primary
                                      : Colors.white,
                                  border: Border.all(
                                    color: _agreedToTerms
                                        ? AppColors.primary
                                        : const Color(0xFFD1D5DB),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: _agreedToTerms
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 14)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: AppTextStyles.caption,
                                  children: [
                                    const TextSpan(text: 'I Agree to the '),
                                    TextSpan(
                                      text: 'terms & condition',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        PrimaryButton(
                          label: _isLoading
                              ? 'Creating Account...'
                              : 'Create Account',
                          isLoading: _isLoading,
                          onPressed: _agreedToTerms ? _handleCreateAccount : null,
                        ),
                      ],
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
