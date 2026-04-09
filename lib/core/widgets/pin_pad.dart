import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../theme/app_colors_theme.dart';

// ── 4-dot indicator ─────────────────────────────────────────────────────────

class PinDots extends StatelessWidget {
  final int filled;
  const PinDots({super.key, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primary : const Color(0xFFD9D9D9),
          ),
        );
      }),
    );
  }
}

// ── Numeric keypad ──────────────────────────────────────────────────────────

class NumPad extends StatelessWidget {
  final void Function(String digit) onKey;
  final VoidCallback onBackspace;

  const NumPad({super.key, required this.onKey, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _row(['1', '2', '3']),
          const SizedBox(height: 12),
          _row(['4', '5', '6']),
          const SizedBox(height: 12),
          _row(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: SizedBox()), // empty left cell
              const SizedBox(width: 12),
              Expanded(child: _Key(label: '0', onTap: () => onKey('0'))),
              const SizedBox(width: 12),
              Expanded(
                child: _BackspaceKey(onTap: onBackspace),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      children: digits.map((d) {
        final isLast = d == digits.last;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: _Key(label: d, onTap: () => onKey(d))),
              if (!isLast) const SizedBox(width: 12),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Key({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: context.appColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  final VoidCallback onTap;
  const _BackspaceKey({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: context.appColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.primary),
      ),
    );
  }
}
