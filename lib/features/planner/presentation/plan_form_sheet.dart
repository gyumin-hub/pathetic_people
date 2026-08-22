import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/models/plan_item.dart';
import '../view_models/planner_view_model.dart';
import 'planner_ui_extensions.dart';

class PlanFormSheet extends StatefulWidget {
  const PlanFormSheet({required this.initialDate, this.initialPlan, super.key});

  final DateTime initialDate;
  final PlanItem? initialPlan;

  static Future<bool> show(
    BuildContext context, {
    required PlannerViewModel viewModel,
    required DateTime initialDate,
    PlanItem? initialPlan,
  }) async {
    final draft = await showModalBottomSheet<PlanDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          PlanFormSheet(initialDate: initialDate, initialPlan: initialPlan),
    );

    if (draft == null) {
      return false;
    }
    if (initialPlan == null) {
      viewModel.addPlan(draft);
    } else {
      viewModel.updatePlan(initialPlan.id, draft);
    }
    return true;
  }

  @override
  State<PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends State<PlanFormSheet> {
  static const _recurrenceOptions = ['없음', '매일', '평일', '주말', '월·수·금'];
  static const _experienceOptions = [5, 10, 20];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late DateTime _date;
  late TimeOfDay _time;
  late PlanCategory _category;
  late String _recurrence;
  late int _experiencePoint;

  bool get _isEditing => widget.initialPlan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    final initialSchedule =
        plan?.scheduledAt ?? _suggestedSchedule(widget.initialDate);
    _titleController = TextEditingController(text: plan?.title ?? '');
    _date = AppDateUtils.startOfDay(initialSchedule);
    _time = TimeOfDay.fromDateTime(initialSchedule);
    _category = plan?.category ?? PlanCategory.routine;
    _recurrence = plan?.recurrence ?? '없음';
    _experiencePoint = plan?.experiencePoint ?? 10;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final recurrenceOptions = {
      ..._recurrenceOptions,
      _recurrence,
    }.toList(growable: false);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHeader(isEditing: _isEditing),
              const SizedBox(height: 24),
              const _FieldLabel('계획 이름'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 40,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: '예: 퇴근 후 운동 60분',
                  counterText: '',
                ),
                validator: (value) {
                  final title = value?.trim() ?? '';
                  if (title.isEmpty) {
                    return '계획 이름을 입력해 주세요.';
                  }
                  if (title.length < 2) {
                    return '2자 이상 입력해 주세요.';
                  }
                  return null;
                },
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 22),
              const _FieldLabel('실행 일시'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _PickerButton(
                      icon: Icons.calendar_today_rounded,
                      label: AppDateUtils.fullDate(_date),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _PickerButton(
                      icon: Icons.schedule_rounded,
                      label: AppDateUtils.hourMinute(_scheduledAt),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _FieldLabel('카테고리'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PlanCategory.values
                    .map((category) {
                      return ChoiceChip(
                        avatar: Icon(
                          category.icon,
                          size: 17,
                          color: _category == category
                              ? category.color
                              : AppPalette.muted,
                        ),
                        label: Text(category.label),
                        selected: _category == category,
                        selectedColor: category.softColor,
                        side: BorderSide(
                          color: _category == category
                              ? category.color
                              : AppPalette.line,
                        ),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _category = category),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 22),
              const _FieldLabel('반복'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recurrenceOptions
                    .map((recurrence) {
                      return ChoiceChip(
                        label: Text(recurrence),
                        selected: _recurrence == recurrence,
                        selectedColor: AppPalette.blueSoft,
                        side: BorderSide(
                          color: _recurrence == recurrence
                              ? AppPalette.blue
                              : AppPalette.line,
                        ),
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _recurrence = recurrence),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 22),
              const _FieldLabel('달성 경험치'),
              const SizedBox(height: 4),
              Text(
                '어려운 계획일수록 높게 설정하세요.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _experienceOptions
                    .map((point) {
                      return ChoiceChip(
                        label: Text('+$point XP'),
                        selected: _experiencePoint == point,
                        selectedColor: AppPalette.blueSoft,
                        side: BorderSide(
                          color: _experiencePoint == point
                              ? AppPalette.blue
                              : AppPalette.line,
                        ),
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _experiencePoint = point),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_isEditing ? '계획 수정하기' : '계획 추가하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime get _scheduledAt {
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final firstYear = _date.year < now.year - 1 ? _date.year : now.year - 1;
    final lastYear = _date.year > now.year + 5 ? _date.year : now.year + 5;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(firstYear),
      lastDate: DateTime(lastYear, 12, 31),
      helpText: '계획 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _date = AppDateUtils.startOfDay(picked));
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: '계획 시간 선택',
      cancelText: '취소',
      confirmText: '선택',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _time = picked);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      PlanDraft(
        title: _titleController.text.trim(),
        scheduledAt: _scheduledAt,
        category: _category,
        recurrence: _recurrence,
        experiencePoint: _experiencePoint,
      ),
    );
  }

  DateTime _suggestedSchedule(DateTime selectedDate) {
    final date = AppDateUtils.startOfDay(selectedDate);
    final now = DateTime.now();
    if (!AppDateUtils.isSameDay(date, now)) {
      return date.add(const Duration(hours: 9));
    }

    final next = now.add(const Duration(hours: 1));
    if (!AppDateUtils.isSameDay(date, next)) {
      return date.add(const Duration(hours: 23, minutes: 59));
    }
    return DateTime(date.year, date.month, date.day, next.hour);
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? '계획 수정' : '새 계획',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 3),
              Text(
                isEditing ? '실행 조건을 다시 조정해 보세요.' : '작게 시작하고 확실하게 끝내세요.',
                style: Theme.of(context).textTheme.bodySmall,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppPalette.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
