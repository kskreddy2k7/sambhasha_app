import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Check if Biometrics supported
  Future<bool> isBiometricAvailable() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  // Authenticate User
  Future<bool> authenticate() async {
    try {
      if (!await isBiometricAvailable()) return true; // Fallback if no security set

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock Sambhasha',
      );



    } on PlatformException catch (e) {
      print("Lock Error: $e");
      return false;
    }
  }

  // Get/Set Lock Status
  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('app_lock_enabled') ?? false;
  }

  Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', enabled);
  }
}
