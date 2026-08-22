import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/media_artwork.dart';
import '../../../../domain/models/feed_post.dart';

class ProfileMediaGrid extends StatelessWidget {
  const ProfileMediaGrid({
    required this.posts,
    required this.onPostTap,
    required this.emptyTitle,
    required this.emptyDescription,
    this.emptyIcon = Icons.photo_library_outlined,
    super.key,
  });

  final List<FeedPost> posts;
  final ValueChanged<FeedPost> onPostTap;
  final String emptyTitle;
  final String emptyDescription;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 280,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPalette.line),
                    ),
                    child: Icon(emptyIcon, size: 28, color: AppPalette.muted),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    emptyDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final post = posts[index];
        return Semantics(
          button: true,
          label:
              '${post.planTitle}, ${post.outcome == PostOutcome.success ? '성공' : '실패'}',
          child: InkWell(
            onTap: () => onPostTap(post),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaArtwork(
                  kind: post.mediaKind,
                  headline: post.mediaHeadline,
                  outcome: post.outcome,
                  label: post.outcome == PostOutcome.success
                      ? 'SUCCESS'
                      : 'FAILED',
                  aspectRatio: 1,
                  compact: true,
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Icon(
                    post.outcome == PostOutcome.success
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: Colors.white,
                    size: 17,
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }, childCount: posts.length),
    );
  }
}
