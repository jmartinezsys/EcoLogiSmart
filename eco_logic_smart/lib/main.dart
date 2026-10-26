import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'features/auth/password_reset_screen.dart';
import 'services/backend_config.dart';
import 'shared/app_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await BackendConfig.initialize();
  } catch (_) {
    // Keep the app shell visible so the user can read the configuration error.
  }
  if (BackendConfig.isInitialized) {
    BackendConfig.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        appNavigatorKey.currentState?.push(
          MaterialPageRoute<void>(builder: (_) => const PasswordResetScreen()),
        );
      }
    });
  }
  runApp(const EcoLogiSmartApp());
}
