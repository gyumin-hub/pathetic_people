import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../domain/models/app_user.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.user,
    required this.postCount,
    required this.experiencePoint,
    required this.nextLevelPoint,
    required this.level,
    required this.levelProgress,
    required this.currentStreak,
    required this.onEditProfile,
    required this.onShareProfile,
    super.key,
  });

  final AppUser user;
  final int postCount;
  final int experiencePoint;
  final int nextLevelPoint;
  final int level;
  final double levelProgress;
  final int currentStreak;
  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final usesLargeTextLayout = textScale > 1.25;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final usesStackedLayout =
                  constraints.maxWidth < 300 || usesLargeTextLayout;
              final stats = Row(
                children: [
                  Expanded(
                    child: _ProfileNumber(
                      label: '게시물',
                      value: _compactNumber(postCount),
                    ),
                  ),
                  Expanded(
                    child: _ProfileNumber(
                      label: '팔로워',
                      value: _compactNumber(user.followers),
                    ),
                  ),
                  Expanded(
                    child: _ProfileNumber(
                      label: '팔로잉',
                      value: _compactNumber(user.following),
                    ),
                  ),
                ],
              );
              final avatar = AppAvatar.user(
                user,
                size: constraints.maxWidth < 340 ? 68 : 76,
                storyState: StoryState.success,
              );

              if (usesStackedLayout) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [avatar, const SizedBox(height: 16), stats],
                );
              }

              return Row(
                children: [
                  avatar,
                  SizedBox(width: constraints.maxWidth < 340 ? 16 : 24),
                  Expanded(child: stats),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.blueSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LV.$level',
                      style: const TextStyle(
                        color: AppPalette.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                user.bio,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 16),
              _ProfileActionButtons(
                usesStackedLayout: usesLargeTextLayout,
                onEditProfile: onEditProfile,
                onShareProfile: onShareProfile,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _LevelSummary(
                      experiencePoint: experiencePoint,
                      nextLevelPoint: nextLevelPoint,
                      currentStreak: currentStreak,
                      usesStackedLayout: usesLargeTextLayout,
                    ),
                    const SizedBox(height: 13),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: levelProgress.clamp(0.0, 1.0).toDouble(),
                        minHeight: 6,
                        backgroundColor: AppPalette.surfaceStrong,
                        valueColor: const AlwaysStoppedAnimation(
                          AppPalette.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _compactNumber(int value) {
    if (value >= 10000) {
      final compact = value / 10000;
      return '${compact.toStringAsFixed(compact % 1 == 0 ? 0 : 1)}만';
    }
    if (value >= 1000) {
      final compact = value / 1000;
      return '${compact.toStringAsFixed(compact % 1 == 0 ? 0 : 1)}천';
    }
    return '$value';
  }
}

class _ProfileActionButtons extends StatelessWidget {
  const _ProfileActionButtons({
    required this.usesStackedLayout,
    required this.onEditProfile,
    required this.onShareProfile,
  });

  final bool usesStackedLayout;
  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;

  @override
  Widget build(BuildContext context) {
    final editButton = _ProfileActionButton(
      label: '프로필 편집',
      onPressed: onEditProfile,
    );
    final shareButton = _ProfileActionButton(
      label: '프로필 공유',
      onPressed: onShareProfile,
    );

    if (usesStackedLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [editButton, const SizedBox(height: 8), shareButton],
      );
    }
    return Row(
      children: [
        Expanded(child: editButton),
        const SizedBox(width: 8),
        Expanded(child: shareButton),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.ink,
        side: const BorderSide(color: AppPalette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}

class _LevelSummary extends StatelessWidget {
  const _LevelSummary({
    required this.experiencePoint,
    required this.nextLevelPoint,
    required this.currentStreak,
    required this.usesStackedLayout,
  });

  final int experiencePoint;
  final int nextLevelPoint;
  final int currentStreak;
  final bool usesStackedLayout;

  @override
  Widget build(BuildContext context) {
    final experience = Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppPalette.blueSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.bolt_rounded,
            size: 20,
            color: AppPalette.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '다음 레벨까지 ${nextLevelPoint - experiencePoint} XP',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                '$experiencePoint / $nextLevelPoint XP',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
    final streak = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          color: AppPalette.red,
          size: 19,
        ),
        const SizedBox(width: 4),
        Text(
          '$currentStreak일',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppPalette.red),
        ),
      ],
    );

    if (usesStackedLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          experience,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: streak),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: experience),
        const SizedBox(width: 8),
        streak,
      ],
    );
  }
}

class _ProfileNumber extends StatelessWidget {
  const _ProfileNumber({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
