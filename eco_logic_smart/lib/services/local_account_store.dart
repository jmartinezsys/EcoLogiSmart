import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company_account.dart';

class LocalAccountStore {
  LocalAccountStore._();

  static const _accountsKey = 'ecologismart.localAccounts.v1';
  static const _iterations = 12000;

  static Future<bool> register({
    required CompanyAccount account,
    required String password,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final accounts = _readAccounts(preferences);
    final normalizedEmail = account.email.trim().toLowerCase();
    if (accounts.any((saved) => saved['email'] == normalizedEmail)) {
      return false;
    }

    final saltBytes = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    final salt = base64Encode(saltBytes);
    final passwordHash = _derivePasswordHash(password, saltBytes);
    accounts.add({
      ...account.copyWith(email: normalizedEmail).toJson(),
      'passwordSalt': salt,
      'passwordHash': passwordHash,
    });
    await preferences.setString(_accountsKey, jsonEncode(accounts));
    return true;
  }

  static Future<CompanyAccount?> authenticate({
    required String email,
    required String password,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final normalizedEmail = email.trim().toLowerCase();
    for (final saved in _readAccounts(preferences)) {
      if (saved['email'] != normalizedEmail) {
        continue;
      }
      final salt = base64Decode(saved['passwordSalt'] as String);
      final candidate = _derivePasswordHash(password, salt);
      if (!_constantTimeEquals(candidate, saved['passwordHash'] as String)) {
        return null;
      }
      return CompanyAccount.fromJson(saved);
    }
    return null;
  }

  static Future<void> updateProfile(CompanyAccount account) async {
    final preferences = await SharedPreferences.getInstance();
    final accounts = _readAccounts(preferences);
    final index = accounts.indexWhere(
      (saved) => saved['email'] == account.email.trim().toLowerCase(),
    );
    if (index < 0) return;
    accounts[index] = {
      ...accounts[index],
      ...account.copyWith(email: account.email.trim().toLowerCase()).toJson(),
    };
    await preferences.setString(_accountsKey, jsonEncode(accounts));
  }

  static List<Map<String, dynamic>> _readAccounts(
    SharedPreferences preferences,
  ) {
    final encoded = preferences.getString(_accountsKey);
    if (encoded == null || encoded.isEmpty) return [];
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  static String _derivePasswordHash(String password, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var block = Uint8List.fromList(hmac.convert([...salt, 0, 0, 0, 1]).bytes);
    final result = Uint8List.fromList(block);
    for (var round = 1; round < _iterations; round++) {
      block = Uint8List.fromList(hmac.convert(block).bytes);
      for (var index = 0; index < result.length; index++) {
        result[index] ^= block[index];
      }
    }
    return base64Encode(result);
  }

  static bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}
