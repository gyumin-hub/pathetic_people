enum PostOutcome { success, failure }

enum MediaKind { morning, workout, study, reading, journal, water }

class PostComment {
  const PostComment({
    required this.id,
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String message;
  final DateTime createdAt;
}

class FeedPost {
  FeedPost({
    required this.id,
    required this.authorId,
    required this.outcome,
    required this.mediaKind,
    required this.planTitle,
    required this.mediaHeadline,
    required this.mentorMessage,
    required this.createdAt,
    required this.likes,
    required List<PostComment> comments,
    required this.isLiked,
    required this.isSaved,
    this.streakDays,
  }) : _comments = List<PostComment>.unmodifiable(comments);

  final String id;
  final String authorId;
  final PostOutcome outcome;
  final MediaKind mediaKind;
  final String planTitle;
  final String mediaHeadline;
  final String mentorMessage;
  final DateTime createdAt;
  final int likes;
  final List<PostComment> _comments;
  final bool isLiked;
  final bool isSaved;
  final int? streakDays;

  List<PostComment> get comments => _comments;

  FeedPost copyWith({
    int? likes,
    List<PostComment>? comments,
    bool? isLiked,
    bool? isSaved,
  }) {
    return FeedPost(
      id: id,
      authorId: authorId,
      outcome: outcome,
      mediaKind: mediaKind,
      planTitle: planTitle,
      mediaHeadline: mediaHeadline,
      mentorMessage: mentorMessage,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? _comments,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      streakDays: streakDays,
    );
  }
}
