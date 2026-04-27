import 'package:flutter/material.dart';

/// App color palette for CodeClub
/// Modern professional colors inspired by LinkedIn + WhatsApp
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primaryBlue = Color(0xFF0A66C2);
  static const Color primaryBlueDark = Color(0xFF004182);
  static const Color primaryBlueLight = Color(0xFF70B5F9);

  // Secondary Colors
  static const Color secondaryGreen = Color(0xFF057642);
  static const Color secondaryGreenLight = Color(0xFF25D366);
  static const Color accentOrange = Color(0xFFE7A33E);

  // Background Colors - Light Mode
  static const Color backgroundLight = Color(0xFFF3F2EF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Background Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF1B1F23);
  static const Color surfaceDark = Color(0xFF1D2226);
  static const Color cardDark = Color(0xFF283339);

  // Text Colors - Light Mode
  static const Color textPrimaryLight = Color(0xFF191919);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textTertiaryLight = Color(0xFF999999);

  // Text Colors - Dark Mode
  static const Color textPrimaryDark = Color.fromARGB(255, 138, 127, 127);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textTertiaryDark = Color(0xFF808080);

  // Status Colors
  static const Color success = Color(0xFF057642);
  static const Color error = Color(0xFFCC1016);
  static const Color warning = Color(0xFFE7A33E);
  static const Color info = Color(0xFF0A66C2);

  // Chat Colors
  static const Color chatBubbleSent = Color(0xFFDCF8C6);
  static const Color chatBubbleReceived = Color(0xFFFFFFFF);
  static const Color chatBubbleSentDark = Color(0xFF056162);
  static const Color chatBubbleReceivedDark = Color(0xFF283339);

  // Message bubble colors
  static const Color sentMessageBubble = Color(0xFF0A66C2);
  static const Color receivedMessageBubbleLight = Color(0xFFF1F1F1);
  static const Color receivedMessageBubbleDark = Color(0xFF283339);

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF38444D);

  // Divider Colors
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF38444D);

  // Gradient for buttons and headers
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, Color(0xFF0077B5)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryGreen, secondaryGreenLight],
  );
}
