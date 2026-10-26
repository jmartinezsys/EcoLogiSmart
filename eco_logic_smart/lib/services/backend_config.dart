import 'package:supabase_flutter/supabase_flutter.dart';

class BackendConfig {
  BackendConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
  static bool get isRequested => url.isNotEmpty || publishableKey.isNotEmpty;
  static bool get isInitialized => isConfigured && _initialized;
  static bool _initialized = false;

  static SupabaseClient get client {
    if (!isInitialized) {
      throw StateError('Supabase no está configurado para esta ejecución.');
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (!isConfigured || _initialized) return;
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    _initialized = true;
  }
}
