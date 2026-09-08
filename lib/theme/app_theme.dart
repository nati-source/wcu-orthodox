import 'package:flutter/material.dart';
import '../models/app_models.dart';

class AppTheme {
  // Sacred Ethiopian Orthodox Palette Defaults - Midnight Fellowship (Default Dark)
  static const Color primaryBg = Color(0xFF070F1E);
  static const Color secondaryBg = Color(0xFF101C33);
  static const Color surfaceColor = Color(0xFF101C33);
  static const Color surfaceElevated = Color(0xFF232E48);
  static const Color surfaceTile = Color(0xFF1C2333);
  static const Color surfaceGlass = Color(0xCC101C33);

  // Accents: Liturgical Radiant Gold, Warm Honey Gold, Monastic Amber
  static const Color goldAccent = Color(0xFFD97706);
  static const Color goldLight = Color(0xFFF59E0B);
  static const Color goldDeep = Color(0xFFB45309);
  static const Color amberGlow = Color(0xFFF59E0B);
  static const Color goldMuted = Color(0xFF5A4426);

  // Status & Liturgical Accents
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldBg = Color(0xFF064E3B);
  static const Color crimson = Color(0xFF991B1B);
  static const Color crimsonBg = Color(0xFF450A0A);
  static const Color pendingRose = Color(0xFFFB7185);
  static const Color royalViolet = Color(0xFF8B5CF6);
  static const Color azure = Color(0xFF3B82F6);
  static const Color slateMuted = Color(0xFF8E9BAE);
  static const Color borderMuted = Color(0xFF1E293B);
  static const Color borderGlow = Color(0x40F59E0B);

  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textGold = Color(0xFFF59E0B);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF15223C), Color(0xFF0F1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGlowGradient = LinearGradient(
    colors: [Color(0x33F59E0B), Color(0x05F59E0B), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme => getTheme(AppThemePalette.midnightFellowship);

  // Context-aware dynamic theme getters
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color bg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color card(BuildContext context) => Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
  static Color elevated(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color tile(BuildContext context) => Theme.of(context).colorScheme.surfaceContainer;
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color accentSecondary(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color text(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color textMuted(BuildContext context) => Theme.of(context).textTheme.bodyMedium?.color ?? textSecondary;
  static Color border(BuildContext context) => Theme.of(context).dividerColor;

  static ThemeData getTheme(AppThemePalette palette) {
    final isDark = palette.isDark;
    final bg = palette.scaffoldBg;
    final surface = palette.cardBg;
    final elevated = palette.elevatedBg;
    final tile = palette.tileBg;
    final primaryAccent = palette.primaryAccent;
    final secondaryAccent = palette.secondaryAccent;
    final textColor = palette.textPrimary;
    final textMutedColor = palette.textSecondary;
    final borderColor = palette.borderMuted;

    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: borderColor,
      primaryColor: primaryAccent,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primaryAccent,
              secondary: secondaryAccent,
              surface: surface,
              surfaceContainerHighest: elevated,
              surfaceContainer: tile,
              error: crimson,
              onPrimary: Colors.black,
              onSecondary: Colors.white,
              onSurface: textColor,
              onError: Colors.white,
            )
          : ColorScheme.light(
              primary: primaryAccent,
              secondary: secondaryAccent,
              surface: surface,
              surfaceContainerHighest: elevated,
              surfaceContainer: tile,
              error: crimson,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: textColor,
              onError: Colors.white,
            ),
      fontFamily: 'serif',
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontFamily: 'serif', color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'serif', color: textColor, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'serif', color: textColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'serif', color: textColor, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontFamily: 'serif', color: textColor, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontFamily: 'serif', color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textMutedColor),
        bodySmall: TextStyle(color: textMutedColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'serif',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryAccent,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: primaryAccent),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 4 : 2,
        shadowColor: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tile,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryAccent, width: 1.5),
        ),
        hintStyle: TextStyle(color: textMutedColor, fontSize: 14),
        labelStyle: TextStyle(color: primaryAccent, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: isDark ? Colors.black : Colors.white,
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
          foregroundColor: primaryAccent,
          side: BorderSide(color: primaryAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryAccent,
        foregroundColor: isDark ? Colors.black : Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: primaryAccent,
        unselectedItemColor: textMutedColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: TextStyle(color: textColor, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: primaryAccent.withOpacity(0.5)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
