import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle logo = GoogleFonts.urbanist(
    fontSize: 60,
    fontWeight: FontWeight.w900,
    color: const Color(0xFF2121D3),
    letterSpacing: -2,
    height: 1,
  );

  static TextStyle heading = GoogleFonts.urbanist(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.labelText,
  );

  static TextStyle label = GoogleFonts.urbanist(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.labelText,
  );

  static TextStyle body = GoogleFonts.urbanist(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.bodyText,
  );

  static TextStyle buttonText = GoogleFonts.urbanist(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle caption = GoogleFonts.urbanist(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.placeholderText,
  );
}
