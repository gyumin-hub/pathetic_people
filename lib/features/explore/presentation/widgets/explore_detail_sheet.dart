import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/media_artwork.dart';
import '../../../../domain/models/explore_item.dart';
import '../../../../domain/models/feed_post.dart';

Future<void> showExploreDetailSheet(
  BuildContext context, {
  required ExploreItem item,
}) async {
  final action = await showModalBottomSheet<_DetailAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ExploreDetailSheet(item: item),
  );

  if (!context.mounted || action == null) return;
  await Clipboard.setData(
    ClipboardData(text: 'https://motive.app/explore/${item.id}'),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('탐색 기록 링크를 복사했어요.')));
}

class _ExploreDetailSheet extends StatelessWidget {
  const _ExploreDetailSheet({required this.item});

  final ExploreItem item;

  @override
  Widget build(BuildContext context) {
    final isSuccess = item.outcome == PostOutcome.success;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '기록 상세',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '닫기',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: MediaArtwork(
                kind: item.mediaKind,
                headline: item.title,
                outcome: item.outcome,
                label: '${item.category} · ${item.label}',
                aspectRatio: 4 / 5,
                isVideo: item.isVideo,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? AppPalette.blueSoft
                              : AppPalette.redSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isSuccess ? '계획 달성' : '계획 미달성',
                          style: TextStyle(
                            color: isSuccess ? AppPalette.blue : AppPalette.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.local_fire_department_outlined,
                        size: 18,
                        color: AppPalette.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '인기 ${item.popularity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title.replaceAll('\n', ' '),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSuccess
                        ? '핑계 없이 끝낸 인증입니다. 다음 계획도 이 흐름을 이어가 보세요.'
                        : '계획은 있었지만 실행은 없었네요. 이 기록을 보고 다음에는 결과로 말해 보세요.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_DetailAction.copyLink),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('링크 복사'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _DetailAction { copyLink }
