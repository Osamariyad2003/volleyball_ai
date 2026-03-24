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
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: brightness,
      primary: const Color(0xFF0F766E),
      secondary: const Color(0xFFF97316),
      surface: isDark ? const Color(0xFF09111A) : const Color(0xFFF6F9FC),
    );

    final textTheme = GoogleFonts.barlowTextTheme().copyWith(
      headlineLarge: GoogleFonts.barlowCondensed(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      headlineMedium: GoogleFonts.barlowCondensed(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.barlow(fontSize: 20, fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.barlow(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
    );
  }
}
