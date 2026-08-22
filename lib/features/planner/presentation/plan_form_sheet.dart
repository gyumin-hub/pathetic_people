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

    if (draft == null) return false;
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
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late PlanCategory _category;
  late String _recurrence;
  late int _experiencePoint;
  late PlanVisibility _visibility;
  late bool _photoProofRequired;
  bool _showTimeError = false;

  bool get _isEditing => widget.initialPlan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    final initialStart =
        plan?.scheduledAt ?? _suggestedSchedule(widget.initialDate);
    final initialDue =
        plan?.verificationDueAt ?? initialStart.add(const Duration(hours: 1));
    _titleController = TextEditingController(text: plan?.title ?? '');
    _startDate = AppDateUtils.startOfDay(initialStart);
    _startTime = TimeOfDay.fromDateTime(initialStart);
    _dueDate = AppDateUtils.startOfDay(initialDue);
    _dueTime = TimeOfDay.fromDateTime(initialDue);
    _category = plan?.category ?? PlanCategory.routine;
    _recurrence = plan?.recurrence ?? '없음';
    _experiencePoint = plan?.experiencePoint ?? 10;
    _visibility = plan?.visibility ?? PlanVisibility.private;
    _photoProofRequired = plan?.photoProofRequired ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.top - bottomInset - 12;
    final preferredHeight = mediaQuery.size.height * 0.92;
    final sheetHeight = availableHeight < preferredHeight
        ? availableHeight
        : preferredHeight;
    final recurrenceOptions = {
      ..._recurrenceOptions,
      _recurrence,
    }.toList(growable: false);
    final hasInvalidWindow = !_verificationDueAt.isAfter(_scheduledAt);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: sheetHeight,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    if (title.isEmpty) return '계획 이름을 입력해 주세요.';
                    if (title.length < 2) return '2자 이상 입력해 주세요.';
                    return null;
                  },
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),
                const SizedBox(height: 22),
                const _FieldLabel('시작 예정'),
                const SizedBox(height: 6),
                Text(
                  '이 시간부터 계획을 실행할 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _PickerButton(
                        icon: Icons.calendar_today_rounded,
                        label: AppDateUtils.fullDate(_startDate),
                        onTap: _pickStartDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _PickerButton(
                        icon: Icons.schedule_rounded,
                        label: AppDateUtils.hourMinute(_scheduledAt),
                        onTap: _pickStartTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _FieldLabel('완료 인증 시간'),
                const SizedBox(height: 6),
                Text(
                  '이 시간 안에 완료 인증을 남겨야 달성으로 기록돼요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _PickerButton(
                        icon: Icons.event_available_outlined,
                        label: AppDateUtils.fullDate(_dueDate),
                        onTap: _pickDueDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _PickerButton(
                        icon: Icons.timer_outlined,
                        label: AppDateUtils.hourMinute(_verificationDueAt),
                        onTap: _pickDueTime,
                      ),
                    ),
                  ],
                ),
                if (_showTimeError && hasInvalidWindow) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '완료 인증 시간은 시작 예정보다 뒤여야 해요.',
                    style: TextStyle(
                      color: AppPalette.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const _FieldLabel('공개 범위'),
                const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: PlanVisibility.values
                        .map((visibility) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: visibility == PlanVisibility.private
                                    ? 8
                                    : 0,
                              ),
                              child: _VisibilityCard(
                                visibility: visibility,
                                isSelected: _visibility == visibility,
                                onTap: () =>
                                    setState(() => _visibility = visibility),
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
                if (_visibility == PlanVisibility.publicChallenge) ...[
                  const SizedBox(height: 10),
                  const _PublicWarning(),
                ],
                const SizedBox(height: 12),
                _PhotoProofSwitch(
                  value: _photoProofRequired,
                  onChanged: (value) {
                    setState(() => _photoProofRequired = value);
                  },
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
                          onSelected: (_) =>
                              setState(() => _category = category),
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
                  runSpacing: 8,
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
      ),
    );
  }

  DateTime get _scheduledAt => _combine(_startDate, _startTime);

  DateTime get _verificationDueAt => _combine(_dueDate, _dueTime);

  Future<void> _pickStartDate() async {
    final picked = await _pickDate(
      initialDate: _startDate,
      helpText: '시작 날짜 선택',
    );
    if (picked == null || !mounted) return;
    final duration = _safeVerificationWindow;
    setState(() {
      _startDate = AppDateUtils.startOfDay(picked);
      _setDueDateTime(_scheduledAt.add(duration));
      _showTimeError = false;
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await _pickTime(
      initialTime: _startTime,
      helpText: '시작 시간 선택',
    );
    if (picked == null || !mounted) return;
    final duration = _safeVerificationWindow;
    setState(() {
      _startTime = picked;
      _setDueDateTime(_scheduledAt.add(duration));
      _showTimeError = false;
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await _pickDate(
      initialDate: _dueDate,
      helpText: '완료 인증 날짜 선택',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dueDate = AppDateUtils.startOfDay(picked);
      _showTimeError = !_verificationDueAt.isAfter(_scheduledAt);
    });
  }

  Future<void> _pickDueTime() async {
    final picked = await _pickTime(
      initialTime: _dueTime,
      helpText: '완료 인증 시간 선택',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dueTime = picked;
      _showTimeError = !_verificationDueAt.isAfter(_scheduledAt);
    });
  }

  Future<DateTime?> _pickDate({
    required DateTime initialDate,
    required String helpText,
  }) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final firstYear = initialDate.year < now.year - 1
        ? initialDate.year
        : now.year - 1;
    final lastYear = initialDate.year > now.year + 5
        ? initialDate.year
        : now.year + 5;
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(firstYear),
      lastDate: DateTime(lastYear, 12, 31),
      helpText: helpText,
      cancelText: '취소',
      confirmText: '선택',
    );
  }

  Future<TimeOfDay?> _pickTime({
    required TimeOfDay initialTime,
    required String helpText,
  }) {
    FocusScope.of(context).unfocus();
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: helpText,
      cancelText: '취소',
      confirmText: '선택',
    );
  }

  Duration get _safeVerificationWindow {
    final duration = _verificationDueAt.difference(_scheduledAt);
    return duration > Duration.zero ? duration : const Duration(hours: 1);
  }

  void _setDueDateTime(DateTime value) {
    _dueDate = AppDateUtils.startOfDay(value);
    _dueTime = TimeOfDay.fromDateTime(value);
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    final timeIsValid = _verificationDueAt.isAfter(_scheduledAt);
    if (!formIsValid || !timeIsValid) {
      setState(() => _showTimeError = !timeIsValid);
      return;
    }

    Navigator.of(context).pop(
      PlanDraft(
        title: _titleController.text.trim(),
        scheduledAt: _scheduledAt,
        verificationDueAt: _verificationDueAt,
        category: _category,
        recurrence: _recurrence,
        experiencePoint: _experiencePoint,
        visibility: _visibility,
        photoProofRequired: _photoProofRequired,
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
                isEditing
                    ? '시작과 인증 조건을 다시 조정해 보세요.'
                    : '시작과 완료 인증 시간을 먼저 약속하세요.',
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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppPalette.blue),
              const SizedBox(width: 7),
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

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({
    required this.visibility,
    required this.isSelected,
    required this.onTap,
  });

  final PlanVisibility visibility;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: visibility.label,
      child: Material(
        color: isSelected ? visibility.softColor : AppPalette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? visibility.color : AppPalette.line,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(visibility.icon, size: 19, color: visibility.color),
                    const Spacer(),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 19,
                      color: isSelected ? visibility.color : AppPalette.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  visibility.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  visibility.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicWarning extends StatelessWidget {
  const _PublicWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.redSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_outlined, size: 19, color: AppPalette.red),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '공개 도전은 완료 인증을 피드에 공유할 수 있고, '
              '실패하면 독설과 함께 실패 기록이 공개될 수 있어요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoProofSwitch extends StatelessWidget {
  const _PhotoProofSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text('사진 인증 필수', style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          '켜면 완료할 때 사진 없이 제출할 수 없어요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
