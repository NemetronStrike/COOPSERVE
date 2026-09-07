import '../models/user_role.dart';

class RegisterRequest {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final UserRole role;
  final String? skills;
  final String? certifications;
  final String? cooperativeId;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.skills,
    this.certifications,
    this.cooperativeId,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.name,
        if (skills != null) 'skills': skills,
        if (certifications != null) 'certifications': certifications,
        if (cooperativeId != null) 'cooperative_id': cooperativeId,
      };
}

class LoginRequest {
  final String identifier;
  final String password;
  final UserRole role;

  const LoginRequest({
    required this.identifier,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
        'role': role.name,
      };
}

class AuthToken {
  final String accessToken;
  final String tokenType;
  final String role;
  final int userId;
  final String fullName;

  const AuthToken({
    required this.accessToken,
    required this.tokenType,
    required this.role,
    required this.userId,
    required this.fullName,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) => AuthToken(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String,
        role: json['role'] as String,
        userId: json['user_id'] as int,
        fullName: json['full_name'] as String,
      );
}

/// Maps GET /auth/me response. Never contains hashed_password.
class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        role: json['role'] as String,
        isActive: json['is_active'] as bool,
      );

  UserRole get userRole {
    switch (role) {
      case 'worker':
        return UserRole.worker;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }
}
