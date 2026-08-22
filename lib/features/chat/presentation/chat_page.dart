import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/page_header.dart';
import '../../../domain/models/chat.dart';
import '../view_models/chat_view_model.dart';
import 'conversation_page.dart';
import 'widgets/chat_room_avatar.dart';
import 'widgets/chat_room_tile.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.viewModel, super.key});

  final ChatViewModel viewModel;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: widget.viewModel,
          builder: (context, _) {
            final rooms = widget.viewModel.rooms;
            final systemRoom = _systemRoomIn(rooms);
            final conversations = rooms
                .where((room) => room.kind != ChatRoomKind.system)
                .toList(growable: false);

            return Column(
              children: [
                PageHeader(
                  title: '메시지',
                  eyebrow: widget.viewModel.totalUnread == 0
                      ? '모든 메시지를 확인했어요'
                      : '안 읽은 메시지 ${widget.viewModel.totalUnread}개',
                  trailing: IconButton(
                    tooltip: '새 대화',
                    onPressed: _showNewChatSheet,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.viewModel.search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: '이름 또는 대화 내용 검색',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppPalette.muted,
                      ),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '검색어 지우기',
                              onPressed: () {
                                _searchController.clear();
                                widget.viewModel.search('');
                              },
                              icon: const Icon(
                                Icons.cancel_rounded,
                                color: AppPalette.muted,
                                size: 19,
                              ),
                            ),
                    ),
                  ),
                ),
                _ChatFilterBar(
                  selectedFilter: widget.viewModel.filter,
                  onSelected: widget.viewModel.selectFilter,
                ),
                const SizedBox(height: 10),
                if (systemRoom != null)
                  _SystemFailureBanner(
                    room: systemRoom,
                    onTap: () => _openRoom(systemRoom),
                  ),
                Expanded(
                  child: conversations.isEmpty
                      ? _EmptyChatResult(
                          hasQuery: _searchController.text.isNotEmpty,
                        )
                      : ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.only(
                            top: systemRoom == null ? 4 : 8,
                            bottom: 24,
                          ),
                          itemCount: conversations.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  5,
                                ),
                                child: Text(
                                  '대화 ${conversations.length}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              );
                            }
                            final room = conversations[index - 1];
                            return ChatRoomTile(
                              room: room,
                              onTap: () => _openRoom(room),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  ChatRoom? _systemRoomIn(List<ChatRoom> rooms) {
    for (final room in rooms) {
      if (room.kind == ChatRoomKind.system) return room;
    }
    return null;
  }

  void _openRoom(ChatRoom room) {
    FocusScope.of(context).unfocus();
    widget.viewModel.openRoom(room.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ConversationPage(viewModel: widget.viewModel, room: room),
      ),
    );
  }

  Future<void> _showNewChatSheet() async {
    final action = await showModalBottomSheet<_NewChatAction>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('새 대화', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                '친구와 직접 대화하거나 함께 인증할 그룹을 만드세요.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppPalette.blueSoft,
                  foregroundColor: AppPalette.blue,
                  child: Icon(Icons.person_add_alt_1_rounded),
                ),
                title: const Text('1:1 대화 시작'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_NewChatAction.direct),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppPalette.surfaceStrong,
                  foregroundColor: AppPalette.ink,
                  child: Icon(Icons.group_add_rounded),
                ),
                title: const Text('그룹 만들기'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_NewChatAction.group),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _NewChatAction.direct:
        await _selectDirectChat();
      case _NewChatAction.group:
        await _createGroupChat();
    }
  }

  Future<void> _selectDirectChat() async {
    final userId = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        final users = widget.viewModel.availableUsers;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('친구 선택', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              ...users.map((user) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AppAvatar.user(user, size: 44),
                  title: Text(user.displayName),
                  subtitle: Text('@${user.username}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(sheetContext).pop(user.id),
                );
              }),
            ],
          ),
        );
      },
    );
    if (!mounted || userId == null) return;
    final room = widget.viewModel.createDirectRoom(userId);
    _openRoom(room);
  }

  Future<void> _createGroupChat() async {
    final titleController = TextEditingController();
    final selectedUserIds = <String>{};
    final draft = await showModalBottomSheet<_GroupChatDraft>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.78,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '새 그룹',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: '그룹 이름'),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '함께할 친구',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: widget.viewModel.availableUsers
                            .map((user) {
                              final isSelected = selectedUserIds.contains(
                                user.id,
                              );
                              return CheckboxListTile(
                                value: isSelected,
                                contentPadding: EdgeInsets.zero,
                                secondary: AppAvatar.user(user, size: 40),
                                title: Text(user.displayName),
                                subtitle: Text('@${user.username}'),
                                onChanged: (value) {
                                  setSheetState(() {
                                    if (value ?? false) {
                                      selectedUserIds.add(user.id);
                                    } else {
                                      selectedUserIds.remove(user.id);
                                    }
                                  });
                                },
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            titleController.text.trim().isEmpty ||
                                selectedUserIds.isEmpty
                            ? null
                            : () {
                                Navigator.of(sheetContext).pop(
                                  _GroupChatDraft(
                                    title: titleController.text.trim(),
                                    userIds: selectedUserIds.toList(),
                                  ),
                                );
                              },
                        child: Text('${selectedUserIds.length}명과 그룹 만들기'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    titleController.dispose();
    if (!mounted || draft == null) return;
    final room = widget.viewModel.createGroupRoom(draft.title, draft.userIds);
    _openRoom(room);
  }
}

enum _NewChatAction { direct, group }

class _GroupChatDraft {
  const _GroupChatDraft({required this.title, required this.userIds});

  final String title;
  final List<String> userIds;
}

class _ChatFilterBar extends StatelessWidget {
  const _ChatFilterBar({
    required this.selectedFilter,
    required this.onSelected,
  });

  final ChatFilter selectedFilter;
  final ValueChanged<ChatFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: ChatFilter.values
            .map((filter) {
              final isSelected = filter == selectedFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_labelFor(filter)),
                  selected: isSelected,
                  onSelected: (_) => onSelected(filter),
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected ? AppPalette.ink : AppPalette.line,
                  ),
                  selectedColor: AppPalette.ink,
                  backgroundColor: AppPalette.background,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppPalette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: const StadiumBorder(),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  String _labelFor(ChatFilter filter) {
    return switch (filter) {
      ChatFilter.all => '전체',
      ChatFilter.direct => '1:1',
      ChatFilter.group => '그룹',
    };
  }
}

class _SystemFailureBanner extends StatelessWidget {
  const _SystemFailureBanner({required this.room, required this.onTap});

  final ChatRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
      child: Material(
        color: AppPalette.redSoft,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ChatRoomAvatar(room: room, size: 46),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '공개처형 알림',
                        style: TextStyle(
                          color: AppPalette.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        room.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (room.unreadCount > 0)
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.red,
                    ),
                    child: Text(
                      '${room.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppPalette.red,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChatResult extends StatelessWidget {
  const _EmptyChatResult({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 42, color: AppPalette.muted),
            const SizedBox(height: 14),
            Text(
              hasQuery ? '검색 결과가 없어요' : '아직 시작한 대화가 없어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              hasQuery ? '다른 이름이나 대화 내용을 검색해 보세요.' : '친구와 서로의 계획을 인증해 보세요.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
