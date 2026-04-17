import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/storage/local_storage.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/rounded_text_field.dart';
import '../../service_locator.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _showSuccess = false;
  String _errorMessage = '';
  String _successDestination = '/signin';

  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnimation;

  // Success overlay controllers
  late final AnimationController _backdropCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _checkCtrl;
  late final AnimationController _textCtrl;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();

    _backdropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _backdropCtrl.dispose();
    _cardCtrl.dispose();
    _checkCtrl.dispose();
    _textCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  static final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  Future<void> _showSuccessAndNavigate(String destination) async {
    setState(() => _showSuccess = true);
    _successDestination = destination;

    await _backdropCtrl.forward();
    await _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _checkCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      context.go(destination);
    }
  }

  Future<void> _handleCreateAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (_nameController.text.trim().isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final wasLocalMode = await LocalStorage.isLocalMode();
      final result = await ServiceLocator.authRepository.register(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: password,
      );
      if (result.success) {
        if (wasLocalMode && !result.isPending) {
          await LocalStorage.setLocalMode(false);
        }
        if (mounted) {
          final destination =
              (wasLocalMode && !result.isPending) ? '/premium' : '/onboarding/wallet';
          await _showSuccessAndNavigate(destination);
        }
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
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                // Swipe down dengan kecepatan > 300 px/s → kembali ke halaman sebelumnya
                if (velocity > 300) {
                  context.pop();
                }
              },
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
          ),

          // Success overlay
          if (_showSuccess)
            _SuccessOverlay(
              backdropCtrl: _backdropCtrl,
              cardCtrl: _cardCtrl,
              checkCtrl: _checkCtrl,
              textCtrl: _textCtrl,
              username: _nameController.text.trim(),
              destination: _successDestination,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success overlay
// ---------------------------------------------------------------------------

class _SuccessOverlay extends StatelessWidget {
  final AnimationController backdropCtrl;
  final AnimationController cardCtrl;
  final AnimationController checkCtrl;
  final AnimationController textCtrl;
  final String username;
  final String destination;

  const _SuccessOverlay({
    required this.backdropCtrl,
    required this.cardCtrl,
    required this.checkCtrl,
    required this.textCtrl,
    required this.username,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final cardScale = CurvedAnimation(
      parent: cardCtrl,
      curve: Curves.elasticOut,
    );
    final textFade = CurvedAnimation(parent: textCtrl, curve: Curves.easeIn);
    final backdropFade =
        CurvedAnimation(parent: backdropCtrl, curve: Curves.easeIn);

    return AnimatedBuilder(
      animation: backdropCtrl,
      builder: (context, _) => Opacity(
        opacity: backdropFade.value,
        child: Container(
          color: const Color(0xCC0D0B26),
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: cardScale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 60,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated checkmark circle
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: AnimatedBuilder(
                      animation: checkCtrl,
                      builder: (context, _) => CustomPaint(
                        painter: _CheckmarkPainter(
                          progress: checkCtrl.value,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title + subtitle fade in
                  FadeTransition(
                    opacity: textFade,
                    child: Column(
                      children: [
                        Text(
                          'Account Created!',
                          style: AppTextStyles.heading.copyWith(fontSize: 22),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Welcome, ${username.isNotEmpty ? username.split(' ').first : 'there'}!\nYou\'re all set to start tracking your finances.',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        // Destination pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(18),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                destination == '/premium'
                                    ? 'Going to Premium...'
                                    : 'Setting up your wallet...',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated checkmark painter
// ---------------------------------------------------------------------------

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle (faint)
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withAlpha(20),
    );

    // Animated stroke circle
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // top
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 0.6) / 0.6;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      startAngle,
      sweepAngle,
      false,
      circlePaint,
    );

    // Checkmark — only drawn after circle is ~60% done
    if (progress > 0.6) {
      final checkProgress = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      _drawCheckmark(canvas, center, radius, checkProgress);
    }
  }

  void _drawCheckmark(
      Canvas canvas, Offset center, double radius, double progress) {
    // Define checkmark points relative to circle center
    final p1 = Offset(center.dx - radius * 0.28, center.dy + radius * 0.02);
    final p2 = Offset(center.dx - radius * 0.04, center.dy + radius * 0.26);
    final p3 = Offset(center.dx + radius * 0.32, center.dy - radius * 0.22);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // First segment: p1 → p2
    final seg1Len = (p2 - p1).distance;
    final seg2Len = (p3 - p2).distance;
    final totalLen = seg1Len + seg2Len;
    final drawnLen = totalLen * progress;

    final path = Path();
    if (drawnLen <= seg1Len) {
      final t = drawnLen / seg1Len;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );
    } else {
      final t = (drawnLen - seg1Len) / seg2Len;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * t,
        p2.dy + (p3.dy - p2.dy) * t,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------

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
