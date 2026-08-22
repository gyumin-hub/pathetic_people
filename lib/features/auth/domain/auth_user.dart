class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.profileImage,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final nickname = json['nickname'];
    final profileImage = json['profileImage'];
    final role = json['role'];

    if (id is! int ||
        email is! String ||
        nickname is! String ||
        (profileImage != null && profileImage is! String) ||
        role is! String) {
      throw const FormatException('Invalid authenticated user response.');
    }

    return AuthUser(
      id: id,
      email: email,
      nickname: nickname,
      profileImage: profileImage as String?,
      role: role,
    );
  }

  final int id;
  final String email;
  final String nickname;
  final String? profileImage;
  final String role;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthUser &&
            id == other.id &&
            email == other.email &&
            nickname == other.nickname &&
            profileImage == other.profileImage &&
            role == other.role;
  }

  @override
  int get hashCode => Object.hash(id, email, nickname, profileImage, role);
}
