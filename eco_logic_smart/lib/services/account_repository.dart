import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/company_account.dart';
import 'backend_config.dart';
import 'local_account_store.dart';

class AccountRegistrationResult {
  const AccountRegistrationResult({
    required this.account,
    this.emailConfirmationRequired = false,
  });

  final CompanyAccount? account;
  final bool emailConfirmationRequired;
}

class AccountRepository {
  AccountRepository._();

  static bool get isCloudEnabled => BackendConfig.isRequested;

  static Future<AccountRegistrationResult> register({
    required CompanyAccount account,
    required String password,
  }) async {
    if (!isCloudEnabled) {
      final created = await LocalAccountStore.register(
        account: account,
        password: password,
      );
      return AccountRegistrationResult(account: created ? account : null);
    }

    final response = await BackendConfig.client.auth.signUp(
      email: account.email.trim().toLowerCase(),
      password: password,
      emailRedirectTo: _emailRedirectUri,
      data: {
        'business_name': account.businessName,
        'contact_name': account.contactName,
        'sector': account.sector,
        'city': account.city,
      },
    );
    if (response.user == null) {
      throw const AuthException('No se pudo crear la cuenta.');
    }
    if (response.session == null) {
      return const AccountRegistrationResult(
        account: null,
        emailConfirmationRequired: true,
      );
    }
    return AccountRegistrationResult(
      account: await _readProfile(response.user!.id),
    );
  }

  static Future<CompanyAccount?> authenticate({
    required String email,
    required String password,
  }) async {
    if (!isCloudEnabled) {
      return LocalAccountStore.authenticate(email: email, password: password);
    }
    final response = await BackendConfig.client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = response.user;
    return user == null ? null : _readProfile(user.id);
  }

  static Future<CompanyAccount?> currentAccount() async {
    if (!BackendConfig.isInitialized) return null;
    final user = BackendConfig.client.auth.currentUser;
    return user == null ? null : _readProfile(user.id);
  }

  static Future<CompanyAccount> _readProfile(String userId) async {
    final data = await BackendConfig.client
        .from('company_profiles')
        .select()
        .eq('id', userId)
        .single();
    return CompanyAccount.fromProfile(data);
  }

  static Future<void> updateProfile(CompanyAccount account) async {
    if (!isCloudEnabled) {
      await LocalAccountStore.updateProfile(account);
      return;
    }
    await BackendConfig.client
        .from('company_profiles')
        .update(account.toProfileJson())
        .eq('id', BackendConfig.client.auth.currentUser!.id);
  }

  static Future<void> sendPasswordReset(String email) async {
    if (!isCloudEnabled) {
      throw StateError('Configura Supabase para recuperar la contraseña.');
    }
    await BackendConfig.client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _emailRedirectUri,
    );
  }

  static Future<void> updatePassword(String password) async {
    await BackendConfig.client.auth.updateUser(
      UserAttributes(password: password),
    );
  }

  static Future<void> signOut() async {
    if (BackendConfig.isInitialized) await BackendConfig.client.auth.signOut();
  }

  static String get _emailRedirectUri =>
      kIsWeb ? Uri.base.origin : 'co.ecologismart.app://login-callback';
}
