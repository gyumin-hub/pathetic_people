import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/models/plan_item.dart';
import '../view_models/planner_view_model.dart';
import 'planner_ui_extensions.dart';

class PlanFormSheet extends StatefulWidget {
  const PlanFormSheet({
    required this.initialDate,
    required this.onSubmit,
    required this.supportsMediaUpload,
    this.initialPlan,
    this.clock,
    super.key,
  });

  final DateTime initialDate;
  final PlanItem? initialPlan;
  final Future<String?> Function(PlanDraft draft) onSubmit;
  final bool supportsMediaUpload;
  final DateTime Function()? clock;

  static Future<bool> show(
    BuildContext context, {
    required PlannerViewModel viewModel,
    required DateTime initialDate,
    PlanItem? initialPlan,
  }) async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          isDismissible: false,
          enableDrag: false,
          builder: (context) => PlanFormSheet(
            initialDate: initialDate,
            initialPlan: initialPlan,
            supportsMediaUpload: viewModel.supportsProofMediaUpload,
            onSubmit: (draft) async {
              final saved = initialPlan == null
                  ? await viewModel.addPlan(draft)
                  : await viewModel.updatePlan(initialPlan.id, draft);
              if (saved) return null;
              return viewModel.submitErrorMessage ??
                  '계획을 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
            },
          ),
        ) ??
        false;
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
  bool _isSubmitting = false;
  String? _submitErrorMessage;

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
    final hasInvalidWindow =
        !_verificationDueAt.isAfter(_scheduledAt) ||
        !_verificationDueAt.isAfter(_now());

    return PopScope(
      canPop: !_isSubmitting,
      child: AnimatedPadding(
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
                  _SheetHeader(isEditing: _isEditing, canClose: !_isSubmitting),
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
                  _DateTimeField(
                    key: const ValueKey('startDateTimePicker'),
                    icon: Icons.play_arrow_rounded,
                    label: '시작',
                    value: _dateTimeLabel(_scheduledAt),
                    onTap: _pickStartDateTime,
                  ),
                  const SizedBox(height: 10),
                  _QuickChoiceRow(
                    label: '빠른 설정',
                    choices: const ['지금', '+15분', '+30분', '+1시간'],
                    onSelected: _setQuickStart,
                  ),
                  const SizedBox(height: 22),
                  const _FieldLabel('완료 인증 시간'),
                  const SizedBox(height: 6),
                  Text(
                    '이 시간 안에 완료 인증을 남겨야 달성으로 기록돼요.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _DateTimeField(
                    key: const ValueKey('dueDateTimePicker'),
                    icon: Icons.flag_rounded,
                    label: '완료 마감',
                    value: _dateTimeLabel(_verificationDueAt),
                    onTap: _pickDueDateTime,
                  ),
                  const SizedBox(height: 10),
                  _QuickChoiceRow(
                    label: '시작 후',
                    choices: const ['30분', '1시간', '2시간', '3시간'],
                    onSelected: _setQuickDue,
                  ),
                  if (_showTimeError && hasInvalidWindow) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '완료 인증 시간은 시작 예정보다 뒤이고 현재 이후여야 해요.',
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
                    onChanged: widget.supportsMediaUpload
                        ? (value) {
                            setState(() => _photoProofRequired = value);
                          }
                        : null,
                    unavailableMessage: widget.supportsMediaUpload
                        ? null
                        : '사진 업로드 API가 연결된 뒤 사용할 수 있어요.',
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
                  if (_submitErrorMessage != null) ...[
                    Text(
                      _submitErrorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppPalette.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? '계획 수정하기' : '계획 추가하기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime get _scheduledAt => _combine(_startDate, _startTime);

  DateTime get _verificationDueAt => _combine(_dueDate, _dueTime);

  Future<void> _pickStartDateTime() async {
    final picked = await _showDateTimePicker(
      title: '언제 시작할까요?',
      description: '날짜와 시간을 위아래로 움직여 선택하세요.',
      initialValue: _scheduledAt,
    );
    if (picked == null || !mounted) return;
    final duration = _safeVerificationWindow;
    setState(() {
      _setStartDateTime(picked);
      _setDueDateTime(picked.add(duration));
      _showTimeError = false;
    });
  }

  Future<void> _pickDueDateTime() async {
    final minimum = _scheduledAt.add(const Duration(minutes: 1));
    final picked = await _showDateTimePicker(
      title: '언제까지 인증할까요?',
      description: '시작 이후의 완료 인증 마감 시간을 선택하세요.',
      initialValue: _verificationDueAt.isBefore(minimum)
          ? minimum
          : _verificationDueAt,
      minimumValue: minimum,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _setDueDateTime(picked);
      _showTimeError = false;
    });
  }

  Future<DateTime?> _showDateTimePicker({
    required String title,
    required String description,
    required DateTime initialValue,
    DateTime? minimumValue,
  }) {
    FocusScope.of(context).unfocus();
    var selected = _withoutSeconds(initialValue);
    final minimum = minimumValue == null ? null : _withoutSeconds(minimumValue);
    if (minimum != null && selected.isBefore(minimum)) {
      selected = minimum;
    }
    return showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppPalette.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.light,
                      primaryColor: AppPalette.blue,
                    ),
                    child: SizedBox(
                      height: 210,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.dateAndTime,
                        initialDateTime: selected,
                        minimumDate: minimum,
                        maximumDate: DateTime(_now().year + 5, 12, 31, 23, 59),
                        use24hFormat: true,
                        minuteInterval: 1,
                        onDateTimeChanged: (value) {
                          setSheetState(() => selected = value);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.blueSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 19,
                        color: AppPalette.blue,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _dateTimeLabel(selected),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppPalette.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('이 시간으로 선택'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _setQuickStart(String choice) {
    final now = _withoutSeconds(_now());
    final offset = switch (choice) {
      '+15분' => const Duration(minutes: 15),
      '+30분' => const Duration(minutes: 30),
      '+1시간' => const Duration(hours: 1),
      _ => Duration.zero,
    };
    final nextStart = now.add(offset);
    final duration = _safeVerificationWindow;
    setState(() {
      _startDate = AppDateUtils.startOfDay(nextStart);
      _startTime = TimeOfDay.fromDateTime(nextStart);
      _setDueDateTime(nextStart.add(duration));
      _showTimeError = false;
    });
  }

  void _setQuickDue(String choice) {
    final duration = switch (choice) {
      '30분' => const Duration(minutes: 30),
      '2시간' => const Duration(hours: 2),
      '3시간' => const Duration(hours: 3),
      _ => const Duration(hours: 1),
    };
    setState(() {
      _setDueDateTime(_scheduledAt.add(duration));
      _showTimeError = false;
    });
  }

  Duration get _safeVerificationWindow {
    final duration = _verificationDueAt.difference(_scheduledAt);
    return duration > Duration.zero ? duration : const Duration(hours: 1);
  }

  void _setDueDateTime(DateTime value) {
    _dueDate = AppDateUtils.startOfDay(value);
    _dueTime = TimeOfDay.fromDateTime(value);
  }

  void _setStartDateTime(DateTime value) {
    _startDate = AppDateUtils.startOfDay(value);
    _startTime = TimeOfDay.fromDateTime(value);
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _dateTimeLabel(DateTime value) {
    return '${AppDateUtils.fullDate(value)} · ${AppDateUtils.hourMinute(value)}';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    final timeIsValid =
        _verificationDueAt.isAfter(_scheduledAt) &&
        _verificationDueAt.isAfter(_now());
    if (!formIsValid || !timeIsValid) {
      setState(() => _showTimeError = !timeIsValid);
      return;
    }

    final draft = PlanDraft(
      title: _titleController.text.trim(),
      scheduledAt: _scheduledAt,
      verificationDueAt: _verificationDueAt,
      category: _category,
      recurrence: _recurrence,
      experiencePoint: _experiencePoint,
      visibility: _visibility,
      photoProofRequired: _photoProofRequired,
    );
    setState(() {
      _isSubmitting = true;
      _submitErrorMessage = null;
    });

    final errorMessage = await widget.onSubmit(draft);
    if (!mounted) return;
    if (errorMessage == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _submitErrorMessage = errorMessage;
    });
  }

  DateTime _suggestedSchedule(DateTime selectedDate) {
    final date = AppDateUtils.startOfDay(selectedDate);
    final now = _withoutSeconds(_now());
    return DateTime(date.year, date.month, date.day, now.hour, now.minute);
  }

  DateTime _withoutSeconds(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }

  DateTime _now() => widget.clock?.call() ?? DateTime.now();
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.isEditing, required this.canClose});

  final bool isEditing;
  final bool canClose;

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
          onPressed: canClose ? () => Navigator.of(context).pop() : null,
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

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppPalette.blueSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 21, color: AppPalette.blue),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppPalette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChoiceRow extends StatelessWidget {
  const _QuickChoiceRow({
    required this.label,
    required this.choices,
    required this.onSelected,
  });

  final String label;
  final List<String> choices;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppPalette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: choices
                  .map(
                    (choice) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ActionChip(
                        label: Text(choice),
                        backgroundColor: AppPalette.background,
                        side: const BorderSide(color: AppPalette.line),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onSelected(choice),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ],
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
  const _PhotoProofSwitch({
    required this.value,
    required this.onChanged,
    this.unavailableMessage,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? unavailableMessage;

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
          unavailableMessage ?? '켜면 완료할 때 사진 없이 제출할 수 없어요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
