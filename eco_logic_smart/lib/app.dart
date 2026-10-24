import 'package:flutter/material.dart';

import 'features/dashboard/dashboard_screen.dart';

class EcoLogiSmartApp extends StatelessWidget {
  const EcoLogiSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF173E35);
    const leaf = Color(0xFF3B8D68);

    return MaterialApp(
      title: 'EcoLogiSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: leaf,
          primary: forest,
          secondary: leaf,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F3),
          foregroundColor: forest,
          elevation: 0,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
