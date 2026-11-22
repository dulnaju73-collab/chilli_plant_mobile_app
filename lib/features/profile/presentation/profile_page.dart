import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.userName});

  final String userName;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  late Future<UserProfile> _profile;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _profile = _userService.getMe();
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await _authService.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not log out: $error')));
      setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth < 360 ? 16 : 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, size: 55, color: Colors.white)),
              const SizedBox(height: 15),
              FutureBuilder<UserProfile>(
                future: _profile,
                builder: (context, snapshot) => Column(
                  children: [
                    Text(snapshot.data?.username ?? widget.userName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    const Text('Registered User',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center),
                    if (snapshot.hasError)
                      TextButton(
                          onPressed: () =>
                              setState(() => _profile = _userService.getMe()),
                          child: const Text('Retry profile load')),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.green),
                    const SizedBox(width: 15),
                    Expanded(
                      child: FutureBuilder<UserProfile>(
                        future: _profile,
                        builder: (context, snapshot) => Text(
                            snapshot.data?.username ?? 'Username',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _loggingOut ? null : _logout,
                  icon: _loggingOut
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.logout),
                  label: Text(_loggingOut ? 'SIGNING OUT' : 'LOGOUT'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
