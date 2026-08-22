import 'package:flutter/material.dart';

import '../../domain/models/app_user.dart';
import '../theme/app_palette.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.initials,
    required this.seed,
    this.size = 44,
    this.storyState,
    super.key,
  });

  factory AppAvatar.user(
    AppUser user, {
    double size = 44,
    StoryState? storyState,
    Key? key,
  }) {
    return AppAvatar(
      initials: user.initials,
      seed: user.avatarSeed,
      size: size,
      storyState: storyState,
      key: key,
    );
  }

  final String initials;
  final int seed;
  final double size;
  final StoryState? storyState;

  static const _gradients = [
    [Color(0xFF53606E), Color(0xFF1E252D)],
    [Color(0xFFBDC6D0), Color(0xFF555F6A)],
    [Color(0xFF4B6380), Color(0xFF182535)],
    [Color(0xFFA8A2A0), Color(0xFF514B4A)],
    [Color(0xFF8291A0), Color(0xFF303A45)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[seed.abs() % _gradients.length];
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );

    if (storyState == null) return avatar;
    final ringColors = storyState == StoryState.failure
        ? const [Color(0xFFF6A13B), AppPalette.red, Color(0xFFA855F7)]
        : const [AppPalette.blue, Color(0xFF8B5CF6), AppPalette.blue];
    return Container(
      width: size + 8,
      height: size + 8,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: ringColors),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppPalette.background,
        ),
        child: avatar,
      ),
    );
  }
}

enum StoryState { success, failure }
