import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'backend_config.dart';

/// Client-side encryption for text chat. The backend stores only ciphertext.
/// A fresh X25519 ephemeral key is used for every recipient envelope.
class EndToEndChat {
  EndToEndChat._();

  static final _storage = FlutterSecureStorage();
  static final _x25519 = X25519();
  static final _ed25519 = Ed25519();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _aes = AesGcm.with256bits();

  static String _identityId() {
    final id = BackendConfig.client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Inicia sesión para usar el chat cifrado.');
    }
    return id;
  }

  static Future<({SimpleKeyPair agreement, SimpleKeyPair signing})>
  _identity() async {
    final id = _identityId();
    final agreementPrivate = await _readOrCreatePrivate(
      'ecologismart.chat.$id.x25519',
      _x25519,
    );
    final signingPrivate = await _readOrCreateSigningPrivate(
      'ecologismart.chat.$id.ed25519',
    );
    return (
      agreement: await _x25519.newKeyPairFromSeed(agreementPrivate),
      signing: await _ed25519.newKeyPairFromSeed(signingPrivate),
    );
  }

  static Future<List<int>> _readOrCreatePrivate(
    String key,
    KeyExchangeAlgorithm algorithm,
  ) async {
    final saved = await _storage.read(key: key);
    if (saved != null) return base64Decode(saved);
    final pair = await algorithm.newKeyPair();
    final pairData = await pair.extract() as SimpleKeyPairData;
    final bytes = pairData.bytes;
    await _storage.write(key: key, value: base64Encode(bytes));
    return bytes;
  }

  static Future<List<int>> _readOrCreateSigningPrivate(String key) async {
    final saved = await _storage.read(key: key);
    if (saved != null) return base64Decode(saved);
    final pair = await _ed25519.newKeyPair();
    final pairData = await pair.extract();
    final bytes = pairData.bytes;
    await _storage.write(key: key, value: base64Encode(bytes));
    return bytes;
  }

  static Future<void> ensureRegistered() async {
    if (!BackendConfig.isInitialized) return;
    final id = _identityId();
    final agreementPrivate = await _readOrCreatePrivate(
      'ecologismart.chat.$id.x25519',
      _x25519,
    );
    final signingPrivate = await _readOrCreateSigningPrivate(
      'ecologismart.chat.$id.ed25519',
    );
    final agreement = await _x25519.newKeyPairFromSeed(agreementPrivate);
    final signing = await _ed25519.newKeyPairFromSeed(signingPrivate);
    final agreementPublic = await agreement.extractPublicKey();
    final signingPublic = await signing.extractPublicKey();
    await BackendConfig.client.from('company_chat_keys').upsert({
      'company_id': id,
      'agreement_public_key': base64Encode(agreementPublic.bytes),
      'signing_public_key': base64Encode(signingPublic.bytes),
    }, onConflict: 'company_id');
  }

  static Future<Map<String, dynamic>> encryptForParticipants({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String plaintext,
  }) async {
    await ensureRegistered();
    final participants = [senderId, recipientId];
    final envelopes = <String, dynamic>{};
    for (final participantId in participants.toSet()) {
      final result = await _encryptEnvelope(
        conversationId: conversationId,
        senderId: senderId,
        recipientId: participantId,
        plaintext: plaintext,
      );
      envelopes[participantId] = result;
    }
    return {'version': 1, 'envelopes': envelopes};
  }

  static Future<Map<String, String>> _encryptEnvelope({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String plaintext,
  }) async {
    final identity = await _identity();
    final recipientRow = await BackendConfig.client
        .from('company_chat_keys')
        .select('agreement_public_key')
        .eq('company_id', recipientId)
        .maybeSingle();
    if (recipientRow == null) {
      throw StateError(
        'La otra empresa debe iniciar sesión en la app para activar su clave de chat.',
      );
    }
    final remotePublic = SimplePublicKey(
      base64Decode(recipientRow['agreement_public_key'] as String),
      type: KeyPairType.x25519,
    );
    final ephemeral = await _x25519.newKeyPair();
    final ephemeralPublic = await ephemeral.extractPublicKey();
    final shared = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: remotePublic,
    );
    final aad = utf8.encode('$conversationId|$senderId|$recipientId|v1');
    final secretKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: aad,
      info: utf8.encode('EcoLogiSmart private message'),
    );
    final nonce = _aes.newNonce();
    final box = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
      aad: aad,
    );
    final unsigned = <String, String>{
      'ephemeral_key': base64Encode(ephemeralPublic.bytes),
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    final canonical = _canonicalEnvelope(
      conversationId,
      senderId,
      recipientId,
      unsigned,
    );
    final signature = await _ed25519.sign(
      utf8.encode(canonical),
      keyPair: identity.signing,
    );
    return {...unsigned, 'signature': base64Encode(signature.bytes)};
  }

  static String _canonicalEnvelope(
    String conversationId,
    String senderId,
    String recipientId,
    Map<String, String> envelope,
  ) =>
      '$conversationId\n$senderId\n$recipientId\n'
      '${envelope['ephemeral_key']}\n${envelope['nonce']}\n'
      '${envelope['ciphertext']}\n${envelope['mac']}';

  static Future<String> decryptEnvelope({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required Map<String, dynamic> envelope,
  }) async {
    final identity = await _identity();
    final id = _identityId();
    final signingRow = await BackendConfig.client
        .from('company_chat_keys')
        .select('signing_public_key')
        .eq('company_id', senderId)
        .maybeSingle();
    if (signingRow == null) {
      throw StateError('No se encontró la clave pública de quien envió.');
    }
    final unsigned = <String, String>{
      'ephemeral_key': envelope['ephemeral_key'] as String,
      'nonce': envelope['nonce'] as String,
      'ciphertext': envelope['ciphertext'] as String,
      'mac': envelope['mac'] as String,
    };
    final signingPublic = SimplePublicKey(
      base64Decode(signingRow['signing_public_key'] as String),
      type: KeyPairType.ed25519,
    );
    final signature = Signature(
      base64Decode(envelope['signature'] as String),
      publicKey: signingPublic,
    );
    final valid = await _ed25519.verify(
      utf8.encode(
        _canonicalEnvelope(conversationId, senderId, recipientId, unsigned),
      ),
      signature: signature,
    );
    if (!valid) throw StateError('La firma del mensaje no es válida.');

    final ephemeralPublic = SimplePublicKey(
      base64Decode(unsigned['ephemeral_key']!),
      type: KeyPairType.x25519,
    );
    final shared = await _x25519.sharedSecretKey(
      keyPair: identity.agreement,
      remotePublicKey: ephemeralPublic,
    );
    final aad = utf8.encode('$conversationId|$senderId|$id|v1');
    final secretKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: aad,
      info: utf8.encode('EcoLogiSmart private message'),
    );
    final box = SecretBox(
      base64Decode(unsigned['ciphertext']!),
      nonce: base64Decode(unsigned['nonce']!),
      mac: Mac(base64Decode(unsigned['mac']!)),
    );
    final cleartext = await _aes.decrypt(box, secretKey: secretKey, aad: aad);
    return utf8.decode(cleartext);
  }
}
