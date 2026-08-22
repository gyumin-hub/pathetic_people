class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.initials,
    required this.avatarSeed,
    required this.level,
    required this.bio,
    required this.followers,
    required this.following,
    required this.isFollowing,
  });

  final String id;
  final String username;
  final String displayName;
  final String initials;
  final int avatarSeed;
  final int level;
  final String bio;
  final int followers;
  final int following;
  final bool isFollowing;

  AppUser copyWith({
    String? username,
    String? displayName,
    String? bio,
    int? level,
    int? followers,
    int? following,
    bool? isFollowing,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      initials: initials,
      avatarSeed: avatarSeed,
      level: level ?? this.level,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
