class UserProfile {
  const UserProfile(
      {required this.uid, required this.username, this.email, this.createdAt});

  final String uid;
  final String username;
  final String? email;
  final DateTime? createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid']?.toString() ?? '',
        username: json['username']?.toString() ?? 'User',
        email: json['email']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}
