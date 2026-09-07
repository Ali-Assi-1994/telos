import 'package:flutter/material.dart';

/// App-wide color tokens, including the Calm Mint auth palette from Banani.
abstract final class AppColors {
  const AppColors._();

  // Base brand / seed color (used in ThemeData.fromSeed).
  static const Color brandSeed = Color(0xFF4F46E5);

  // Calm Mint palette used for auth flow.
  static const Color calmBackground = Color(0xFFF6FBF9);
  static const Color calmForeground = Color(0xFF0F1722);
  static const Color calmPrimary = Color(0xFF16A085);
  static const Color calmPrimaryForeground = Color(0xFFFFFFFF);
  static const Color calmMutedForeground = Color(0xFF6B7280);
  static const Color calmCard = Color(0xFFFFFFFF);
  static const Color calmBorder = Color(0xFFE5E7EB);
  static const Color calmSecondary = Color(0xFFE8F7F4);
  static const Color calmSecondaryForeground = Color(0xFF0F3B35);
  static const Color calmAccent = Color(0xFF8B5CF6);
  static const Color calmAccentForeground = Color(0xFFFFFFFF);
}
