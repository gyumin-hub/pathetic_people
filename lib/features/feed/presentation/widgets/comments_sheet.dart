import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../domain/models/feed_post.dart';
import '../../view_models/feed_view_model.dart';

Future<void> showCommentsSheet(
  BuildContext context, {
  required FeedViewModel viewModel,
  required FeedPost initialPost,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _CommentsSheet(viewModel: viewModel, initialPost: initialPost),
  );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.viewModel, required this.initialPost});

  final FeedViewModel viewModel;
  final FeedPost initialPost;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onTextChanged);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final nextCanSubmit = _controller.text.trim().isNotEmpty;
    if (_canSubmit == nextCanSubmit) return;
    setState(() => _canSubmit = nextCanSubmit);
  }

  void _submit() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    widget.viewModel.addComment(widget.initialPost.id, message);
    _controller.clear();
    _focusNode.requestFocus();
  }

  FeedPost _currentPost() {
    for (final post in widget.viewModel.posts) {
      if (post.id == widget.initialPost.id) return post;
    }
    return widget.initialPost;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '댓글',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '닫기',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  final post = _currentPost();
                  if (post.comments.isEmpty) {
                    return _EmptyComments(scrollController: scrollController);
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    itemCount: post.comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      return _CommentRow(comment: post.comments[index]);
                    },
                  );
                },
              ),
            ),
            const Divider(),
            AnimatedPadding(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                12,
                10 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Row(
                children: [
                  AppAvatar.user(widget.viewModel.currentUser, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: '놀리거나 응원하는 댓글 추가',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: const Text('게시'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final avatarSeed = comment.authorName.hashCode;
    final initials = String.fromCharCodes(comment.authorName.runes.take(2));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(initials: initials, seed: avatarSeed, size: 34),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.authorName,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    AppDateUtils.relativeTime(comment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(comment.message),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      children: [
        const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 42,
          color: AppPalette.muted,
        ),
        const SizedBox(height: 14),
        Text(
          '아직 댓글이 없어요',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '첫 번째로 놀리거나 응원해 보세요.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
