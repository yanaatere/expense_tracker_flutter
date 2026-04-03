import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

// ── Bottom-sheet picker ───────────────────────────────────────────────────────

/// Opens a numpad bottom sheet.
/// Returns the entered amount string on "Done", or null if dismissed.
Future<String?> showAmountPicker(
  BuildContext context, {
  String initial = '0',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AmountPickerSheet(initial: initial),
  );
}

class _AmountPickerSheet extends StatefulWidget {
  final String initial;
  const _AmountPickerSheet({required this.initial});

  @override
  State<_AmountPickerSheet> createState() => _AmountPickerSheetState();
}

class _AmountPickerSheetState extends State<_AmountPickerSheet> {
  late String _amountStr;

  @override
  void initState() {
    super.initState();
    _amountStr = widget.initial.isEmpty ? '0' : widget.initial;
  }

  double get _amount => double.tryParse(_amountStr) ?? 0;

  String get _formatted {
    if (_amount == 0) return 'Rp. 0';
    final v = _amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'Rp. $v';
  }

  void _onDigit(String d) {
    setState(() {
      if (d == '00') {
        if (_amountStr != '0' && _amountStr.length < 11) _amountStr += '00';
        return;
      }
      if (_amountStr == '0') {
        _amountStr = d;
      } else if (_amountStr.length < 12) {
        _amountStr += d;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountStr.length <= 1) {
        _amountStr = '0';
      } else {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _formatted,
            style: GoogleFonts.urbanist(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.labelText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter Amount',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: AppColors.placeholderText,
            ),
          ),
          const SizedBox(height: 16),
          AmountNumpad(onDigit: _onDigit, onBackspace: _onBackspace),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(_amountStr),
              child: Text(
                'Done',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable numpad key grid ──────────────────────────────────────────────────

class AmountNumpad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final Color? keyColor;
  final Color? labelColor;
  final double keyHeight;

  const AmountNumpad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.keyColor,
    this.labelColor,
    this.keyHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(['1', '2', '3']),
        const SizedBox(height: 8),
        _row(['4', '5', '6']),
        const SizedBox(height: 8),
        _row(['7', '8', '9']),
        const SizedBox(height: 8),
        Row(
          children: [
            _key('00', () => onDigit('00')),
            const SizedBox(width: 8),
            _key('0', () => onDigit('0')),
            const SizedBox(width: 8),
            _key('⌫', onBackspace, isAction: true),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _key(digits[i], () => onDigit(digits[i])),
        ],
      ],
    );
  }

  Widget _key(String label, VoidCallback onTap, {bool isAction = false}) {
    return Expanded(
      child: _NumKey(
        label: label,
        onTap: onTap,
        isAction: isAction,
        keyColor: keyColor,
        labelColor: labelColor,
        height: keyHeight,
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;
  final Color? keyColor;
  final Color? labelColor;
  final double height;

  const _NumKey({
    required this.label,
    required this.onTap,
    this.isAction = false,
    this.keyColor,
    this.labelColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: keyColor ?? AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: isAction ? 20 : 22,
            fontWeight: FontWeight.w600,
            color: labelColor ?? AppColors.labelText,
          ),
        ),
      ),
    );
  }
}
