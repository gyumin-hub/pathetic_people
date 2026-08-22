import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../domain/models/chat.dart';

class ChatRoomAvatar extends StatelessWidget {
  const ChatRoomAvatar({required this.room, this.size = 52, super.key});

  final ChatRoom room;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (room.kind == ChatRoomKind.system) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppPalette.redSoft,
        ),
        child: Icon(
          Icons.campaign_rounded,
          color: AppPalette.red,
          size: size * 0.48,
        ),
      );
    }

    if (room.kind == ChatRoomKind.group && room.memberInitials.length > 1) {
      return _GroupAvatar(room: room, size: size);
    }

    final compactTitle = room.title.trim();
    final initials = room.memberInitials.isEmpty
        ? compactTitle.isEmpty
              ? '?'
              : compactTitle.substring(0, 1).toUpperCase()
        : room.memberInitials.first;
    return AppAvatar(initials: initials, seed: room.id.hashCode, size: size);
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.room, required this.size});

  final ChatRoom room;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarSize = size * 0.68;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: _BorderedAvatar(
              initials: room.memberInitials.first,
              seed: room.id.hashCode,
              size: avatarSize,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _BorderedAvatar(
              initials: room.memberInitials[1],
              seed: room.id.hashCode + 1,
              size: avatarSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _BorderedAvatar extends StatelessWidget {
  const _BorderedAvatar({
    required this.initials,
    required this.seed,
    required this.size,
  });

  final String initials;
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppPalette.background,
      ),
      child: AppAvatar(initials: initials, seed: seed, size: size - 3),
    );
  }
}
