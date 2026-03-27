import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../home/presentation/screens/main_navigation_screen.dart';
import '../application/providers.dart';

class VoiceCoachApp extends ConsumerWidget {
  const VoiceCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Volleyball AI Voice Coach',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const MainNavigationScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.74)
        : const Color(0xFF475569);
    final surfaceColor = isDark
        ? const Color(0xFF09111A)
        : const Color(0xFFF6F9FC);
    final baseScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: brightness,
          primary: const Color(0xFF0F766E),
          secondary: const Color(0xFFF97316),
          surface: surfaceColor,
        ).copyWith(
          surface: surfaceColor,
          onSurface: contentColor,
          onSurfaceVariant: mutedColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          outline: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFF94A3B8),
        );

    final textTheme = GoogleFonts.barlowTextTheme()
        .apply(bodyColor: contentColor, displayColor: contentColor)
        .copyWith(
          headlineLarge: GoogleFonts.barlowCondensed(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: contentColor,
          ),
          headlineMedium: GoogleFonts.barlowCondensed(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: contentColor,
          ),
          titleLarge: GoogleFonts.barlow(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: contentColor,
          ),
          bodyLarge: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: contentColor,
          ),
          bodyMedium: GoogleFonts.barlow(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
          labelLarge: GoogleFonts.barlow(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: contentColor,
          ),
        );

    return ThemeData(
      colorScheme: baseScheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF061019)
          : const Color(0xFFF3F7FB),
      textTheme: textTheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: contentColor,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: contentColor),
        iconTheme: IconThemeData(color: contentColor),
      ),
      iconTheme: IconThemeData(color: contentColor),
      primaryIconTheme: IconThemeData(color: contentColor),
      listTileTheme: ListTileThemeData(
        textColor: contentColor,
        iconColor: contentColor,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF08131D) : Colors.white,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: isSelected ? contentColor : mutedColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(color: isSelected ? contentColor : mutedColor);
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF0C1722) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFD8E3EC),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF12202D) : Colors.white,
        labelStyle: TextStyle(color: mutedColor),
        hintStyle: TextStyle(color: mutedColor),
        prefixIconColor: mutedColor,
        suffixIconColor: mutedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
      ),
    );
  }
}
