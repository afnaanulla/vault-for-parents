import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/vault_entry.dart';
import 'encryption_service.dart';

class StorageService {
  final SharedPreferences _prefs;

  /// True when the user is actively using the system camera or photo gallery picker.
  /// Used by app lifecycle observers to prevent auto-locking the vault mid-capture.
  static bool isPickingMedia = false;

  StorageService(this._prefs);

  static const String _keyLastUserId = 'secure_vault_last_user_id';

  // --- Last active user ---
  String? getLastActiveUserId() {
    return _prefs.getString(_keyLastUserId);
  }

  Future<void> setLastActiveUserId(String userId) async {
    await _prefs.setString(_keyLastUserId, userId);
  }

  // --- User Profile PIN & Biometrics Management ---
  String _pinKey(UserProfile profile) => '${profile.storagePrefix}pin_hash';
  String _bioKey(UserProfile profile) => '${profile.storagePrefix}bio_enabled';
  String _dataKey(UserProfile profile) => '${profile.storagePrefix}vault_data';

  bool isUserPinConfigured(UserProfile profile) {
    return _prefs.getString(_pinKey(profile)) != null;
  }

  Future<void> setUserPin(UserProfile profile, String plainPin) async {
    final hash = EncryptionService.hashPin(plainPin, profile.storagePrefix);
    await _prefs.setString(_pinKey(profile), hash);
  }

  bool verifyUserPin(UserProfile profile, String plainPin) {
    final storedHash = _prefs.getString(_pinKey(profile));
    if (storedHash == null) return false;
    return EncryptionService.verifyPin(plainPin, profile.storagePrefix, storedHash);
  }

  bool isBiometricEnabled(UserProfile profile) {
    return _prefs.getBool(_bioKey(profile)) ?? true;
  }

  Future<void> setBiometricEnabled(UserProfile profile, bool enabled) async {
    await _prefs.setBool(_bioKey(profile), enabled);
  }

  String? getBioToken(UserProfile profile) {
    return _prefs.getString('${profile.storagePrefix}bio_token');
  }

  Future<void> setBioToken(UserProfile profile, String token) async {
    await _prefs.setString('${profile.storagePrefix}bio_token', token);
  }

  // --- Encrypted Vault Entries Storage (Completely Isolated) ---

  /// Reads and decrypts all entries for a specific user using their secret PIN.
  /// If PIN is empty or wrong, decryption fails and empty list is returned.
  List<VaultEntry> loadUserEntries(UserProfile profile, String userPin) {
    final encryptedData = _prefs.getString(_dataKey(profile));
    if (encryptedData == null || encryptedData.isEmpty) {
      return [];
    }

    try {
      final decryptedJson = EncryptionService.decryptText(
        encryptedData,
        profile.storagePrefix,
        userPin,
      );

      if (decryptedJson.isEmpty) return [];

      final List<dynamic> list = json.decode(decryptedJson) as List<dynamic>;
      return list
          .map((item) => VaultEntry.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Encrypts and persists all entries for a specific user using their secret PIN.
  Future<bool> saveUserEntries(
    UserProfile profile,
    String userPin,
    List<VaultEntry> entries,
  ) async {
    try {
      final jsonString = json.encode(entries.map((e) => e.toMap()).toList());
      final encryptedData = EncryptionService.encryptText(
        jsonString,
        profile.storagePrefix,
        userPin,
      );
      return await _prefs.setString(_dataKey(profile), encryptedData);
    } catch (_) {
      return false;
    }
  }

  /// Returns count of entries without exposing or decrypting actual values
  int getEntryCount(UserProfile profile) {
    final encryptedData = _prefs.getString(_dataKey(profile));
    if (encryptedData == null || encryptedData.isEmpty) return 0;
    // Approximated non-decrypted indicator or count flag if needed
    return _prefs.getInt('${profile.storagePrefix}entry_count') ?? 0;
  }

  Future<void> updateEntryCount(UserProfile profile, int count) async {
    await _prefs.setInt('${profile.storagePrefix}entry_count', count);
  }

  /// Copies a captured or chosen photo into app's private sandbox (not in public gallery)
  Future<String> saveDocumentPhoto(UserProfile profile, String tempFilePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${appDir.path}/${profile.storagePrefix}documents');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }

    final ext = tempFilePath.contains('.')
        ? tempFilePath.substring(tempFilePath.lastIndexOf('.'))
        : '.jpg';
    final newFileName = 'doc_${const Uuid().v4()}$ext';
    final targetPath = '${docsDir.path}/$newFileName';

    final tempFile = File(tempFilePath);
    await tempFile.copy(targetPath);
    return targetPath;
  }

  /// Removes the private photo file when an entry is deleted
  Future<void> deleteDocumentPhoto(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
