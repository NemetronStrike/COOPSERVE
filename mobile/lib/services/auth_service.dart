import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import 'api_client.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _userIdKey = 'auth_user_id';
  static const _nameKey = 'auth_full_name';

  Future<AuthToken> register(RegisterRequest req) async {
    final json = await ApiClient.post('/auth/register', req.toJson());
    final token = AuthToken.fromJson(json);
    await _persist(token);
    return token;
  }

  Future<AuthToken> login(LoginRequest req) async {
    final json = await ApiClient.post('/auth/login', req.toJson());
    final token = AuthToken.fromJson(json);
    await _persist(token);
    return token;
  }

  Future<void> _persist(AuthToken token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.accessToken);
    await prefs.setString(_roleKey, token.role);
    await prefs.setInt(_userIdKey, token.userId);
    await prefs.setString(_nameKey, token.fullName);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
