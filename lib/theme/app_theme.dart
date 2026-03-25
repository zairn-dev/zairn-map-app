import 'package:flutter/material.dart';

/// Zairn Map Design System
/// Material Design 3 based theme with warm, Japanese-inspired tones.
///
/// Color roles:
///   primary        → Brand accent, active states, FABs
///   secondary      → Supporting elements, chips, toggles
///   tertiary       → Complementary accent (terrain toggle, badges)
///   surface        → Floating controls, cards, dialogs
///   surfaceContainerHighest → Elevated surfaces (bottom sheets)
///   outline        → Subtle borders
///   onSurface      → Primary text on surface
///   onSurfaceVariant → Secondary text, icons

class AppTheme {
  AppTheme._();

  // ── Brand colors (from cairn logo) ──
  // Bottom stone gradient: pink → orange
  // Middle stones: teal → cyan
  // Top stone: amber
  static const Color _seedColor = Color(0xFF00B8A9);

  static const Color brandPink = Color(0xFFFF2D78);
  static const Color brandOrange = Color(0xFFFF9800);
  static const Color brandTeal = Color(0xFF009688);
  static const Color brandCyan = Color(0xFF00E5CC);
  static const Color brandAmber = Color(0xFFFFAB00);

  // ──────────────────────────────────────
  // Light Theme
  // ──────────────────────────────────────
  static final ThemeData light = _buildTheme(Brightness.light);

  // ──────────────────────────────────────
  // Dark Theme
  // ──────────────────────────────────────
  static final ThemeData dark = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ).copyWith(
      // Primary — teal/cyan (middle stones of cairn)
      primary: isLight ? brandTeal : brandCyan,
      onPrimary: Colors.white,
      primaryContainer: isLight ? brandCyan : const Color(0xFF004D47),
      onPrimaryContainer: isLight ? const Color(0xFF00332E) : brandCyan,

      // Secondary — orange/amber (top stone + bottom gradient)
      secondary: isLight ? brandOrange : brandAmber,
      onSecondary: Colors.white,
      secondaryContainer: isLight ? const Color(0xFFFFD180) : const Color(0xFF4A3000),
      onSecondaryContainer: isLight ? const Color(0xFF3E2700) : brandAmber,

      // Tertiary — hot pink (bottom stone accent)
      tertiary: brandPink,
      onTertiary: Colors.white,
      tertiaryContainer: isLight ? const Color(0xFFFFD9E3) : const Color(0xFF5C0028),
      onTertiaryContainer: isLight ? const Color(0xFF3E001A) : brandPink,

      // Warm surfaces
      surface: isLight ? const Color(0xFFFAF8F5) : const Color(0xFF1A1714),
      surfaceContainerHighest: isLight
          ? const Color(0xFFEDE8E0)
          : const Color(0xFF2E2A24),
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // ── Shape ──
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
        ),
      ),

      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── NavigationBar ──
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 6,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // ── BottomSheet ──
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        backgroundColor: colorScheme.surface,
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      // Headline
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      // Title
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      // Body
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
      ),
      // Label
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ──────────────────────────────────────
// Spacing constants
// ──────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
