import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Or Login With', style: AppTextStyles.caption),
            ),
            const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
          ],
        ),
        const SizedBox(height: 16),
        _SocialButton(
          label: 'Google',
          icon: _googleIcon(),
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Apple',
          icon: _appleIcon(),
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Facebook',
          icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 20),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }

  Widget _appleIcon() {
    return const Icon(Icons.apple, color: Colors.black, size: 22);
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Google "G" logo drawn with CustomPainter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Red arc (top-right)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -1.0, 1.57, true, paint);
    // Blue arc (top-left + left)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0.57, 1.74, true, paint);
    // Yellow arc (bottom-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        2.31, 1.57, true, paint);
    // Green arc (bottom-right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        3.88, 1.26, true, paint);

    // White inner circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);

    // Blue right bar of "G"
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.15, r, r * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}
