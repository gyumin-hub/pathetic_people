enum ChatRoomKind { direct, group, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.message,
    required this.sentAt,
    required this.isMine,
    required this.isSystem,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String message;
  final DateTime sentAt;
  final bool isMine;
  final bool isSystem;
}

class ChatRoom {
  ChatRoom({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required List<String> memberInitials,
    required this.updatedAt,
    required this.unreadCount,
  }) : _memberInitials = List<String>.unmodifiable(memberInitials);

  final String id;
  final String title;
  final String subtitle;
  final ChatRoomKind kind;
  final List<String> _memberInitials;
  final DateTime updatedAt;
  final int unreadCount;

  List<String> get memberInitials => _memberInitials;

  ChatRoom copyWith({String? subtitle, DateTime? updatedAt, int? unreadCount}) {
    return ChatRoom(
      id: id,
      title: title,
      subtitle: subtitle ?? this.subtitle,
      kind: kind,
      memberInitials: _memberInitials,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
