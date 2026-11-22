import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/layout/responsive_page.dart';
import '../../../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    debugPrint('======================================');
    debugPrint('LOGIN BUTTON PRESSED');
    debugPrint('======================================');

    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    debugPrint('Password length: ${password.length}');

    if (email.isEmpty) {
      debugPrint('LOGIN VALIDATION ERROR: Email is empty.');

      setState(() {
        _errorMessage = 'Please enter your email.';
      });
      return;
    }
    if (!AuthService.isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Enter a valid email address.';
      });
      return;
    }

    // Password validation
    if (!RegExp(r'^\d{6}$').hasMatch(password)) {
      debugPrint(
        'LOGIN VALIDATION ERROR: Password must contain exactly 6 digits.',
      );

      setState(() {
        _errorMessage = 'Password must contain exactly 6 digits.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(email, password);

      debugPrint('======================================');
      debugPrint('FIREBASE LOGIN SUCCESS');
      debugPrint('Firebase UID: ${_authService.currentUser?.uid}');
      debugPrint(
        'Firebase currentUser: ${_authService.currentUser != null}',
      );
      debugPrint('======================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // AuthCheck listens to FirebaseAuth.authStateChanges and opens Home.
    } on FirebaseAuthException catch (e) {
      debugPrint('======================================');
      debugPrint('FIREBASE LOGIN ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('======================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        if (e.code == 'user-not-found') {
          _errorMessage = 'Account not found. Please register first.';
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          _errorMessage = 'Invalid email or password.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Enter a valid email address.';
        } else if (e.code == 'too-many-requests') {
          _errorMessage = 'Too many login attempts. Please try again later.';
        } else {
          _errorMessage = 'Firebase login failed. Please try again.';
        }
      });
    } catch (e) {
      debugPrint('======================================');
      debugPrint('LOGIN GENERAL ERROR');
      debugPrint('$e');
      debugPrint('======================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed. Please try again.';
      });
    }
  }

  void _openRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsivePage(
        maxContentWidth: 540,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 55),
                const Icon(Icons.eco, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to use the chilli disease detection system.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: '6-Digit Password',
                    hintText: 'Enter your 6-digit password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 25),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _openRegisterPage,
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Use the email address and 6-digit password you registered with.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
