import 'package:flutter/material.dart';
import '../models/app_models.dart';

class AppTheme {
  // Sacred Ethiopian Orthodox Palette Defaults
  static const Color primaryBg = Color(0xFF0C1017);
  static const Color secondaryBg = Color(0xFF131923);
  static const Color surfaceColor = Color(0xFF1A2230);
  static const Color surfaceElevated = Color(0xFF222D3E);
  static const Color surfaceGlass = Color(0xCC1A2230);

  // Accents: Liturgical Gold, Amber, Warm Sand
  static const Color goldAccent = Color(0xFFD48B38);
  static const Color goldLight = Color(0xFFE5A65E);
  static const Color goldDeep = Color(0xFFBF7526);
  static const Color amberGlow = Color(0xFFF59E0B);
  static const Color goldMuted = Color(0xFF5A4426);

  // Accent Tints & Status
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldBg = Color(0xFF064E3B);
  static const Color crimson = Color(0xFFEF4444);
  static const Color crimsonBg = Color(0xFF450A0A);
  static const Color azure = Color(0xFF3B82F6);
  static const Color azureBg = Color(0xFF1E3A5F);
  static const Color slateMuted = Color(0xFF8E9BAE);
  static const Color borderMuted = Color(0xFF2D3748);
  static const Color borderGlow = Color(0x40D48B38);

  // Text Colors
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textGold = Color(0xFFE5A65E);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE5A65E), Color(0xFFD48B38), Color(0xFFBF7526)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C2534), Color(0xFF151C28)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGlowGradient = LinearGradient(
    colors: [Color(0x33D48B38), Color(0x05D48B38), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme => getTheme(AppThemePalette.midnightGold);

  // Context-aware dynamic theme getters
  static Color bg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color card(BuildContext context) => Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color accentLight(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color text(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  static ThemeData getTheme(AppThemePalette palette) {
    final bg = palette.scaffoldBg;
    final secBg = palette.surfaceBg;
    final surface = palette.cardBg;
    final elevated = palette.elevatedBg;
    final accent = palette.secondaryAccent;
    final accentLight = palette.primaryAccent;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      primaryColor: accent,
      colorScheme: ColorScheme.dark(
        primary: accentLight,
        secondary: accent,
        surface: surface,
        surfaceContainerHighest: elevated,
        error: crimson,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'serif',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'serif',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: accentLight,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: accentLight),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderMuted, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderMuted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentLight, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
        labelStyle: TextStyle(color: accentLight, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentLight,
          foregroundColor: Colors.black,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentLight,
          side: BorderSide(color: accentLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentLight,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: accentLight,
        unselectedItemColor: slateMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(
        color: borderMuted,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accentLight.withOpacity(0.5)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
