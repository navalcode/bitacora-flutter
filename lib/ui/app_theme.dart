import 'package:flutter/material.dart';

ThemeData buildBitacoraTheme() {
  const ink = Color(0xff202421);
  const paper = Color(0xfffaf8f3);
  const muted = Color(0xff5e625c);
  const copper = Color(0xff9b432f);
  const soft = Color(0xfff2e3db);
  const line = Color(0xffddd8cd);
  const outline = Color(0xff85877e);
  const rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  const field = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: outline),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    scaffoldBackgroundColor: paper,
    colorScheme: const ColorScheme.light(
      primary: copper,
      onPrimary: Colors.white,
      primaryContainer: soft,
      onPrimaryContainer: copper,
      secondary: copper,
      onSecondary: Colors.white,
      secondaryContainer: soft,
      onSecondaryContainer: ink,
      tertiary: ink,
      onTertiary: Colors.white,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: line,
      error: copper,
      onError: Colors.white,
      errorContainer: soft,
      onErrorContainer: ink,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: paper,
      surfaceContainer: paper,
      surfaceContainerHigh: soft,
      surfaceContainerHighest: soft,
      inverseSurface: ink,
      onInverseSurface: Colors.white,
      inversePrimary: soft,
      surfaceTint: Colors.transparent,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontSize: 26,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 16, height: 1.4),
      bodySmall: TextStyle(fontSize: 13, height: 1.5, color: muted),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: field,
      enabledBorder: field,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: copper, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: const ChipThemeData(
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white,
      selectedColor: copper,
      secondarySelectedColor: copper,
      labelStyle: TextStyle(
        fontFamily: 'Outfit',
        color: ink,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'Outfit',
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: outline),
      shape: rounded,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected) ? copper : outline,
          width: 1.5,
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      minVerticalPadding: 8,
      horizontalTitleGap: 12,
      iconColor: muted,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        height: 1.4,
        color: muted,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: rounded,
      ),
    ),
  );
}
