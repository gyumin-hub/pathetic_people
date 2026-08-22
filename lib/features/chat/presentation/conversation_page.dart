import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/models/chat.dart';
import '../view_models/chat_view_model.dart';
import 'widgets/chat_room_avatar.dart';
import 'widgets/message_bubble.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    required this.viewModel,
    required this.room,
    super.key,
  });

  final ChatViewModel viewModel;
  final ChatRoom room;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageFocusNode = FocusNode();
  int _lastMessageCount = -1;

  @override
  void initState() {
    super.initState();
    widget.viewModel.openRoom(widget.room.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ChatRoomAvatar(room: widget.room, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _roomDescription(widget.room),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '대화 정보',
            onPressed: _showRoomInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: widget.viewModel,
              builder: (context, _) {
                final messages = widget.viewModel.messagesFor(widget.room.id);
                if (_lastMessageCount != messages.length) {
                  _lastMessageCount = messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom(animated: _lastMessageCount > 1);
                  });
                }

                if (messages.isEmpty) {
                  return const _EmptyConversation();
                }

                return ListView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 20),
                  children: _messageWidgets(messages),
                );
              },
            ),
          ),
          _MessageComposer(
            controller: _messageController,
            focusNode: _messageFocusNode,
            onAttach: _showAttachmentSheet,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  List<Widget> _messageWidgets(List<ChatMessage> messages) {
    final children = <Widget>[];
    DateTime? previousDate;
    for (final message in messages) {
      if (previousDate == null ||
          !AppDateUtils.isSameDay(previousDate, message.sentAt)) {
        children.add(_DateDivider(date: message.sentAt));
      }
      children.add(MessageBubble(key: ValueKey(message.id), message: message));
      previousDate = message.sentAt;
    }
    return children;
  }

  String _roomDescription(ChatRoom room) {
    return switch (room.kind) {
      ChatRoomKind.direct => '1:1 대화',
      ChatRoomKind.group => '그룹 대화',
      ChatRoomKind.system => '실패 알림 채널',
    };
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    widget.viewModel.sendMessage(widget.room.id, message);
    _messageController.clear();
    _messageFocusNode.requestFocus();
  }

  void _scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('보내기', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachmentAction(
                    icon: Icons.image_outlined,
                    label: '사진',
                    onTap: () => _closeSheetWithNotice(
                      sheetContext,
                      '실제 사진 업로드는 스토리지 API 연결 후 사용할 수 있어요.',
                    ),
                  ),
                  _AttachmentAction(
                    icon: Icons.task_alt_rounded,
                    label: '계획 인증',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _showPlanAttachmentSheet();
                    },
                  ),
                  _AttachmentAction(
                    icon: Icons.location_on_outlined,
                    label: '위치',
                    onTap: () => _closeSheetWithNotice(
                      sheetContext,
                      '실제 위치 공유는 위치 권한과 지도 API 연결 후 사용할 수 있어요.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlanAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        final plans = widget.viewModel.completedPlans.take(10).toList();
        return FractionallySizedBox(
          heightFactor: 0.62,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '계획 인증 보내기',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '완료한 계획을 이 대화방에 공유해요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: plans.isEmpty
                      ? const Center(child: Text('아직 완료한 계획이 없어요.'))
                      : ListView.separated(
                          itemCount: plans.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: AppPalette.blueSoft,
                                foregroundColor: AppPalette.blue,
                                child: Icon(Icons.task_alt_rounded),
                              ),
                              title: Text(plan.title),
                              subtitle: Text(
                                '${AppDateUtils.fullDate(plan.scheduledAt)} · +${plan.experiencePoint} XP',
                              ),
                              onTap: () {
                                widget.viewModel.sendMessage(
                                  widget.room.id,
                                  '[계획 인증] ${plan.title} · +${plan.experiencePoint} XP',
                                );
                                Navigator.of(sheetContext).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRoomInfo() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatRoomAvatar(room: widget.room, size: 72),
              const SizedBox(height: 14),
              Text(
                widget.room.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                _roomDescription(widget.room),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted),
              ),
              const SizedBox(height: 22),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_none_rounded),
                title: const Text('알림 설정'),
                trailing: Switch(value: true, onChanged: null),
              ),
            ],
          ),
        );
      },
    );
  }

  void _closeSheetWithNotice(BuildContext sheetContext, String message) {
    Navigator.of(sheetContext).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(indent: 36, endIndent: 12)),
          Text(
            AppDateUtils.fullDate(date),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          const Expanded(child: Divider(indent: 12, endIndent: 36)),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.background,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppPalette.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: '첨부',
                onPressed: onAttach,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: '메시지 보내기',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend = value.text.trim().isNotEmpty;
                  return IconButton.filled(
                    tooltip: '전송',
                    onPressed: canSend ? onSend : null,
                    style: IconButton.styleFrom(
                      backgroundColor: canSend
                          ? AppPalette.blue
                          : AppPalette.surfaceStrong,
                      disabledBackgroundColor: AppPalette.surfaceStrong,
                    ),
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                      color: canSend ? Colors.white : AppPalette.muted,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentAction extends StatelessWidget {
  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppPalette.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.waving_hand_outlined,
            color: AppPalette.muted,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text('첫 메시지를 보내 보세요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '서로의 계획을 공유하면 포기하기 어려워져요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted),
          ),
        ],
      ),
    );
  }
}
