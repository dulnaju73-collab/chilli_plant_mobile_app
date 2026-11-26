import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:chilli_plant_health/core/network/api_client.dart';
import 'package:chilli_plant_health/core/startup/app_initializer.dart';
import 'package:chilli_plant_health/features/home/presentation/home_page.dart';
import 'package:chilli_plant_health/features/scanning/presentation/plant_scan_page.dart';
import 'package:chilli_plant_health/features/splash/presentation/splash_screen.dart';
import 'package:chilli_plant_health/features/splash/presentation/widgets/chilli_brand_logo.dart';
import 'package:chilli_plant_health/main.dart';
import 'package:chilli_plant_health/models/prediction.dart';
import 'package:chilli_plant_health/services/prediction_service.dart';

class _FakePredictionService extends PredictionService {
  _FakePredictionService(this._onAnalyze);

  final Future<Prediction> Function(File image) _onAnalyze;

  @override
  Future<Prediction> analyze(File image) => _onAnalyze(image);
}

class _FakeUser implements User {
  _FakeUser({this.displayName, this.email});

  @override
  final String? displayName;

  @override
  final String? email;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('home keeps the active user name visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomePage(userName: 'Maria')),
    );

    expect(find.text('Hello, Maria 👋'), findsOneWidget);
  });

  testWidgets(
    'home displays Chili Care section and switches only its description between English and Sinhala',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomePage(userName: 'Maria')),
      );

      expect(find.text('Hello, Maria 👋'), findsOneWidget);
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Chili Care'), findsOneWidget);
      expect(find.text('About Chili Plants'), findsOneWidget);
      expect(find.text('Common Diseases'), findsOneWidget);
      expect(find.text('White Spot'), findsOneWidget);
      expect(find.text('Nutrition Deficiency'), findsOneWidget);
      expect(find.text('Healthy Leaf'), findsOneWidget);
      expect(find.text('Cercospora Leaf Spot'), findsOneWidget);
      expect(find.text('Bacterial Wilt'), findsOneWidget);

      final toggle = find.byKey(const ValueKey('chili_care_language_toggle'));
      await tester.ensureVisible(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump(const Duration(milliseconds: 250));

      // Chili Care section switches to Sinhala while the rest of Home remains English.
      expect(find.text('මිරිස් වගාව'), findsOneWidget);
      expect(find.text('මිරිස් ශාකය පිළිබඳව'), findsOneWidget);
      expect(find.text('ප්‍රධාන මිරිස් රෝග'), findsOneWidget);
      expect(find.text('සුදු ලප (White Spot)'), findsOneWidget);
      expect(find.text('පෝෂක ඌනතාවය (Nutrition Deficiency)'), findsOneWidget);
      expect(find.text('නිරෝගී මිරිස් කොළ (Healthy Leaf)'), findsOneWidget);
      expect(
        find.text('සර්කොස්පෝරා පත්‍ර ලප රෝගය (Cercospora Leaf Spot)'),
        findsOneWidget,
      );
      expect(find.text('බැක්ටීරියා මැලවීමේ රෝගය (Bacterial Wilt)'), findsOneWidget);
      expect(find.text('Hello, Maria 👋'), findsOneWidget);
      expect(find.text('Quick Access'), findsOneWidget);

      // Tapping again returns Chili Care section to English.
      await tester.tap(toggle);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Chili Care'), findsOneWidget);
      expect(find.text('About Chili Plants'), findsOneWidget);
    },
  );

  testWidgets('splash screen displays brand logo, title, and tagline in light and dark themes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(ChilliBrandLogo), findsOneWidget);
    expect(find.text(SplashScreen.appName), findsOneWidget);
    expect(find.text(SplashScreen.tagline), findsOneWidget);

    final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(lightScaffold.backgroundColor, SplashPalette.light.background);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(darkScaffold.backgroundColor, SplashPalette.dark.background);
  });

  testWidgets(
    'startup gate waits for initialization and routes unauthenticated user to LoginPage',
    (WidgetTester tester) async {
      final initCompleter = Completer<AppInitializationResult>();
      final authStreamController = StreamController<User?>.broadcast();
      addTearDown(authStreamController.close);

      await tester.pumpWidget(
        ChilliDiseaseApp(
          initializationFuture: initCompleter.future,
          splashEntranceDuration: const Duration(milliseconds: 300),
          authStream: authStreamController.stream,
        ),
      );

      // Splash stays visible while background initialization is still running.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsNothing);

      // Once initialization resolves with no user, transition to LoginPage.
      initCompleter.complete(
        const AppInitializationResult(
          firebaseInitialized: true,
          initialUser: null,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    },
  );

  testWidgets(
    'startup gate routes authenticated user straight to HomePage without a loading spinner flash',
    (WidgetTester tester) async {
      final user = _FakeUser(displayName: 'Maria', email: 'maria@example.com');
      final authStreamController = StreamController<User?>.broadcast();
      addTearDown(authStreamController.close);

      await tester.pumpWidget(
        ChilliDiseaseApp(
          initializationFuture: Future.value(
            AppInitializationResult(
              firebaseInitialized: true,
              initialUser: user,
            ),
          ),
          splashEntranceDuration: const Duration(milliseconds: 250),
          authStream: authStreamController.stream,
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Hello, Maria 👋'), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    },
  );

  testWidgets(
    'startup gate routes to FirebaseUnavailablePage when Firebase initialization fails',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ChilliDiseaseApp(
          initializationFuture: Future.value(
            const AppInitializationResult(
              firebaseInitialized: false,
              initialUser: null,
            ),
          ),
          splashEntranceDuration: const Duration(milliseconds: 200),
        ),
      );

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sign-in is unavailable'), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    },
  );

  testWidgets(
    'plant scanner shows Try Again and Retake buttons after capture and runs both actions',
    (WidgetTester tester) async {
      final pickedSources = <ImageSource>[];
      var analyzeCalls = 0;

      final fakeService = _FakePredictionService((_) async {
        analyzeCalls++;
        if (analyzeCalls == 1) {
          throw const ApiException('Temporary network error.');
        }
        return Prediction(
          id: '$analyzeCalls',
          disease: analyzeCalls == 2 ? 'Healthy_Leaf' : 'Curl_Virus',
          confidence: 95.4,
          isHealthy: analyzeCalls == 2,
          createdAt: null,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: PlantScanPage(
            predictionService: fakeService,
            pickImageOverride: (source) async {
              pickedSources.add(source);
              return XFile('assets/branding/app_icon.png');
            },
          ),
        ),
      );

      expect(find.text('Try Again'), findsNothing);
      expect(find.text('Retake'), findsNothing);

      // Capture photo with camera -> first analysis fails.
      final takePhotoButton = find.text('Take Photo');
      await tester.ensureVisible(takePhotoButton);
      await tester.pump();
      await tester.tap(takePhotoButton);
      await tester.pumpAndSettle();

      expect(pickedSources, [ImageSource.camera]);
      expect(analyzeCalls, 1);
      expect(find.text('Temporary network error.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);

      // Try Again re-analyzes the captured image without reopening the camera.
      final tryAgainButton =
          find.byKey(const ValueKey('plant_scan_try_again_button'));
      await tester.ensureVisible(tryAgainButton);
      await tester.pump();
      await tester.tap(tryAgainButton);
      await tester.pumpAndSettle();

      expect(pickedSources.length, 1);
      expect(analyzeCalls, 2);
      expect(find.text('Plant Appears Healthy'), findsOneWidget);

      // Retake opens the camera again to capture a fresh photo.
      final retakeButton =
          find.byKey(const ValueKey('plant_scan_retake_button'));
      await tester.ensureVisible(retakeButton);
      await tester.pump();
      await tester.tap(retakeButton);
      await tester.pumpAndSettle();

      expect(pickedSources, [ImageSource.camera, ImageSource.camera]);
      expect(analyzeCalls, 3);
      expect(find.text('Curl Virus'), findsOneWidget);
    },
  );
}
