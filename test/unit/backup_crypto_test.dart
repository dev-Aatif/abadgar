import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/core/services/backup_crypto.dart';

void main() {
  group('BackupCrypto AES-256-GCM', () {
    test('encrypts and decrypts JSON round-trip cleanly', () {
      const payload =
          '{"version":1,"seasons":[{"id":"s1","name":"Wheat 2026"}]}';
      final envelope = BackupCrypto.encryptJson(
        payload,
        'my-farm-secret',
        iterations: 1000,
      );

      expect(BackupCrypto.isEncryptedEnvelope(envelope), isTrue);
      expect(BackupCrypto.isEncryptedEnvelope(payload), isFalse);

      final decrypted = BackupCrypto.decryptJson(envelope, 'my-farm-secret');
      expect(decrypted, payload);
    });

    test('rejects wrong passphrase and tampered ciphertext', () {
      const payload = '{"version":1,"seasons":[]}';
      final envelope = BackupCrypto.encryptJson(
        payload,
        'correct-pass',
        iterations: 1000,
      );

      expect(
        () => BackupCrypto.decryptJson(envelope, 'wrong-pass'),
        throwsA(isA<BackupDecryptionException>()),
      );

      final map = jsonDecode(envelope) as Map<String, dynamic>;
      final rawCipher = base64Decode(map['ciphertext'] as String);
      rawCipher[0] = rawCipher[0] ^ 0xFF;
      map['ciphertext'] = base64Encode(rawCipher);

      expect(
        () => BackupCrypto.decryptJson(jsonEncode(map), 'correct-pass'),
        throwsA(isA<BackupDecryptionException>()),
      );
      final tamperedMap = jsonDecode(envelope) as Map<String, dynamic>;
      tamperedMap['kdf'] = 'NONE';
      expect(
        () => BackupCrypto.decryptJson(jsonEncode(tamperedMap), 'correct-pass'),
        throwsA(isA<BackupDecryptionException>()),
      );
    });
    test('encrypts and decrypts JSON round-trip asynchronously via isolate',
        () async {
      const payload =
          '{"version":1,"seasons":[{"id":"s1","name":"Rice 2026"}]}';
      final envelope = await BackupCrypto.encryptJsonAsync(
        payload,
        'async-farm-secret',
        iterations: 1000,
      );
      final decrypted =
          await BackupCrypto.decryptJsonAsync(envelope, 'async-farm-secret');
      expect(decrypted, payload);
    });
  });
}
