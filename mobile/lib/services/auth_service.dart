import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../models/user_role.dart';
import 'api_client.dart';

/// Maps raw backend/network error messages to user-friendly strings.
String _friendlyError(ApiException e) {
  if (e.statusCode == 0 || e.message == 'network_error') {
    return 'Unable to connect to the server. Please check that the backend is running.';
  }
  switch (e.statusCode) {
    case 401:
      return 'Your session has expired. Please sign in again.';
    case 403:
      return 'Access denied.';
    case 409:
      return 'An account with this email or phone already exists.';
    case 422:
      return e.message; // validation detail from backend is already readable
    case 500:
      return 'Something went wrong. Please try again.';
  }
  // Map specific backend detail strings
  final m = e.message.toLowerCase();
  if (m.contains('invalid credentials')) return 'Invalid email or password.';
  if (m.contains('email already')) return 'An account with this email already exists.';
  if (m.contains('phone') && m.contains('already')) {
    return 'An account with this phone number already exists.';
  }
  if (m.contains('not registered as')) return e.message;
  return e.message.isNotEmpty ? e.message : 'Something went wrong. Please try again.';
}

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _userIdKey = 'auth_user_id';
  static const _nameKey = 'auth_full_name';

  // ── Register ──────────────────────────────────────────────────────────────

  Future<AuthToken> register(RegisterRequest req) async {
    try {
      final json = await ApiClient.post('/auth/register', req.toJson());
      final token = AuthToken.fromJson(json);
      await _persist(token);
      return token;
    } on ApiException catch (e) {
      throw ApiException(e.statusCode, _friendlyError(e));
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<AuthToken> login(LoginRequest req) async {
    try {
      final json = await ApiClient.post('/auth/login', req.toJson());
      final token = AuthToken.fromJson(json);
      await _persist(token);
      return token;
    } on ApiException catch (e) {
      throw ApiException(e.statusCode, _friendlyError(e));
    }
  }

  // ── Current user (GET /auth/me) ───────────────────────────────────────────

  Future<UserProfile?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final json = await ApiClient.get('/auth/me', token: token);
      return UserProfile.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout(); // token invalid/expired — clear it
        return null;
      }
      return null;
    }
  }

  // ── Session check ─────────────────────────────────────────────────────────

  /// Returns the authenticated [UserRole] if a valid session exists,
  /// or null if unauthenticated.
  Future<UserRole?> checkSession() async {
    final profile = await getCurrentUser();
    return profile?.userRole;
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
  }

  // ── Token access ──────────────────────────────────────────────────────────

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _persist(AuthToken token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.accessToken);
    await prefs.setString(_roleKey, token.role);
    await prefs.setInt(_userIdKey, token.userId);
    await prefs.setString(_nameKey, token.fullName);
  }
}
