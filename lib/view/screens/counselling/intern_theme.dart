// ─────────────────────────────────────────────────────────────────
// view/screens/intern/intern_theme.dart
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class InternTheme {
  // Palette
  static const Color primary       = Color(0xFF0A9E8A);
  static const Color primaryLight  = Color(0xFF14C4AA);
  static const Color accent        = Color(0xFF38EF7D);
  static const Color surface       = Color(0xFFF7FAFA);
  static const Color card          = Colors.white;
  static const Color textDark      = Color(0xFF0D1F1E);
  static const Color textMid       = Color(0xFF4A6361);
  static const Color textLight     = Color(0xFF8AACAA);
  static const Color available     = Color(0xFF22C55E);
  static const Color unavailable   = Color(0xFFCBD5E1);
  static const Color danger        = Color(0xFFEF4444);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0A9E8A), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFE0FAF4), Color(0xFFF7FAFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static ThemeData theme = ThemeData(
    colorSchemeSeed: primary,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Nunito',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
  );
}