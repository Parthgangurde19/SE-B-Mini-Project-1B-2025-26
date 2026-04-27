import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AIMentorTheme {
  static const Color primaryBlue = AppColors.primaryBlue;
  static const Color deepBlue = AppColors.primaryBlueDark;
  static const Color accentGreen = AppColors.secondaryGreenLight;

  static const List<Color> fabGradient = [primaryBlue, deepBlue];

  static LinearGradient headerGradient = const LinearGradient(
    colors: [primaryBlue, deepBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient backgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? const [Color(0xFF1B1F23), Color(0xFF222A30)]
          : const [AppColors.backgroundLight, Color(0xFFEDEBE7)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static Color scaffoldBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  }

  static Color cardBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.cardDark : AppColors.cardLight;
  }

  static Color cardBg2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  }

  static Color aiBubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.cardDark : AppColors.surfaceLight;
  }

  static Color textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  }

  static Color textSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  }

  static Color divider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.dividerDark : AppColors.dividerLight;
  }

  static TextStyle headingStyle(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: textPrimary(context),
    );
  }

  static TextStyle messageStyle(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 14,
      color: textPrimary(context),
      height: 1.45,
    );
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return GoogleFonts.inter(fontSize: 12, color: textSecondary(context));
  }

  static TextStyle monoStyle(BuildContext context) {
    return GoogleFonts.spaceMono(
      fontSize: 12,
      color: deepBlue,
      fontWeight: FontWeight.w500,
    );
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, accentGreen],
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
  );
}
