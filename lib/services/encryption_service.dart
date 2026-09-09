import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  EncryptionService._();

  // 16-byte fixed IV for AES CBC block mode
  static final enc.IV _iv = enc.IV.fromUtf8('SecureVaultIv128');

  /// Hashes a 4-digit PIN with a user-specific salt for secure verification
  static String hashPin(String pin, String userPrefix) {
    final salted = '$userPrefix-JupiterVaultSalt2026-$pin';
    final bytes = utf8.encode(salted);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if provided plain PIN matches the stored SHA-256 hash
  static bool verifyPin(String plainPin, String userPrefix, String storedHash) {
    final computed = hashPin(plainPin, userPrefix);
    return computed == storedHash;
  }

  /// Generates a 32-byte (256-bit) AES key from user prefix and secret
  static enc.Key _deriveKey(String userPrefix, String userPin) {
    final rawKeyMaterial = 'SecureVaultKey-$userPrefix-$userPin-AES256MasterSeed';
    final hashBytes = sha256.convert(utf8.encode(rawKeyMaterial)).bytes;
    return enc.Key(Uint8List.fromList(hashBytes));
  }

  /// Encrypts plain text string to Base64 ciphertext
  static String encryptText(String plainText, String userPrefix, String userPin) {
    if (plainText.isEmpty) return '';
    final key = _deriveKey(userPrefix, userPin);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts Base64 ciphertext back to plain text
  static String decryptText(String cipherBase64, String userPrefix, String userPin) {
    if (cipherBase64.isEmpty) return '';
    try {
      final key = _deriveKey(userPrefix, userPin);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = enc.Encrypted.fromBase64(cipherBase64);
      return encrypter.decrypt(encrypted, iv: _iv);
    } catch (_) {
      return '';
    }
  }
}
