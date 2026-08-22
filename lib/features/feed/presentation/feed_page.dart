import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/feed_post.dart';
import '../view_models/feed_view_model.dart';
import 'widgets/comments_sheet.dart';
import 'widgets/feed_post_card.dart';
import 'widgets/feed_story_bar.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({
    required this.viewModel,
    required this.onOpenPlanner,
    required this.onOpenProfile,
    super.key,
  });

  final FeedViewModel viewModel;
  final VoidCallback onOpenPlanner;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final posts = viewModel.posts;
            return CustomScrollView(
              key: PageStorageKey<String>('feed-${viewModel.scope.name}'),
              slivers: [
                SliverToBoxAdapter(
                  child: _FeedHeader(
                    onCreatePost: onOpenPlanner,
                    onNotifications: onOpenProfile,
                  ),
                ),
                SliverToBoxAdapter(
                  child: FeedStoryBar(
                    currentUser: viewModel.currentUser,
                    users: viewModel.storyUsers,
                    onCurrentUserTap: onOpenPlanner,
                    onUserTap: (user) => _showStory(context, user),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FeedScopeTabs(
                    scope: viewModel.scope,
                    onChanged: viewModel.changeScope,
                  ),
                ),
                if (posts.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyFeed(),
                  )
                else
                  SliverList.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final author = viewModel.authorOf(post);
                      if (author == null) return const SizedBox.shrink();
                      return FeedPostCard(
                        key: ValueKey(post.id),
                        post: post,
                        author: author,
                        onLike: () => viewModel.toggleLike(post.id),
                        onComment: () => showCommentsSheet(
                          context,
                          viewModel: viewModel,
                          initialPost: post,
                        ),
                        onShare: () => _showShareSheet(context, post),
                        onSave: () {
                          viewModel.toggleSave(post.id);
                          _showMessage(
                            context,
                            post.isSaved ? '저장을 취소했어요.' : '게시물을 저장했어요.',
                          );
                        },
                        onMore: () => _showPostOptions(context, post),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showStory(BuildContext context, AppUser user) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.displayName}의 오늘',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(user.bio, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppPalette.blue),
                    const SizedBox(width: 6),
                    Text(
                      'Lv.${user.level} · 팔로워 ${user.followers}명',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showShareSheet(BuildContext context, FeedPost post) async {
    final action = await showModalBottomSheet<_ShareAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.link_rounded),
                  title: const Text('링크 복사'),
                  onTap: () => Navigator.of(context).pop(_ShareAction.copyLink),
                ),
                ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: const Text('친구에게 보내기'),
                  onTap: () => Navigator.of(context).pop(_ShareAction.send),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;
    if (action == _ShareAction.copyLink) {
      await Clipboard.setData(
        ClipboardData(text: 'https://motive.app/posts/${post.id}'),
      );
      if (!context.mounted) return;
      _showMessage(context, '게시물 링크를 복사했어요.');
      return;
    }
    final roomId = await _selectShareRoom(context);
    if (!context.mounted || roomId == null) return;
    viewModel.sharePostToRoom(post, roomId);
    _showMessage(context, '채팅방에 게시물을 보냈어요.');
  }

  Future<String?> _selectShareRoom(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.65,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                children: [
                  const ListTile(
                    title: Text('보낼 채팅방 선택'),
                    subtitle: Text('인증 결과와 게시물 링크를 함께 보내요.'),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: viewModel.shareRooms.length,
                      itemBuilder: (context, index) {
                        final room = viewModel.shareRooms[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppPalette.surfaceStrong,
                            child: Text(
                              room.memberInitials.isEmpty
                                  ? (room.title.isEmpty
                                        ? '?'
                                        : room.title.substring(0, 1))
                                  : room.memberInitials.first,
                            ),
                          ),
                          title: Text(room.title),
                          subtitle: Text(
                            room.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(room.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPostOptions(BuildContext context, FeedPost post) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('게시물 옵션'),
                  subtitle: Text(
                    post.planTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: const Text('이 게시물 알림 받기'),
                  onTap: () => Navigator.of(context).pop('게시물 알림을 켰어요.'),
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined),
                  title: const Text('이런 게시물 덜 보기'),
                  onTap: () => Navigator.of(context).pop('피드 추천에 반영할게요.'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted || message == null) return;
    _showMessage(context, message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.onCreatePost,
    required this.onNotifications,
  });

  final VoidCallback onCreatePost;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'motive',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(letterSpacing: -1.8),
            ),
          ),
          IconButton(
            onPressed: onCreatePost,
            tooltip: '새 인증',
            icon: const Icon(Icons.add_box_outlined),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotifications,
                tooltip: '알림',
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const Positioned(
                top: 9,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppPalette.red,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 7, height: 7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedScopeTabs extends StatelessWidget {
  const _FeedScopeTabs({required this.scope, required this.onChanged});

  final FeedScope scope;
  final ValueChanged<FeedScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.line)),
      ),
      child: Row(
        children: FeedScope.values
            .map((value) {
              final isSelected = value == scope;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(value),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Text(
                          value == FeedScope.following ? '팔로잉' : '추천',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isSelected
                                    ? AppPalette.ink
                                    : AppPalette.muted,
                              ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 2,
                        color: isSelected ? AppPalette.ink : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 46,
              color: AppPalette.muted,
            ),
            const SizedBox(height: 14),
            Text(
              '아직 보여줄 인증이 없어요',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '친구를 팔로우하면 성공과 실패 기록이 여기에 보여요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ShareAction { copyLink, send }
