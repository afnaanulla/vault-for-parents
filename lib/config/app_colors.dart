import 'package:flutter/material.dart';

/// Jupiter banking inspired color palette
class AppColors {
  AppColors._();

  // Primary branding
  static const Color primary = Color(0xFF2563EB); // Jupiter Clean Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color secondary = Color(0xFFF0F9FF); // Soft Ice Blue
  static const Color secondaryDark = Color(0xFFE0F2FE);
  static const Color accent = Color(0xFF06B6D4); // Cyan / Teal

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean neutral off-white
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Typography
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textBody = Color(0xFF334155); // Slate 700
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400

  // Semantic Status
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);

  // Profile Specific Identity Colors
  static const Color fatherPrimary = Color(0xFF2563EB);
  static const Color fatherBg = Color(0xFFEFF6FF);
  static const Color motherPrimary = Color(0xFF8B5CF6);
  static const Color motherBg = Color(0xFFF5F3FF);
}
