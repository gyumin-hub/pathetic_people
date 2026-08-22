import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/models/plan_item.dart';
import '../view_models/planner_view_model.dart';
import 'plan_proof_sheet.dart';
import 'planner_ui_extensions.dart';

class PlanDetailSheet extends StatefulWidget {
  const PlanDetailSheet({
    required this.planId,
    required this.viewModel,
    this.initialProofType,
    super.key,
  });

  final String planId;
  final PlannerViewModel viewModel;
  final PlanProofType? initialProofType;

  static Future<void> show(
    BuildContext context, {
    required PlanItem plan,
    required PlannerViewModel viewModel,
    PlanProofType? initialProofType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PlanDetailSheet(
        planId: plan.id,
        viewModel: viewModel,
        initialProofType: initialProofType,
      ),
    );
  }

  @override
  State<PlanDetailSheet> createState() => _PlanDetailSheetState();
}

class _PlanDetailSheetState extends State<PlanDetailSheet> {
  Timer? _clockTimer;
  bool _didOpenInitialProof = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    if (widget.initialProofType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didOpenInitialProof) return;
        _didOpenInitialProof = true;
        final plan = widget.viewModel.planById(widget.planId);
        final now = DateTime.now();
        if (plan != null &&
            plan.progress == PlanProgress.pending &&
            !now.isBefore(plan.scheduledAt) &&
            now.isBefore(plan.verificationDueAt)) {
          _openProof(plan, widget.initialProofType!);
        }
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.top - 12;
    final preferredHeight = mediaQuery.size.height * 0.9;
    final sheetHeight = availableHeight < preferredHeight
        ? availableHeight
        : preferredHeight;

    return SizedBox(
      height: sheetHeight,
      child: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final plan = widget.viewModel.planById(widget.planId);
          if (plan == null) return const _MissingPlan();
          final now = DateTime.now();
          final canSubmitProof =
              !now.isBefore(plan.scheduledAt) &&
              now.isBefore(plan.verificationDueAt);
          final proofDisabledMessage = now.isBefore(plan.scheduledAt)
              ? '시작 시간이 되면 인증할 수 있어요.'
              : !now.isBefore(plan.verificationDueAt)
              ? '완료 인증 시간이 지났어요. 상태를 새로 확인해 주세요.'
              : null;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailHeader(plan: plan),
                const SizedBox(height: 18),
                _StatusPanel(plan: plan, now: DateTime.now()),
                const SizedBox(height: 22),
                _InformationCard(plan: plan),
                if (plan.startProof != null) ...[
                  const SizedBox(height: 22),
                  _ProofPreview(proof: plan.startProof!),
                ],
                if (plan.completionProof != null) ...[
                  const SizedBox(height: 14),
                  _ProofPreview(proof: plan.completionProof!),
                ],
                const SizedBox(height: 24),
                if (plan.progress == PlanProgress.pending)
                  _PendingActions(
                    hasStartProof: plan.startProof != null,
                    isEnabled: canSubmitProof,
                    disabledMessage: proofDisabledMessage,
                    onStart: () => _openProof(plan, PlanProofType.start),
                    onComplete: () =>
                        _openProof(plan, PlanProofType.completion),
                  )
                else
                  _FinalResult(plan: plan),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openProof(PlanItem plan, PlanProofType type) async {
    final proofDraft = await PlanProofSheet.show(
      context,
      plan: plan,
      type: type,
    );
    if (proofDraft == null || !mounted) return;

    try {
      if (type == PlanProofType.start) {
        widget.viewModel.startPlan(plan.id, proofDraft);
      } else {
        widget.viewModel.completePlan(plan.id, proofDraft);
      }
      _showMessage(
        type == PlanProofType.start ? '시작 인증을 기록했어요.' : '완료 인증을 기록했어요.',
      );
    } on StateError catch (error) {
      _showMessage(error.message, isError: true);
    } on ArgumentError catch (error) {
      _showMessage('${error.message}', isError: true);
    } catch (_) {
      _showMessage('인증을 저장하지 못했어요. 잠시 후 다시 시도해 주세요.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppPalette.red : AppPalette.ink,
        ),
      );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.plan});

  final PlanItem plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.category.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: plan.category.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                plan.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '닫기',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.plan, required this.now});

  final PlanItem plan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final status = _statusContent(plan, now);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(status.icon, size: 22, color: status.color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: status.color),
                ),
                const SizedBox(height: 4),
                Text(
                  status.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppPalette.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.plan});

  final PlanItem plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.play_circle_outline_rounded,
            label: '시작 예정',
            value: _dateTimeLabel(plan.scheduledAt),
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.verified_outlined,
            label: '완료 인증 시간',
            value: _dateTimeLabel(plan.verificationDueAt),
          ),
          const Divider(),
          _DetailRow(
            icon: plan.visibility.icon,
            label: '공개 범위',
            value: plan.visibility.label,
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.add_a_photo_outlined,
            label: '사진 인증',
            value: plan.photoProofRequired ? '필수' : '선택',
          ),
          const Divider(),
          _DetailRow(
            icon: Icons.repeat_rounded,
            label: '반복',
            value: plan.recurrence == '없음' ? '반복 없음' : plan.recurrence,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppPalette.muted),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofPreview extends StatelessWidget {
  const _ProofPreview({required this.proof});

  final PlanProof proof;

  @override
  Widget build(BuildContext context) {
    final bytes = proof.mediaBytes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppPalette.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                proof.type == PlanProofType.start
                    ? Icons.play_arrow_rounded
                    : Icons.check_rounded,
                size: 18,
                color: proof.type == PlanProofType.start
                    ? AppPalette.blue
                    : AppPalette.green,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '기록된 ${proof.type.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                AppDateUtils.hourMinute(proof.recordedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (bytes != null && bytes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ProofImage(bytes: bytes),
          ],
          if (proof.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(proof.note, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (proof.sharedToFeed) ...[
            const SizedBox(height: 10),
            Text(
              proof.type == PlanProofType.start ? '도전 중 상태 공개' : '피드에 공유됨',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProofImage extends StatelessWidget {
  const _ProofImage({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: 168,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: 1200,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(
              color: AppPalette.surfaceStrong,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppPalette.muted,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PendingActions extends StatelessWidget {
  const _PendingActions({
    required this.hasStartProof,
    required this.isEnabled,
    required this.disabledMessage,
    required this.onStart,
    required this.onComplete,
  });

  final bool hasStartProof;
  final bool isEnabled;
  final String? disabledMessage;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEnabled && !hasStartProof ? onStart : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: Icon(
                  hasStartProof
                      ? Icons.check_circle_outline_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(hasStartProof ? '시작 인증 완료' : '시작 인증'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: isEnabled ? onComplete : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.verified_rounded),
                label: const Text('완료 인증'),
              ),
            ),
          ],
        ),
        if (disabledMessage != null) ...[
          const SizedBox(height: 9),
          Text(
            disabledMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _FinalResult extends StatelessWidget {
  const _FinalResult({required this.plan});

  final PlanItem plan;

  @override
  Widget build(BuildContext context) {
    final isCompleted = plan.progress == PlanProgress.completed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFE9F8F2) : AppPalette.redSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCompleted
                ? Icons.emoji_events_outlined
                : Icons.warning_amber_rounded,
            color: isCompleted ? AppPalette.green : AppPalette.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? '달성으로 기록됐어요' : '완료 인증 시간을 넘겼어요',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isCompleted ? AppPalette.green : AppPalette.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted
                      ? '완료 인증과 +${plan.experiencePoint} XP가 반영됐어요.'
                      : '이 계획은 미달성으로 확정됐고, 공개 도전이었다면 실패 기록이 공개될 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingPlan extends StatelessWidget {
  const _MissingPlan();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, color: AppPalette.muted),
            const SizedBox(height: 10),
            const Text('이 계획을 찾을 수 없어요.'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanStatusContent {
  const _PlanStatusContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

_PlanStatusContent _statusContent(PlanItem plan, DateTime now) {
  if (plan.progress == PlanProgress.completed) {
    return const _PlanStatusContent(
      title: '달성 완료',
      description: '완료 인증이 저장됐어요. 오늘 할 일을 제대로 끝냈네요.',
      icon: Icons.check_circle_rounded,
      color: AppPalette.green,
      backgroundColor: Color(0xFFE9F8F2),
    );
  }
  if (plan.progress == PlanProgress.failed) {
    return const _PlanStatusContent(
      title: '미달성 확정',
      description: '완료 인증 시간을 넘겨 실패로 기록됐어요.',
      icon: Icons.close_rounded,
      color: AppPalette.red,
      backgroundColor: AppPalette.redSoft,
    );
  }
  if (now.isBefore(plan.scheduledAt)) {
    return _PlanStatusContent(
      title: '시작까지 ${_durationLabel(plan.scheduledAt.difference(now))}',
      description: '시작 예정 시간이 되면 인증을 남기고 실행해 보세요.',
      icon: Icons.schedule_rounded,
      color: AppPalette.blue,
      backgroundColor: AppPalette.blueSoft,
    );
  }
  if (now.isBefore(plan.verificationDueAt)) {
    return _PlanStatusContent(
      title:
          '완료 인증까지 ${_durationLabel(plan.verificationDueAt.difference(now))}',
      description: plan.startProof == null
          ? '시작 인증을 남기고, 정해둔 시간 전에 완료 인증해 주세요.'
          : '시작 인증을 남겼어요. 이제 끝낸 결과를 인증하세요.',
      icon: Icons.timer_outlined,
      color: AppPalette.blue,
      backgroundColor: AppPalette.blueSoft,
    );
  }
  return const _PlanStatusContent(
    title: '인증 시간이 지났어요',
    description: '상태를 다시 판정하면 미달성으로 반영돼요.',
    icon: Icons.warning_amber_rounded,
    color: AppPalette.red,
    backgroundColor: AppPalette.redSoft,
  );
}

String _dateTimeLabel(DateTime value) {
  return '${AppDateUtils.fullDate(value)} ${AppDateUtils.hourMinute(value)}';
}

String _durationLabel(Duration duration) {
  if (duration.inDays > 0) {
    final hours = duration.inHours.remainder(24);
    return hours == 0 ? '${duration.inDays}일' : '${duration.inDays}일 $hours시간';
  }
  if (duration.inHours > 0) {
    final minutes = duration.inMinutes.remainder(60);
    return minutes == 0
        ? '${duration.inHours}시간'
        : '${duration.inHours}시간 $minutes분';
  }
  final minutes = duration.inMinutes < 1 ? 1 : duration.inMinutes;
  return '$minutes분';
}
