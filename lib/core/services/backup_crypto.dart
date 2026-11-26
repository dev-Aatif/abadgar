import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class BackupDecryptionException implements Exception {
  final String message;
  const BackupDecryptionException(this.message);

  @override
  String toString() => message;
}

/// Encrypts and decrypts local JSON backups using PBKDF2-HMAC-SHA256 + AES-256-GCM.
class BackupCrypto {
  BackupCrypto._();

  static const String formatId = 'abadgar_encrypted_backup';
  static const int formatVersion = 1;
  static const int defaultIterations = 100000;
  static const int _minIterations = 1000;
  static const int _maxIterations = 1000000;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _keyLength = 32;
  static const int _macBitLength = 128;

  static final Uint8List _aadBytes =
      Uint8List.fromList(utf8.encode('$formatId:v$formatVersion'));

  static bool isEncryptedEnvelope(String content) {
    try {
      final decoded = jsonDecode(content);
      return decoded is Map<String, dynamic> && decoded['format'] == formatId;
    } catch (_) {
      return false;
    }
  }

  static String encryptJson(
    String plainJson,
    String passphrase, {
    int iterations = defaultIterations,
  }) {
    if (passphrase.isEmpty) {
      throw ArgumentError('Passphrase cannot be empty');
    }
    if (iterations < _minIterations || iterations > _maxIterations) {
      throw ArgumentError('Unsupported PBKDF2 iteration count');
    }

    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final key = _deriveKey(passphrase, salt, iterations);

    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          true,
          AEADParameters(
            KeyParameter(key),
            _macBitLength,
            nonce,
            _aadBytes,
          ),
        );

      final input = Uint8List.fromList(utf8.encode(plainJson));
      final output = cipher.process(input);

      return jsonEncode({
        'format': formatId,
        'version': formatVersion,
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': iterations,
        'salt': base64Encode(salt),
        'cipher': 'AES-256-GCM',
        'nonce': base64Encode(nonce),
        'ciphertext': base64Encode(output),
      });
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  static String decryptJson(String envelopeJson, String passphrase) {
    if (passphrase.isEmpty) {
      throw const BackupDecryptionException('Passphrase is required');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(envelopeJson);
    } catch (_) {
      throw const BackupDecryptionException('Invalid backup file format');
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != formatId ||
        decoded['version'] != formatVersion ||
        decoded['cipher'] != 'AES-256-GCM') {
      throw const BackupDecryptionException(
          'Unsupported encrypted backup format');
    }

    final iterations = decoded['iterations'];
    if (iterations is! int ||
        iterations < _minIterations ||
        iterations > _maxIterations) {
      throw const BackupDecryptionException(
          'Invalid key derivation parameters');
    }

    final Uint8List salt;
    final Uint8List nonce;
    final Uint8List ciphertext;
    try {
      salt = base64Decode(decoded['salt'] as String);
      nonce = base64Decode(decoded['nonce'] as String);
      ciphertext = base64Decode(decoded['ciphertext'] as String);
    } catch (_) {
      throw const BackupDecryptionException(
          'Corrupted encrypted backup payload');
    }

    if (salt.length < 8 ||
        nonce.length != _nonceLength ||
        ciphertext.length < 16) {
      throw const BackupDecryptionException(
          'Corrupted encrypted backup payload');
    }

    final key = _deriveKey(passphrase, salt, iterations);
    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(key),
            _macBitLength,
            nonce,
            _aadBytes,
          ),
        );

      final plainBytes = cipher.process(ciphertext);
      return utf8.decode(plainBytes);
    } on InvalidCipherTextException {
      throw const BackupDecryptionException(
        'Incorrect passphrase or damaged backup file',
      );
    } on FormatException {
      throw const BackupDecryptionException('Corrupted backup encoding');
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  static Uint8List _deriveKey(
    String passphrase,
    Uint8List salt,
    int iterations,
  ) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, _keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(passphrase)));
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }
}
