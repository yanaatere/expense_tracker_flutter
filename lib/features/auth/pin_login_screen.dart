import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/storage/local_storage.dart';
import '../../core/widgets/pin_pad.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _verifying = false;
  String? _error;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_pin.length < 4 && !_verifying) {
      setState(() { _pin += digit; _error = null; });
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_verifying) {
      setState(() { _pin = _pin.substring(0, _pin.length - 1); _error = null; });
    }
  }

  Future<void> _onVerify() async {
    if (_pin.length < 4 || _verifying) return;
    setState(() => _verifying = true);

    final storedPin = await LocalStorage.getPin();
    if (_pin == storedPin) {
      await LocalStorage.clearLastActiveAt();
      if (mounted) context.go('/home');
    } else {
      await _shakeController.forward(from: 0);
      if (mounted) {
        setState(() {
          _pin = '';
          _error = 'Incorrect PIN. Please try again.';
          _verifying = false;
        });
      }
    }
  }

  Future<void> _usePassword() async {
    await LocalStorage.clearAll();
    if (mounted) context.go('/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Enter PIN',
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

            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // ── Dots with shake ──────────────────────────────────────
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      final dx = _shakeAnimation.value == 0
                          ? 0.0
                          : 8 * (0.5 - (_shakeAnimation.value % 0.25) / 0.25).abs();
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: PinDots(filled: _pin.length),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: AppColors.expense,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  NumPad(onKey: _onKey, onBackspace: _onBackspace),
                  const SizedBox(height: 24),
                  // ── Verify button ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _pin.length == 4 && !_verifying ? _onVerify : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withAlpha(100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                        child: _verifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Login',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Fallback ─────────────────────────────────────────────
                  TextButton(
                    onPressed: _usePassword,
                    child: Text(
                      'Use password instead',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: AppColors.placeholderText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
