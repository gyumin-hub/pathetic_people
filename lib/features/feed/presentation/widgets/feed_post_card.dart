import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/media_artwork.dart';
import '../../../../domain/models/app_user.dart';
import '../../../../domain/models/feed_post.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    required this.post,
    required this.author,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.onMore,
    super.key,
  });

  final FeedPost post;
  final AppUser author;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final isFailure = post.outcome == PostOutcome.failure;
    final outcomeColor = isFailure ? AppPalette.red : AppPalette.blue;
    final outcomeBackground = isFailure
        ? AppPalette.redSoft
        : AppPalette.blueSoft;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppPalette.background,
        border: Border(bottom: BorderSide(color: AppPalette.surface, width: 8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                AppAvatar.user(author, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${AppDateUtils.relativeTime(post.createdAt)} · 공개',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: outcomeBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isFailure ? '미달성' : '달성',
                    style: TextStyle(
                      color: outcomeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onMore,
                  tooltip: '게시물 옵션',
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
          MediaArtwork(
            kind: post.mediaKind,
            headline: post.mediaHeadline,
            outcome: post.outcome,
            label: post.streakDays == null
                ? post.planTitle
                : '${post.streakDays}일 연속 · ${post.planTitle}',
            aspectRatio: 4 / 5,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                _ActionButton(
                  tooltip: post.isLiked ? '좋아요 취소' : '좋아요',
                  icon: post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: post.isLiked ? AppPalette.red : AppPalette.ink,
                  onPressed: onLike,
                ),
                _ActionButton(
                  tooltip: '댓글',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: onComment,
                ),
                _ActionButton(
                  tooltip: '공유',
                  icon: Icons.send_outlined,
                  onPressed: onShare,
                ),
                const Spacer(),
                _ActionButton(
                  tooltip: post.isSaved ? '저장 취소' : '저장',
                  icon: post.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  onPressed: onSave,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '좋아요 ${_formatCount(post.likes)}개',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 7),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'motive  ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: post.mentorMessage),
                    ],
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onComment,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      post.comments.isEmpty
                          ? '첫 댓글을 남겨보세요'
                          : '댓글 ${post.comments.length}개 모두 보기',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted),
                    ),
                  ),
                ),
                if (post.comments.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${post.comments.last.authorName}  ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: post.comments.last.message),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppPalette.ink),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = AppPalette.ink,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 27,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color),
    );
  }
}
