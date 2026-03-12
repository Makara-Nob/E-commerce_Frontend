class AuthResponse {
  final String token;
  final UserData user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? json['accessToken'] ?? json['access_token'] ?? '',
      user: UserData.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}

class UserData {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String? phone;
  final String role;
  final bool active;
  final String? profileUrl;

  UserData({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.phone,
    required this.role,
    required this.active,
    this.profileUrl,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      phone: json['phone'],
      role: json['role'] ?? '',
      active: json['active'] ?? false,
      profileUrl: json['profileUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'active': active,
      'profileUrl': profileUrl,
    };
  }
}
