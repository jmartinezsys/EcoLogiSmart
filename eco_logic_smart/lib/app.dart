import 'package:flutter/material.dart';

import 'features/auth/splash_screen.dart';
import 'shared/app_navigation.dart';

class EcoLogiSmartApp extends StatelessWidget {
  const EcoLogiSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF173E35);
    const leaf = Color(0xFF3B8D68);
    const canvas = Color(0xFFF4F7F3);
    const line = Color(0xFFDCE5DE);
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'EcoLogiSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: const ColorScheme.light(
          primary: forest,
          onPrimary: Colors.white,
          secondary: leaf,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF26382E),
          error: Color(0xFFB5473C),
          outline: line,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: forest,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          hintStyle: const TextStyle(color: Color(0xFF89958D), fontSize: 14),
          labelStyle: const TextStyle(color: Color(0xFF68776D)),
          prefixIconColor: const Color(0xFF738279),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: leaf, width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 48),
            foregroundColor: forest,
            side: const BorderSide(color: line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFFE3F0E7),
          elevation: 12,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
