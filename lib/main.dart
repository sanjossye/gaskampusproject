import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding_screen.dart';

// Notifier global untuk kontrol Dark Mode dan Light Mode di seluruh aplikasi
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.system);

void main() {
  runApp(const GasKampusApp());
}

class GasKampusApp extends StatelessWidget {
  const GasKampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'GasKampus',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            textTheme: GoogleFonts.interTextTheme(),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFC0F637),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F8F5),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFC0F637),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            useMaterial3: true,
          ),
          themeMode: currentMode,
          home: const OnboardingWrapper(),
        );
      },
    );
  }
}
