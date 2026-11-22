import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Removes plaintext credentials persisted by versions before Firebase Auth.
class LegacyCredentialCleanup {
  static Future<void> clear() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove('registered_username');
      await preferences.remove('registered_password');
      await preferences.remove('is_logged_in');
    } catch (error) {
      debugPrint('Legacy local credential cleanup failed: $error');
    }
  }
}
