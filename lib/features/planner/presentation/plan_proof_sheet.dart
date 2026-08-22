import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/models/plan_item.dart';
import 'planner_ui_extensions.dart';

class PlanProofSheet extends StatefulWidget {
  const PlanProofSheet({required this.plan, required this.type, super.key});

  final PlanItem plan;
  final PlanProofType type;

  static Future<PlanProofDraft?> show(
    BuildContext context, {
    required PlanItem plan,
    required PlanProofType type,
  }) {
    return showModalBottomSheet<PlanProofDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PlanProofSheet(plan: plan, type: type),
    );
  }

  @override
  State<PlanProofSheet> createState() => _PlanProofSheetState();
}

class _PlanProofSheetState extends State<PlanProofSheet> {
  final _picker = ImagePicker();
  late final TextEditingController _noteController;
  late bool _sharedToFeed;
  Uint8List? _mediaBytes;
  String? _mediaName;
  bool _isPicking = false;

  bool get _isCompletion => widget.type == PlanProofType.completion;

  bool get _requiresPhoto =>
      _isCompletion && (widget.plan.photoProofRequired || _sharedToFeed);

  bool get _canSubmit =>
      !_isPicking && (!_requiresPhoto || _mediaBytes?.isNotEmpty == true);

  bool get _supportsCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _showsShareSwitch {
    return _isCompletion ||
        widget.plan.visibility == PlanVisibility.publicChallenge;
  }

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _sharedToFeed = widget.plan.visibility == PlanVisibility.publicChallenge;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreLostImage());
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.top - bottomInset - 12;
    final preferredHeight = mediaQuery.size.height * 0.88;
    final sheetHeight = availableHeight < preferredHeight
        ? availableHeight
        : preferredHeight;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: sheetHeight,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProofHeader(type: widget.type),
              const SizedBox(height: 20),
              _PlanSummary(plan: widget.plan),
              const SizedBox(height: 24),
              Text(
                '인증 사진${_requiresPhoto ? ' 필수' : ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _requiresPhoto
                    ? _sharedToFeed && !widget.plan.photoProofRequired
                          ? '피드에 공유하려면 완료 사진을 첨부해 주세요.'
                          : '이 계획은 완료 사진을 첨부해야 제출할 수 있어요.'
                    : '필요하면 실행 장면을 함께 남겨 보세요.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (_mediaBytes == null)
                _EmptyImagePreview(isPicking: _isPicking)
              else
                _ImagePreview(
                  bytes: _mediaBytes!,
                  mediaName: _mediaName,
                  onRemove: _isPicking ? null : _removeImage,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPicking
                          ? null
                          : _supportsCamera
                          ? () => _pickImage(ImageSource.camera)
                          : _showCameraUnsupported,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('카메라'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPicking
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('앨범'),
                    ),
                  ),
                ],
              ),
              if (!_supportsCamera) ...[
                const SizedBox(height: 7),
                Text(
                  '현재 환경에서는 카메라 촬영을 지원하지 않아요. '
                  '앨범에서 사진을 선택해 주세요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_requiresPhoto && _mediaBytes == null) ...[
                const SizedBox(height: 8),
                const Text(
                  '완료 인증 사진을 추가해야 제출할 수 있어요.',
                  style: TextStyle(
                    color: AppPalette.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('한 줄 메모', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLength: 60,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: '예: 핑계 없이 예정대로 끝냈다',
                  counterText: '',
                ),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
              if (_showsShareSwitch) ...[
                const SizedBox(height: 14),
                _ShareSwitch(
                  type: widget.type,
                  visibility: widget.plan.visibility,
                  value: _sharedToFeed,
                  onChanged: (value) {
                    setState(() => _sharedToFeed = value);
                  },
                ),
              ] else ...[
                const SizedBox(height: 14),
                const _PrivateStartNotice(),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isPicking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('${widget.type.label} 제출'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera && !_supportsCamera) {
      _showCameraUnsupported();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isPicking = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (file != null) await _loadImage(file);
    } catch (_) {
      _showError('사진을 불러오지 못했어요. 권한과 파일 상태를 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _restoreLostImage() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.exception != null) {
        _showError('이전에 선택한 사진을 복구하지 못했어요.');
        return;
      }
      final file = response.file ?? response.files?.lastOrNull;
      if (file != null) await _loadImage(file);
    } catch (_) {
      _showError('이전 사진 선택 결과를 복구하지 못했어요.');
    }
  }

  Future<void> _loadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw StateError('빈 이미지 파일입니다.');
    if (!mounted) return;
    setState(() {
      _mediaBytes = bytes;
      _mediaName = file.name;
    });
  }

  void _removeImage() {
    setState(() {
      _mediaBytes = null;
      _mediaName = null;
    });
  }

  void _showCameraUnsupported() {
    _showError(
      '이 기기에서는 카메라 촬영을 지원하지 않아요. '
      '앨범에서 선택해 주세요.',
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_canSubmit) {
      _showError('완료 인증 사진을 먼저 추가해 주세요.');
      return;
    }
    Navigator.of(context).pop(
      PlanProofDraft(
        type: widget.type,
        mediaBytes: _mediaBytes,
        mediaName: _mediaName,
        note: _noteController.text.trim(),
        sharedToFeed: _sharedToFeed,
      ),
    );
  }
}

class _ProofHeader extends StatelessWidget {
  const _ProofHeader({required this.type});

  final PlanProofType type;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.label,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 3),
              Text(
                type == PlanProofType.start
                    ? '지금 시작한 사실을 기록해요.'
                    : '결과를 남기고 계획을 마무리해요.',
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

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final PlanItem plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: plan.visibility.softColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              plan.visibility.icon,
              size: 19,
              color: plan.visibility.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  plan.visibility.label,
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

class _EmptyImagePreview extends StatelessWidget {
  const _EmptyImagePreview({required this.isPicking});

  final bool isPicking;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.line),
      ),
      child: isPicking
          ? const CircularProgressIndicator(strokeWidth: 2)
          : const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: AppPalette.muted,
                ),
                SizedBox(height: 7),
                Text(
                  '카메라나 앨범에서 사진 추가',
                  style: TextStyle(color: AppPalette.muted, fontSize: 12),
                ),
              ],
            ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.bytes,
    required this.mediaName,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String? mediaName;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 190,
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
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              tooltip: '사진 제거',
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.58),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close_rounded, size: 19),
            ),
          ),
          if (mediaName != null && mediaName!.isNotEmpty)
            Positioned(
              left: 10,
              right: 56,
              bottom: 10,
              child: Text(
                mediaName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShareSwitch extends StatelessWidget {
  const _ShareSwitch({
    required this.type,
    required this.visibility,
    required this.value,
    required this.onChanged,
  });

  final PlanProofType type;
  final PlanVisibility visibility;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isStart = type == PlanProofType.start;
    return Material(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(
          isStart ? '도전 중 상태 공개' : '피드에도 공유',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          isStart
              ? '시작 인증은 도전 중 표시만 남기고 피드 게시물은 만들지 않아요.'
              : visibility == PlanVisibility.private
              ? '켜면 개인 계획의 성공 결과도 피드에 공유해요.'
              : '완료 사진과 메모를 성공 게시물로 공유해요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _PrivateStartNotice extends StatelessWidget {
  const _PrivateStartNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppPalette.muted,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '개인 계획의 시작 인증은 나만 볼 수 있어요.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
