import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/section_header.dart';
import '../../../domain/models/plan_item.dart';
import '../view_models/planner_view_model.dart';
import 'plan_detail_sheet.dart';
import 'plan_form_sheet.dart';
import 'planner_ui_extensions.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({required this.viewModel, super.key});

  final PlannerViewModel viewModel;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  bool _isMonthExpanded = false;

  @override
  void initState() {
    super.initState();
    _evaluateOverduePlansAfterBuild();
  }

  @override
  void didUpdateWidget(covariant PlannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _evaluateOverduePlansAfterBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final plans = widget.viewModel.selectedPlans;
            return CustomScrollView(
              key: const PageStorageKey<String>('planner-page'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: PageHeader(
                    eyebrow: 'PLANNER',
                    title: '계획',
                    trailing: _AddPlanButton(onPressed: _openAddPlan),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SummaryCard(
                    date: widget.viewModel.selectedDate,
                    completedCount: widget.viewModel.completedCount,
                    totalCount: plans.length,
                    completionRate: widget.viewModel.completionRate,
                    currentStreak: widget.viewModel.currentStreak,
                    bestStreak: widget.viewModel.bestStreak,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CalendarSection(
                    viewModel: widget.viewModel,
                    isMonthExpanded: _isMonthExpanded,
                    onToggleExpanded: () {
                      setState(() => _isMonthExpanded = !_isMonthExpanded);
                    },
                    onPrevious: _showPreviousPeriod,
                    onNext: _showNextPeriod,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      eyebrow: '${plans.length}개의 계획',
                      title: AppDateUtils.fullDate(
                        widget.viewModel.selectedDate,
                      ),
                      actionLabel: '추가',
                      onAction: _openAddPlan,
                    ),
                  ),
                ),
                if (plans.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyPlanState(onAdd: _openAddPlan),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final plan = plans[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == plans.length - 1 ? 0 : 10,
                          ),
                          child: Dismissible(
                            key: ValueKey(plan.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDelete(plan),
                            onDismissed: (_) => _removePlan(plan),
                            background: const _DeleteBackground(),
                            child: _PlanCard(
                              plan: plan,
                              onTap: () => _openPlanDetail(plan),
                              onCompletionTap: () => _openPlanDetail(
                                plan,
                                initialProofType: PlanProofType.completion,
                              ),
                              onEdit: () => _openEditPlan(plan),
                              onDelete: () => _requestDelete(plan),
                            ),
                          ),
                        );
                      }, childCount: plans.length),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
                    child: _MentorPanel(
                      message: widget.viewModel.mentorMessage,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _evaluateOverduePlansAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.viewModel.evaluateOverduePlans();
      }
    });
  }

  void _showPreviousPeriod() {
    if (_isMonthExpanded) {
      widget.viewModel.previousMonth();
      return;
    }
    widget.viewModel.selectDate(
      widget.viewModel.selectedDate.subtract(const Duration(days: 7)),
    );
  }

  void _showNextPeriod() {
    if (_isMonthExpanded) {
      widget.viewModel.nextMonth();
      return;
    }
    widget.viewModel.selectDate(
      widget.viewModel.selectedDate.add(const Duration(days: 7)),
    );
  }

  Future<void> _openAddPlan() async {
    final saved = await PlanFormSheet.show(
      context,
      viewModel: widget.viewModel,
      initialDate: widget.viewModel.selectedDate,
    );
    if (!saved || !mounted) {
      return;
    }
    _showMessage('새 계획을 추가했어요.');
  }

  Future<void> _openEditPlan(PlanItem plan) async {
    if (plan.progress != PlanProgress.pending) {
      _showMessage('완료되거나 실패한 계획은 기록을 보호하기 위해 수정할 수 없어요.');
      return;
    }
    final saved = await PlanFormSheet.show(
      context,
      viewModel: widget.viewModel,
      initialDate: plan.scheduledAt,
      initialPlan: plan,
    );
    if (!saved || !mounted) {
      return;
    }
    _showMessage('계획을 수정했어요.');
  }

  Future<void> _openPlanDetail(
    PlanItem plan, {
    PlanProofType? initialProofType,
  }) {
    return PlanDetailSheet.show(
      context,
      plan: plan,
      viewModel: widget.viewModel,
      initialProofType: initialProofType,
    );
  }

  Future<void> _requestDelete(PlanItem plan) async {
    if (await _confirmDelete(plan)) {
      _removePlan(plan);
    }
  }

  Future<bool> _confirmDelete(PlanItem plan) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계획을 삭제할까요?'),
          content: Text('‘${plan.title}’ 계획은 다시 복구할 수 없어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppPalette.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    return shouldDelete ?? false;
  }

  void _removePlan(PlanItem plan) {
    widget.viewModel.deletePlan(plan.id);
    if (mounted) {
      _showMessage('계획을 삭제했어요.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AddPlanButton extends StatelessWidget {
  const _AddPlanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton.filled(
        tooltip: '계획 추가',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppPalette.ink,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.date,
    required this.completedCount,
    required this.totalCount,
    required this.completionRate,
    required this.currentStreak,
    required this.bestStreak,
  });

  final DateTime date;
  final int completedCount;
  final int totalCount;
  final double completionRate;
  final int currentStreak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final percentage = (completionRate * 100).round();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _summaryLabel(date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalCount == 0
                          ? '계획을 채워보세요'
                          : '$totalCount개 중 $completedCount개 달성',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: percentage == 100 ? AppPalette.green : AppPalette.ink,
                  letterSpacing: -1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: completionRate,
              minHeight: 7,
              backgroundColor: AppPalette.surfaceStrong,
              color: percentage == 100 ? AppPalette.green : AppPalette.blue,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.local_fire_department_outlined,
                  label: '현재 연속',
                  value: '$currentStreak일',
                ),
              ),
              Container(width: 1, height: 34, color: AppPalette.line),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.emoji_events_outlined,
                  label: '최고 연속',
                  value: '$bestStreak일',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _summaryLabel(DateTime date) {
    return AppDateUtils.isSameDay(date, DateTime.now())
        ? '오늘의 달성률'
        : '${date.month}월 ${date.day}일 달성률';
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: AppPalette.muted),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ],
    );
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.viewModel,
    required this.isMonthExpanded,
    required this.onToggleExpanded,
    required this.onPrevious,
    required this.onNext,
  });

  final PlannerViewModel viewModel;
  final bool isMonthExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final titleDate = isMonthExpanded
        ? viewModel.visibleMonth
        : viewModel.selectedDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onToggleExpanded,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppDateUtils.monthTitle(titleDate),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isMonthExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: AppPalette.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _CalendarNavigationButton(
                tooltip: isMonthExpanded ? '이전 달' : '이전 주',
                icon: Icons.chevron_left_rounded,
                onPressed: onPrevious,
              ),
              const SizedBox(width: 2),
              _CalendarNavigationButton(
                tooltip: isMonthExpanded ? '다음 달' : '다음 주',
                icon: Icons.chevron_right_rounded,
                onPressed: onNext,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _WeekStrip(viewModel: viewModel),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isMonthExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _MonthCalendar(viewModel: viewModel),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CalendarNavigationButton extends StatelessWidget {
  const _CalendarNavigationButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(backgroundColor: AppPalette.surface),
      icon: Icon(icon, size: 21),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.viewModel});

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  final PlannerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final selectedDate = viewModel.selectedDate;
    final monday = selectedDate.subtract(
      Duration(days: selectedDate.weekday - DateTime.monday),
    );

    return Row(
      children: List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        return Expanded(
          child: _DateCell(
            weekday: _weekdayLabels[index],
            date: date,
            plans: viewModel.plansFor(date),
            isSelected: AppDateUtils.isSameDay(date, selectedDate),
            onTap: () => viewModel.selectDate(date),
          ),
        );
      }),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.weekday,
    required this.date,
    required this.plans,
    required this.isSelected,
    required this.onTap,
  });

  final String weekday;
  final DateTime date;
  final List<PlanItem> plans;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = AppDateUtils.isSameDay(date, DateTime.now());
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${date.month}월 ${date.day}일 $weekday요일',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            children: [
              Text(
                weekday,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? AppPalette.blue : AppPalette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppPalette.blue : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: AppPalette.blue)
                      : null,
                ),
                child: Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected ? Colors.white : AppPalette.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _PlanStatusDot(plans: plans),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.viewModel});

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  final PlannerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final month = viewModel.visibleMonth;
    final firstDay = DateTime(month.year, month.month);
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCount = firstDay.weekday - DateTime.monday;
    final usedCellCount = leadingEmptyCount + dayCount;
    final cellCount = ((usedCellCount + 6) ~/ 7) * 7;

    return Column(
      children: [
        Row(
          children: _weekdayLabels
              .map((label) {
                return Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final day = index - leadingEmptyCount + 1;
            if (day < 1 || day > dayCount) {
              return const SizedBox.shrink();
            }
            final date = DateTime(month.year, month.month, day);
            return _MonthDayCell(
              date: date,
              plans: viewModel.plansFor(date),
              isSelected: AppDateUtils.isSameDay(date, viewModel.selectedDate),
              onTap: () => viewModel.selectDate(date),
            );
          },
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.plans,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final List<PlanItem> plans;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = AppDateUtils.isSameDay(date, DateTime.now());
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${date.month}월 ${date.day}일',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppPalette.blue : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: AppPalette.blue)
                    : null,
              ),
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : AppPalette.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 3),
            _PlanStatusDot(plans: plans),
          ],
        ),
      ),
    );
  }
}

class _PlanStatusDot extends StatelessWidget {
  const _PlanStatusDot({required this.plans});

  final List<PlanItem> plans;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const SizedBox(width: 5, height: 5);
    }

    final Color color;
    if (plans.any((plan) => plan.progress == PlanProgress.failed)) {
      color = AppPalette.red;
    } else if (plans.every((plan) => plan.progress == PlanProgress.completed)) {
      color = AppPalette.green;
    } else {
      color = AppPalette.blue;
    }

    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

enum _PlanMenuAction { edit, delete }

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onCompletionTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PlanItem plan;
  final VoidCallback onTap;
  final VoidCallback onCompletionTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isCompleted = plan.progress == PlanProgress.completed;
    final backgroundColor = plan.progress == PlanProgress.failed
        ? AppPalette.redSoft
        : AppPalette.background;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: plan.progress == PlanProgress.failed
              ? AppPalette.red.withValues(alpha: 0.16)
              : AppPalette.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompletionButton(
                progress: plan.progress,
                onPressed: onCompletionTap,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: plan.category.softColor,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            plan.category.icon,
                            size: 14,
                            color: plan.category.color,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${AppDateUtils.hourMinute(plan.scheduledAt)} 시작 · ${plan.category.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isCompleted ? AppPalette.muted : AppPalette.ink,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${AppDateUtils.hourMinute(plan.verificationDueAt)} 완료 인증',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: plan.progress == PlanProgress.failed
                            ? AppPalette.red
                            : AppPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusBadge(progress: plan.progress),
                        _PlanMetaBadge(
                          icon: plan.visibility.icon,
                          label: plan.visibility.label,
                          color: plan.visibility.color,
                          backgroundColor: plan.visibility.softColor,
                        ),
                        if (plan.photoProofRequired)
                          const _PlanMetaBadge(
                            icon: Icons.add_a_photo_outlined,
                            label: '사진 필수',
                            color: AppPalette.muted,
                            backgroundColor: AppPalette.surfaceStrong,
                          ),
                        Text(
                          plan.recurrence == '없음' ? '반복 없음' : plan.recurrence,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '+${plan.experiencePoint} XP',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppPalette.blue,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_PlanMenuAction>(
                tooltip: '계획 메뉴',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppPalette.muted,
                ),
                onSelected: (action) {
                  switch (action) {
                    case _PlanMenuAction.edit:
                      onEdit();
                    case _PlanMenuAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  if (plan.progress == PlanProgress.pending)
                    const PopupMenuItem(
                      value: _PlanMenuAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('수정'),
                      ),
                    ),
                  const PopupMenuItem(
                    value: _PlanMenuAction.delete,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: AppPalette.red,
                      ),
                      title: Text(
                        '삭제',
                        style: TextStyle(color: AppPalette.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionButton extends StatelessWidget {
  const _CompletionButton({required this.progress, required this.onPressed});

  final PlanProgress progress;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress == PlanProgress.completed;
    final isFailed = progress == PlanProgress.failed;
    final color = isCompleted
        ? AppPalette.green
        : isFailed
        ? AppPalette.red
        : AppPalette.line;
    return Semantics(
      button: true,
      checked: isCompleted,
      label: isCompleted
          ? '달성 상세 보기'
          : isFailed
          ? '미달성 상세 보기'
          : '완료 인증 열기',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.8),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : isFailed
                  ? const Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: AppPalette.red,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.progress});

  final PlanProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: progress.softColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        progress.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: progress.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlanMetaBadge extends StatelessWidget {
  const _PlanMetaBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
        color: AppPalette.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white),
          SizedBox(height: 2),
          Text(
            '삭제',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlanState extends StatelessWidget {
  const _EmptyPlanState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_note_rounded,
            size: 30,
            color: AppPalette.muted,
          ),
          const SizedBox(height: 10),
          Text('아직 계획이 없어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '하나만 만들고 직접 지켜보세요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('계획 추가'),
          ),
        ],
      ),
    );
  }
}

class _MentorPanel extends StatelessWidget {
  const _MentorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.record_voice_over_outlined,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MENTOR REPORT',
                  style: TextStyle(
                    color: Color(0xFFFF7A84),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '팩트는 아프지만 기록은 남습니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.52),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
