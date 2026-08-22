import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/media_artwork.dart';
import '../../../domain/models/app_preferences.dart';
import '../../../domain/models/feed_post.dart';
import '../view_models/profile_view_model.dart';
import 'widgets/profile_content_tabs.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_media_grid.dart';
import 'widgets/profile_stats_view.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.viewModel,
    required this.onOpenPlanner,
    required this.onOpenExplore,
    required this.onLogout,
    super.key,
  });

  final ProfileViewModel viewModel;
  final VoidCallback onOpenPlanner;
  final VoidCallback onOpenExplore;
  final Future<void> Function() onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  _HarshnessLevel get _harshnessLevel {
    return switch (widget.viewModel.preferences.mentorIntensity) {
      MentorIntensity.mild => _HarshnessLevel.mild,
      MentorIntensity.spicy => _HarshnessLevel.spicy,
      MentorIntensity.extreme => _HarshnessLevel.extreme,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, _) {
          final viewModel = widget.viewModel;
          final user = viewModel.user;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(
                  user.username,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                actions: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        tooltip: '알림',
                        onPressed: _showNotifications,
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                      if (viewModel.preferences.pushEnabled)
                        const Positioned(
                          top: 11,
                          right: 10,
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: AppPalette.red,
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    tooltip: '설정',
                    onPressed: _showSettings,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverToBoxAdapter(
                child: ProfileHeader(
                  user: user,
                  postCount: viewModel.postCount,
                  experiencePoint: viewModel.experiencePoint,
                  nextLevelPoint: viewModel.nextLevelPoint,
                  level: viewModel.level,
                  levelProgress: viewModel.levelProgress,
                  currentStreak: viewModel.currentStreak,
                  onEditProfile: _showEditProfile,
                  onShareProfile: _shareProfile,
                ),
              ),
              SliverToBoxAdapter(
                child: ProfileContentTabs(
                  selectedContent: viewModel.content,
                  onSelected: viewModel.selectContent,
                ),
              ),
              ..._contentSlivers(viewModel),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _contentSlivers(ProfileViewModel viewModel) {
    return switch (viewModel.content) {
      ProfileContent.posts => [
        ProfileMediaGrid(
          posts: viewModel.posts,
          onPostTap: _showPostDetail,
          emptyTitle: '아직 게시물이 없어요',
          emptyDescription: '계획을 인증하면 성공과 실패 기록이\n내 프로필에 차곡차곡 쌓여요.',
        ),
      ],
      ProfileContent.stats => [
        SliverToBoxAdapter(
          child: ProfileStatsView(
            monthlySuccessRate: viewModel.monthlySuccessRate,
            failureCount: viewModel.failureCount,
            currentStreak: viewModel.currentStreak,
            bestStreak: viewModel.bestStreak,
            recentDays: viewModel.recentDays,
          ),
        ),
      ],
      ProfileContent.saved => [
        ProfileMediaGrid(
          posts: viewModel.savedPosts,
          onPostTap: _showPostDetail,
          emptyTitle: '저장한 게시물이 없어요',
          emptyDescription: '다시 보고 싶은 인증 게시물의\n북마크 아이콘을 눌러 보세요.',
          emptyIcon: Icons.bookmark_border_rounded,
        ),
      ],
    };
  }

  Future<void> _showEditProfile() async {
    final user = widget.viewModel.user;
    final nameController = TextEditingController(text: user.displayName);
    final usernameController = TextEditingController(text: user.username);
    final bioController = TextEditingController(text: user.bio);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '프로필 편집',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: const Text('완료'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _EditField(
                  label: '이름',
                  controller: nameController,
                  maxLength: 20,
                ),
                const SizedBox(height: 14),
                _EditField(
                  label: '사용자 이름',
                  controller: usernameController,
                  maxLength: 24,
                ),
                const SizedBox(height: 14),
                _EditField(
                  label: '소개',
                  controller: bioController,
                  maxLength: 100,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        );
      },
    );

    final displayName = nameController.text;
    final username = usernameController.text;
    final bio = bioController.text;
    nameController.dispose();
    usernameController.dispose();
    bioController.dispose();
    if (!mounted || saved != true) return;
    widget.viewModel.updateProfile(
      displayName: displayName,
      username: username,
      bio: bio,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('프로필을 저장했어요.')));
  }

  Future<void> _shareProfile() async {
    final username = widget.viewModel.user.username;
    await Clipboard.setData(
      ClipboardData(text: 'https://pathetic.people/@$username'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('프로필 링크를 복사했어요.')));
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Text(
                  '알림',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _NotificationTile(
                      icon: Icons.campaign_rounded,
                      iconColor: AppPalette.red,
                      backgroundColor: AppPalette.redSoft,
                      title: '독설가 멘토가 할 말이 있대요',
                      description: _harshnessLevel.reminderMessage,
                      time: '방금',
                      onTap: () => _closeSheetWithNotice(
                        sheetContext,
                        '',
                        afterClose: widget.onOpenPlanner,
                      ),
                    ),
                    _NotificationTile(
                      icon: Icons.favorite_rounded,
                      iconColor: AppPalette.blue,
                      backgroundColor: AppPalette.blueSoft,
                      title: '김민지님이 회원님의 인증을 좋아합니다',
                      description: '퇴근 후 운동 60분',
                      time: '18분 전',
                      onTap: () => _closeSheetWithNotice(
                        sheetContext,
                        '',
                        afterClose: _openLatestPost,
                      ),
                    ),
                    _NotificationTile(
                      icon: Icons.person_add_alt_1_rounded,
                      iconColor: AppPalette.ink,
                      backgroundColor: AppPalette.surfaceStrong,
                      title: '한서윤님이 회원님을 팔로우합니다',
                      description: '퇴근 후 90분 공부를 실천 중인 사용자예요.',
                      time: '2시간 전',
                      onTap: () => _closeSheetWithNotice(
                        sheetContext,
                        '',
                        afterClose: widget.onOpenExplore,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      '설정',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      children: [
                        const _SettingsSectionLabel(label: '알림 및 공개 범위'),
                        _SettingsSwitchTile(
                          title: '푸시 알림',
                          description: '완료 인증 시간과 소셜 활동 알림',
                          value: widget.viewModel.preferences.pushEnabled,
                          onChanged: (value) {
                            widget.viewModel.updatePreferences(
                              pushEnabled: value,
                            );
                            setSheetState(() {});
                          },
                        ),
                        _SettingsSwitchTile(
                          title: '실패 기록 공개',
                          description: '실패 독설을 팔로워 피드에 공개',
                          value:
                              widget.viewModel.preferences.publicFailureEnabled,
                          onChanged: (value) {
                            widget.viewModel.updatePreferences(
                              publicFailureEnabled: value,
                            );
                            setSheetState(() {});
                          },
                        ),
                        _SettingsSwitchTile(
                          title: '단체방 실패 알림',
                          description: '친구 채팅방에 실패 내용을 전송',
                          value: widget
                              .viewModel
                              .preferences
                              .systemChatAlertEnabled,
                          onChanged: (value) {
                            widget.viewModel.updatePreferences(
                              systemChatAlertEnabled: value,
                            );
                            setSheetState(() {});
                          },
                        ),
                        const SizedBox(height: 20),
                        const _SettingsSectionLabel(label: '계정'),
                        _SettingsNavigationTile(
                          icon: Icons.shield_outlined,
                          title: '개인정보 및 보안',
                          onTap: () => _closeSheetWithNotice(
                            sheetContext,
                            '현재 데모 데이터는 앱 메모리에만 저장되고 재실행 시 초기화돼요.',
                          ),
                        ),
                        _SettingsNavigationTile(
                          icon: Icons.tune_rounded,
                          title: '독설 강도 설정',
                          subtitle: _harshnessLevel.label,
                          onTap: () async {
                            final selected = await _showHarshnessDialog(
                              sheetContext,
                            );
                            if (selected == null || !sheetContext.mounted) {
                              return;
                            }
                            widget.viewModel.updatePreferences(
                              mentorIntensity: selected.mentorIntensity,
                            );
                            setSheetState(() {});
                          },
                        ),
                        _SettingsNavigationTile(
                          icon: Icons.help_outline_rounded,
                          title: '도움말',
                          onTap: () => _closeSheetWithNotice(
                            sheetContext,
                            '계획을 등록하고 완료 인증을 남기세요. 정해둔 시간이 지나면 실패 기록과 독설이 자동 생성돼요.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SettingsNavigationTile(
                          icon: Icons.logout_rounded,
                          title: '로그아웃',
                          onTap: () => _confirmLogout(sheetContext),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext sheetContext) async {
    final shouldLogout = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃할까요?'),
          content: const Text('이 기기에 저장된 로그인 정보가 삭제됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !sheetContext.mounted) {
      return;
    }
    Navigator.of(sheetContext).pop();
    await widget.onLogout();
  }

  Future<_HarshnessLevel?> _showHarshnessDialog(BuildContext sheetContext) {
    return showDialog<_HarshnessLevel>(
      context: sheetContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('독설 강도'),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _HarshnessLevel.values
                .map((level) {
                  final isSelected = level == _harshnessLevel;
                  return ListTile(
                    onTap: () => Navigator.of(dialogContext).pop(level),
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppPalette.blue : AppPalette.muted,
                    ),
                    title: Text(
                      level.label,
                      style: Theme.of(dialogContext).textTheme.titleMedium,
                    ),
                    subtitle: Text(level.description),
                  );
                })
                .toList(growable: false),
          ),
        );
      },
    );
  }

  void _showPostDetail(FeedPost post) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isSuccess = post.outcome == PostOutcome.success;
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              MediaArtwork(
                kind: post.mediaKind,
                headline: post.mediaHeadline,
                outcome: post.outcome,
                label: isSuccess ? 'SUCCESS' : 'FAILED',
                aspectRatio: 4 / 5,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSuccess
                                ? AppPalette.blueSoft
                                : AppPalette.redSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSuccess ? '계획 성공' : '계획 실패',
                            style: TextStyle(
                              color: isSuccess
                                  ? AppPalette.blue
                                  : AppPalette.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          AppDateUtils.relativeTime(post.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      post.planTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? AppPalette.blueSoft
                            : AppPalette.redSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        post.mentorMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '좋아요 ${post.likes} · 댓글 ${post.comments.length}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _closeSheetWithNotice(
    BuildContext sheetContext,
    String message, {
    VoidCallback? afterClose,
  }) {
    Navigator.of(sheetContext).pop();
    afterClose?.call();
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openLatestPost() {
    final posts = widget.viewModel.posts;
    if (posts.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showPostDetail(posts.first);
    });
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    required this.maxLength,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.description,
    required this.time,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String description;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: backgroundColor,
        foregroundColor: iconColor,
        child: Icon(icon, size: 20),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      trailing: Text(time, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppPalette.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SettingsNavigationTile extends StatelessWidget {
  const _SettingsNavigationTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppPalette.muted,
      ),
    );
  }
}

enum _HarshnessLevel { mild, spicy, extreme }

extension on _HarshnessLevel {
  MentorIntensity get mentorIntensity {
    return switch (this) {
      _HarshnessLevel.mild => MentorIntensity.mild,
      _HarshnessLevel.spicy => MentorIntensity.spicy,
      _HarshnessLevel.extreme => MentorIntensity.extreme,
    };
  }

  String get label {
    return switch (this) {
      _HarshnessLevel.mild => '순한맛',
      _HarshnessLevel.spicy => '매운맛',
      _HarshnessLevel.extreme => '극한맛',
    };
  }

  String get description {
    return switch (this) {
      _HarshnessLevel.mild => '부담 없이 행동을 다시 권해요.',
      _HarshnessLevel.spicy => '핑계를 짚고 단호하게 재촉해요.',
      _HarshnessLevel.extreme => '돌려 말하지 않고 결과로 압박해요.',
    };
  }

  String get reminderMessage {
    return switch (this) {
      _HarshnessLevel.mild => '오늘 회고 계획이 3시간 남았어요. 지금 시작해 볼까요?',
      _HarshnessLevel.spicy => '오늘 회고 계획이 3시간 남았어요. 또 미룰 건 아니죠?',
      _HarshnessLevel.extreme => '3시간 남았습니다. 이번에도 안 하면 계획이 아니라 희망사항이에요.',
    };
  }
}
