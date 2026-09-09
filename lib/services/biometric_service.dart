import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Flag indicating if system biometric prompt is currently active on screen
  static bool isAuthenticating = false;

  /// Checks if device has biometric hardware and capability
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks if any biometrics (fingerprint/face) are currently enrolled on device
  static Future<bool> hasEnrolledBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Authenticates for general app unlock
  static Future<bool> authenticateForUnlock({
    required String userName,
  }) async {
    if (isAuthenticating) return false;
    isAuthenticating = true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan fingerprint to unlock $userName\'s SecureVault',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    } finally {
      // Small buffer before resetting so lifecycle observer doesn't trigger immediately
      await Future.delayed(const Duration(milliseconds: 300));
      isAuthenticating = false;
    }
  }

  /// Authenticates specifically to reveal a sensitive PIN, CVV, or password
  static Future<bool> authenticateToRevealSecret({
    required String fieldName,
  }) async {
    if (isAuthenticating) return false;
    isAuthenticating = true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan fingerprint to view secret $fieldName',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      isAuthenticating = false;
    }
  }
}
