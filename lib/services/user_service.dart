import '../core/network/api_client.dart';
import '../models/user_profile.dart';

class UserService {
  UserService({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  Future<UserProfile> getMe() async =>
      UserProfile.fromJson(await _client.get('/users/me'));

  Future<UserProfile> updateUsername(String username) async =>
      UserProfile.fromJson(
          await _client.put('/users/me', {'username': username}));
}
