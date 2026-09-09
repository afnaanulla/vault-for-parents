import 'package:flutter_test/flutter_test.dart';
import 'package:secure_vault/models/user_profile.dart';
import 'package:secure_vault/models/vault_entry.dart';
import 'package:secure_vault/services/encryption_service.dart';

void main() {
  group('SecureVault Security & Isolation Tests', () {
    test('PIN hashing and verification works correctly', () {
      const pin = '4829';
      final fatherHash = EncryptionService.hashPin(pin, UserProfile.father.storagePrefix);
      final motherHash = EncryptionService.hashPin(pin, UserProfile.mother.storagePrefix);

      // Verify same PIN produces different hashes due to user salt isolation
      expect(fatherHash, isNot(equals(motherHash)));

      // Verify correct verification
      expect(
        EncryptionService.verifyPin(pin, UserProfile.father.storagePrefix, fatherHash),
        isTrue,
      );
      expect(
        EncryptionService.verifyPin('0000', UserProfile.father.storagePrefix, fatherHash),
        isFalse,
      );
    });

    test('Data is encrypted and decrypted with user PIN', () {
      const plainText = '{"account": "5010049281928", "pin": "9921"}';
      const userPin = '1234';

      final cipherText = EncryptionService.encryptText(
        plainText,
        UserProfile.father.storagePrefix,
        userPin,
      );

      // Ciphertext must be non-empty, Base64, and not equal to plain text
      expect(cipherText, isNotEmpty);
      expect(cipherText, isNot(equals(plainText)));

      // Decryption with correct PIN succeeds
      final decrypted = EncryptionService.decryptText(
        cipherText,
        UserProfile.father.storagePrefix,
        userPin,
      );
      expect(decrypted, equals(plainText));
    });

    test('Strict Multi-User Isolation: Mother cannot decrypt Father data', () {
      const fatherSecret = 'HDFC-SUPER-SECRET-PIN-1234';
      const fatherPin = '4321';
      const motherPin = '8765';

      final fatherEncrypted = EncryptionService.encryptText(
        fatherSecret,
        UserProfile.father.storagePrefix,
        fatherPin,
      );

      // Mother attempts to decrypt Father data using her prefix & PIN -> fails
      final motherAttempt = EncryptionService.decryptText(
        fatherEncrypted,
        UserProfile.mother.storagePrefix,
        motherPin,
      );

      // Decryption fails and does NOT reveal father's secret
      expect(motherAttempt, isNot(equals(fatherSecret)));
    });

    test('Fast in-memory search matches titles, banks, and field values', () {
      final entry = VaultEntry(
        id: 'test-1',
        category: EntryCategory.bankAccount,
        title: 'Salary Account',
        institution: 'HDFC Bank',
        fields: {
          'account_number': '501004829102',
          'ifsc_code': 'HDFC0001234',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(entry.matchesSearch('HDFC'), isTrue);
      expect(entry.matchesSearch('salary'), isTrue);
      expect(entry.matchesSearch('9102'), isTrue); // Last 4 digits match
      expect(entry.matchesSearch('ICICI'), isFalse);
    });
  });
}
