import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';

enum AuthStatus {
  unselected,   // No user chosen yet
  pinRequired,  // Profile chosen, needs PIN setup
  locked,       // Profile chosen, ready for Biometric or PIN
  authenticated // Logged in, vault accessible
}

class AuthProvider extends ChangeNotifier {
  final StorageService _storageService;

  UserProfile? _currentUser;
  AuthStatus _status = AuthStatus.unselected;
  String _activeSessionPin = ''; // Memory-only session key, flushed on lock
  bool _isBiometricSupported = false;
  String? _authError;

  AuthProvider(this._storageService) {
    _initBiometrics();
    _checkLastActiveUser();
  }

  UserProfile? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _activeSessionPin.isNotEmpty;
  String get activeSessionPin => _activeSessionPin;
  bool get isBiometricSupported => _isBiometricSupported;
  String? get authError => _authError;
  StorageService get storageService => _storageService;

  Future<void> _initBiometrics() async {
    _isBiometricSupported = await BiometricService.isBiometricAvailable();
    notifyListeners();
  }

  void _checkLastActiveUser() {
    final lastId = _storageService.getLastActiveUserId();
    if (lastId != null) {
      final profile = UserProfile.fromId(lastId);
      selectProfile(profile, autoPromptBiometric: false);
    }
  }

  /// Selects active profile (Father or Mother)
  void selectProfile(UserProfile profile, {bool autoPromptBiometric = true}) {
    _currentUser = profile;
    _activeSessionPin = '';
    _authError = null;

    final isPinSet = _storageService.isUserPinConfigured(profile);
    if (!isPinSet) {
      _status = AuthStatus.pinRequired;
    } else {
      _status = AuthStatus.locked;
    }
    notifyListeners();

    if (autoPromptBiometric && _status == AuthStatus.locked) {
      attemptBiometricUnlock();
    }
  }

  /// Deselects profile and returns to User Selection screen
  void switchUser() {
    lockVault();
    _currentUser = null;
    _status = AuthStatus.unselected;
    notifyListeners();
  }

  /// First time setup of 4-digit PIN for the selected user
  Future<bool> setupPin(String newPin) async {
    if (_currentUser == null || newPin.length != 4) return false;

    await _storageService.setUserPin(_currentUser!, newPin);
    await _storageService.setLastActiveUserId(_currentUser!.id);
    await _storageService.setBioToken(_currentUser!, newPin);
    _activeSessionPin = newPin;
    _status = AuthStatus.authenticated;
    _authError = null;
    notifyListeners();
    return true;
  }

  /// Unlocks using 4-digit PIN
  bool unlockWithPin(String enteredPin) {
    if (_currentUser == null) return false;

    final isValid = _storageService.verifyUserPin(_currentUser!, enteredPin);
    if (isValid) {
      _activeSessionPin = enteredPin;
      _status = AuthStatus.authenticated;
      _storageService.setLastActiveUserId(_currentUser!.id);
      _storageService.setBioToken(_currentUser!, enteredPin);
      _authError = null;
      notifyListeners();
      return true;
    } else {
      _authError = 'Incorrect PIN. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Unlocks using Biometrics (Fingerprint)
  Future<bool> attemptBiometricUnlock() async {
    if (_currentUser == null || _status != AuthStatus.locked) return false;

    final bioEnabled = _storageService.isBiometricEnabled(_currentUser!);
    if (!bioEnabled || !_isBiometricSupported) return false;

    final success = await BiometricService.authenticateForUnlock(
      userName: _currentUser!.displayName,
    );

    if (success) {
      final storedPin = _storageService.getBioToken(_currentUser!);
      if (storedPin != null && storedPin.isNotEmpty) {
        _activeSessionPin = storedPin;
        _status = AuthStatus.authenticated;
        _authError = null;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Flushes all decrypted data and memory on lock
  void lockVault() {
    _activeSessionPin = '';
    if (_currentUser != null && _storageService.isUserPinConfigured(_currentUser!)) {
      _status = AuthStatus.locked;
    } else {
      _status = AuthStatus.unselected;
    }
    _authError = null;
    notifyListeners();
  }

  void clearError() {
    _authError = null;
    notifyListeners();
  }
}
