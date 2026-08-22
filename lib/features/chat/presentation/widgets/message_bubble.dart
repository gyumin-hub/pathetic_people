import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../domain/models/chat.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _SystemMessage(message: message);
    return _UserMessage(message: message);
  }
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.redSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.red.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.campaign_rounded, color: AppPalette.red, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '독설가 멘토',
                    style: TextStyle(
                      color: AppPalette.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppDateUtils.hourMinute(message.sentAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.red.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Padding(
      padding: EdgeInsets.fromLTRB(isMine ? 68 : 16, 4, isMine ? 16 : 68, 4),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            AppAvatar(
              initials: _senderInitials(message.senderId),
              seed: message.senderId.hashCode,
              size: 30,
            ),
            const SizedBox(width: 8),
          ],
          if (isMine) ...[
            Text(
              AppDateUtils.hourMinute(message.sentAt),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppPalette.blue : AppPalette.surfaceStrong,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 5),
                  bottomRight: Radius.circular(isMine ? 5 : 18),
                ),
              ),
              child: Text(
                message.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isMine ? Colors.white : AppPalette.ink,
                  height: 1.42,
                ),
              ),
            ),
          ),
          if (!isMine) ...[
            const SizedBox(width: 6),
            Text(
              AppDateUtils.hourMinute(message.sentAt),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  String _senderInitials(String senderId) {
    final compact = senderId.trim();
    if (compact.isEmpty) return '?';
    return compact.length == 1
        ? compact.toUpperCase()
        : compact.substring(0, 2).toUpperCase();
  }
}
