import 'package:flutter/material.dart';

import '../../app_shell.dart';
import '../../models/company_account.dart';
import '../../services/account_repository.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      CompanyAccount? account;
      try {
        account = await AccountRepository.currentAccount().timeout(
          const Duration(seconds: 8),
        );
      } catch (_) {
        account = null;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => account == null
              ? const LoginScreen()
              : AppShell(account: account),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7F3),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/ecologismart_isotipo.png',
            width: 136,
            height: 176,
            fit: BoxFit.contain,
            semanticLabel: 'Isotipo EcoLogiSmart',
          ),
          const SizedBox(height: 22),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],
      ),
    ),
  );
}
