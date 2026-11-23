import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_options.dart';
import '../../services/auth_service.dart';
import '../../services/legacy_credential_cleanup.dart';

/// Immutable snapshot of the application's startup initialization state.
class AppInitializationResult {
  const AppInitializationResult({
    required this.firebaseInitialized,
    required this.initialUser,
  });

  final bool firebaseInitialized;
  final User? initialUser;
}

/// Runs required startup tasks (local cleanup, Firebase setup, and initial
/// authentication resolution) asynchronously while the splash screen renders.
class AppInitializer {
  const AppInitializer._();

  static const Duration _authResolutionTimeout = Duration(seconds: 5);

  static Future<AppInitializationResult> initialize({
    Future<void> Function()? cleanupLegacyCredentials,
    Future<void> Function()? initializeFirebase,
    Future<User?> Function()? resolveInitialUser,
  }) async {
    final cleanupFuture = _runCleanup(cleanupLegacyCredentials);
    final firebaseFuture = _initFirebase(initializeFirebase);

    // Run independent local configuration cleanup and Firebase initialization
    // concurrently so startup completes as quickly as possible.
    await cleanupFuture;
    final firebaseInitialized = await firebaseFuture;

    if (!firebaseInitialized) {
      return const AppInitializationResult(
        firebaseInitialized: false,
        initialUser: null,
      );
    }

    final initialUser = await _resolveUser(resolveInitialUser);
    return AppInitializationResult(
      firebaseInitialized: true,
      initialUser: initialUser,
    );
  }

  static Future<void> _runCleanup(
    Future<void> Function()? cleanupLegacyCredentials,
  ) async {
    try {
      await (cleanupLegacyCredentials ?? LegacyCredentialCleanup.clear)();
    } catch (error) {
      debugPrint('Startup local cleanup error: $error');
    }
  }

  static Future<bool> _initFirebase(
    Future<void> Function()? initializeFirebase,
  ) async {
    try {
      if (initializeFirebase != null) {
        await initializeFirebase();
      } else if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      debugPrint('Firebase initialized successfully.');
      return true;
    } catch (error) {
      debugPrint('Firebase initialization error: $error');
      return false;
    }
  }

  static Future<User?> _resolveUser(
    Future<User?> Function()? resolveInitialUser,
  ) async {
    if (resolveInitialUser != null) {
      try {
        return await resolveInitialUser();
      } catch (error) {
        debugPrint('Initial auth state resolution error: $error');
        return null;
      }
    }

    final authService = AuthService();
    try {
      return await authService.authStateChanges.first.timeout(
        _authResolutionTimeout,
        onTimeout: () => authService.currentUser,
      );
    } catch (error) {
      debugPrint('Initial auth state stream error: $error');
      return authService.currentUser;
    }
  }
}
