import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/models/plan_item.dart';

class FeedStoryBar extends StatelessWidget {
  const FeedStoryBar({
    required this.plans,
    required this.onPlanTap,
    required this.onCreateTap,
    super.key,
  });

  final List<PlanItem> plans;
  final ValueChanged<PlanItem> onPlanTap;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('도전 중', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 7),
              if (plans.isNotEmpty)
                Text(
                  '${plans.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppPalette.blue),
                ),
              const Spacer(),
              TextButton(
                onPressed: onCreateTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(plans.isEmpty ? '도전 시작' : '계획 보기'),
              ),
            ],
          ),
          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '공유한 시작 인증이 여기에 표시돼요.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.muted),
              ),
            )
          else
            SizedBox(
              // 사진 원과 두 줄의 설명이 큰 글자 설정에서도 잘리지 않도록
              // Instagram 스타일의 story rail보다 조금 여유 있게 잡습니다.
              height: 112,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: plans.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return _ChallengeItem(
                    plan: plan,
                    onTap: () => onPlanTap(plan),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ChallengeItem extends StatelessWidget {
  const _ChallengeItem({required this.plan, required this.onTap});

  final PlanItem plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final proof = plan.startProof;
    final mediaBytes = proof?.mediaBytes;
    return Semantics(
      button: true,
      label: '${plan.title} 도전 중 인증 보기',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPalette.blue, width: 2),
                ),
                child: ClipOval(
                  child: mediaBytes == null
                      ? const ColoredBox(
                          color: AppPalette.surfaceStrong,
                          child: Icon(
                            Icons.bolt_rounded,
                            color: AppPalette.blue,
                          ),
                        )
                      : Image.memory(
                          mediaBytes,
                          fit: BoxFit.cover,
                          cacheWidth: 256,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: AppPalette.surfaceStrong,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppPalette.muted,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.ink,
                  fontSize: 11,
                ),
              ),
              Text(
                '${AppDateUtils.hourMinute(plan.verificationDueAt)}까지',
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
