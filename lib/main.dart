import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/layout/responsive_page.dart';
import 'core/startup/app_initializer.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'services/auth_service.dart';

bool _firebaseInitialized = false;

bool getFirebaseInitialized() {
  return _firebaseInitialized;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final initializationFuture = AppInitializer.initialize().then((result) {
    _firebaseInitialized = result.firebaseInitialized;
    return result;
  });
  runApp(ChilliDiseaseApp(initializationFuture: initializationFuture));
}

class ChilliDiseaseApp extends StatelessWidget {
  const ChilliDiseaseApp({
    super.key,
    this.initializationFuture,
    this.splashEntranceDuration = const Duration(milliseconds: 1200),
    this.authStream,
  });

  /// Pre-started startup initialization future created in [main] so background
  /// tasks run concurrently with the first rendered splash frame.
  final Future<AppInitializationResult>? initializationFuture;

  /// Duration of the splash screen entrance choreography.
  final Duration splashEntranceDuration;

  /// Optional auth stream override for testing.
  final Stream<User?>? authStream;

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
      home: AppStartupGate(
        initializationFuture: initializationFuture,
        splashEntranceDuration: splashEntranceDuration,
        authStream: authStream,
      ),
    );
  }
}

/// Hosts the animated splash screen while startup initialization resolves,
/// then smoothly cross-fades directly into the auth-driven root screen on the
/// first Navigator route (preventing back-navigation to the splash and keeping
/// `popUntil((r) => r.isFirst)` flows intact).
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({
    super.key,
    this.initializationFuture,
    this.splashEntranceDuration = const Duration(milliseconds: 1200),
    this.authStream,
  });

  final Future<AppInitializationResult>? initializationFuture;
  final Duration splashEntranceDuration;
  final Stream<User?>? authStream;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exitController;
  late final Animation<double> _splashOpacity;
  late final Animation<double> _splashScale;
  late final Animation<double> _destinationOpacity;
  late final Animation<double> _destinationScale;

  AppInitializationResult? _initResult;
  bool _entranceComplete = false;
  bool _transitionStarted = false;
  bool _splashMounted = true;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener(_handleExitStatus);

    _splashOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.0, 0.82, curve: Curves.easeInCubic),
      ),
    );
    _splashScale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeOutCubic,
      ),
    );
    _destinationOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.14, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _destinationScale = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeOutCubic,
      ),
    );

    final future = widget.initializationFuture ?? AppInitializer.initialize();
    future.then(
      (result) {
        if (!mounted) return;
        _firebaseInitialized = result.firebaseInitialized;
        _initResult = result;
        _maybeStartTransition();
      },
      onError: (Object error) {
        debugPrint('Unexpected startup initialization error: $error');
        if (!mounted) return;
        _firebaseInitialized = false;
        _initResult = const AppInitializationResult(
          firebaseInitialized: false,
          initialUser: null,
        );
        _maybeStartTransition();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
  }

  void _handleEntranceComplete() {
    _entranceComplete = true;
    _maybeStartTransition();
  }

  void _maybeStartTransition() {
    if (_transitionStarted || !_entranceComplete || _initResult == null) {
      return;
    }
    if (!mounted) return;

    _transitionStarted = true;
    if (_disableAnimations) {
      _exitController.value = 1.0;
      setState(() {
        _splashMounted = false;
      });
      return;
    }

    setState(() {});
    _exitController.forward();
  }

  void _handleExitStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && _splashMounted) {
      setState(() {
        _splashMounted = false;
      });
    }
  }

  @override
  void dispose() {
    _exitController.removeStatusListener(_handleExitStatus);
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _initResult;
    final showDestination = _transitionStarted && result != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showDestination)
          FadeTransition(
            opacity: _destinationOpacity,
            child: ScaleTransition(
              scale: _destinationScale,
              child: KeyedSubtree(
                key: const ValueKey('app_root_destination'),
                child: AuthCheck(
                  firebaseInitialized: result.firebaseInitialized,
                  initialUser: result.initialUser,
                  hasInitialUser: true,
                  authStream: widget.authStream,
                ),
              ),
            ),
          ),
        if (_splashMounted)
          IgnorePointer(
            ignoring: _transitionStarted,
            child: FadeTransition(
              opacity: _splashOpacity,
              child: ScaleTransition(
                scale: _splashScale,
                child: SplashScreen(
                  entranceDuration: widget.splashEntranceDuration,
                  onEntranceComplete: _handleEntranceComplete,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({
    super.key,
    this.firebaseInitialized,
    this.initialUser,
    this.hasInitialUser = false,
    this.authStream,
  });

  final bool? firebaseInitialized;
  final User? initialUser;
  final bool hasInitialUser;
  final Stream<User?>? authStream;

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  Stream<User?>? _authStream;

  bool get _isFirebaseReady =>
      widget.firebaseInitialized ?? _firebaseInitialized;

  @override
  void initState() {
    super.initState();
    if (_isFirebaseReady) {
      _authStream = widget.authStream ?? AuthService().authStateChanges;
    }
  }

  @override
  void didUpdateWidget(covariant AuthCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isFirebaseReady &&
        (_authStream == null || oldWidget.authStream != widget.authStream)) {
      _authStream = widget.authStream ?? AuthService().authStateChanges;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFirebaseReady) return const FirebaseUnavailablePage();

    return StreamBuilder<User?>(
      stream: _authStream,
      initialData: widget.initialUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !widget.hasInitialUser) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.connectionState == ConnectionState.waiting
            ? widget.initialUser
            : snapshot.data;

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
                  Text(
                    'Sign-in is unavailable',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Firebase could not be initialized. Check the platform Firebase configuration and restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
