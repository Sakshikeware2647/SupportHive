import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand palette ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);      // violet-600
  static const Color primaryLight = Color(0xFFEDE9FE); // violet-100
  static const Color secondary = Color(0xFFEC4899);    // pink-500
  static const Color accent = Color(0xFF10B981);       // emerald-500
  static const Color warning = Color(0xFFF59E0B);      // amber-500
  static const Color surface = Color(0xFFF8F7FF);      // tinted white
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B4B);  // indigo-950
  static const Color textSecondary = Color(0xFF6B7280);// gray-500
  static const Color divider = Color(0xFFE5E7EB);      // gray-200
  static const Color available = Color(0xFF10B981);
  static const Color unavailable = Color(0xFFEF4444);

  // ── Gradient ─────────────────────────────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient freeBannerGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Text styles ───────────────────────────────────────────────────────────────
  static const TextStyle displayMd = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle titleSm = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    color: textSecondary,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  // ── Card decoration ───────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration chipDecoration(Color color) => BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      );
}
