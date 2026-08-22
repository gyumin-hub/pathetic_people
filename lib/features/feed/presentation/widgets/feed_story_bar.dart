import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../domain/models/app_user.dart';

class FeedStoryBar extends StatelessWidget {
  const FeedStoryBar({
    required this.currentUser,
    required this.users,
    required this.onCurrentUserTap,
    required this.onUserTap,
    super.key,
  });

  final AppUser currentUser;
  final List<AppUser> users;
  final VoidCallback onCurrentUserTap;
  final ValueChanged<AppUser> onUserTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: users.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _StoryItem(
              label: '내 인증',
              avatar: Stack(
                clipBehavior: Clip.none,
                children: [
                  AppAvatar.user(currentUser, size: 56),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        color: AppPalette.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppPalette.background,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: onCurrentUserTap,
            );
          }

          final user = users[index - 1];
          final storyState = index.isEven
              ? StoryState.success
              : StoryState.failure;
          return _StoryItem(
            label: user.displayName,
            avatar: AppAvatar.user(user, size: 52, storyState: storyState),
            onTap: () => onUserTap(user),
          );
        },
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.label,
    required this.avatar,
    required this.onTap,
  });

  final String label;
  final Widget avatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label 오늘 상태 보기',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 64, height: 64, child: Center(child: avatar)),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.ink,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
