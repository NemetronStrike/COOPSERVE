import 'package:flutter/material.dart';

/// Brand and semantic colour constants for COOPSERVE.
/// All colours are derived from or complement the Material 3 seed.
class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  /// Primary brand colour — trustworthy teal-blue for a cooperative service.
  static const Color brand = Color(0xFF1A6B8A);
  static const Color brandDark = Color(0xFF0D4F6B);
  static const Color brandLight = Color(0xFF4A9BB8);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF01579B);
  static const Color infoLight = Color(0xFFE1F5FE);

  // ── Neutral ────────────────────────────────────────────────────────────────
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ── Role accent colours ────────────────────────────────────────────────────
  static const Color customerAccent = Color(0xFF1565C0); // blue
  static const Color workerAccent = Color(0xFF2E7D32);   // green
  static const Color adminAccent = Color(0xFF6A1B9A);    // purple
}
