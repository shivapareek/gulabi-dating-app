import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Brand {
  static const pink = Color(0xFFFF3C78);
  static const coral = Color(0xFFFF7A59);
  static const gold = Color(0xFFFFB648);
  static const blue = Color(0xFF3FA9F5);
  static const green = Color(0xFF2ED47A);
  static const gradient = LinearGradient(
    colors: [pink, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFFFC94D), Color(0xFFFF8A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.pink,
    brightness: b,
    primary: Brand.pink,
    surface: dark ? const Color(0xFF141018) : Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: GoogleFonts.poppins().fontFamily,
  );
  return base.copyWith(
    scaffoldBackgroundColor:
        dark ? const Color(0xFF0E0B11) : const Color(0xFFFFF8FA),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: GoogleFonts.poppins().fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: dark ? Colors.white : const Color(0xFF1D1220),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1E1823) : const Color(0xFFFFEFF4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
  );
}
