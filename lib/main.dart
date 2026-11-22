import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/config/firebase_options.dart';
import 'core/layout/responsive_page.dart';
import 'services/auth_service.dart';
import 'services/legacy_credential_cleanup.dart';
import 'features/home/presentation/home_page.dart';
import 'features/auth/presentation/login_page.dart';

bool _firebaseInitialized = false;

bool getFirebaseInitialized() {
  return _firebaseInitialized;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LegacyCredentialCleanup.clear();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _firebaseInitialized = true;

    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    _firebaseInitialized = false;

    debugPrint('Firebase initialization error: $e');
  }

  runApp(const ChilliDiseaseApp());
}

class ChilliDiseaseApp extends StatelessWidget {
  const ChilliDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chilli Plant Disease Detection',
      builder: (context, child) => ResponsivePage(
        maxContentWidth: 1280,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  Widget build(BuildContext context) {
    if (!_firebaseInitialized) return const FirebaseUnavailablePage();
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user != null) {
          return HomePage(
            userName:
                user.displayName ?? user.email?.split('@').first ?? 'User',
          );
        }
        return const LoginPage();
      },
    );
  }
}

class FirebaseUnavailablePage extends StatelessWidget {
  const FirebaseUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Sign-in is unavailable',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  SizedBox(height: 8),
                  Text(
                      'Firebase could not be initialized. Check the platform Firebase configuration and restart the app.',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
}
