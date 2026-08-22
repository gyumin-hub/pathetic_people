import 'dart:typed_data';

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
    this.sourcePlanId,
    this.mediaBytes,
    this.proofNote,
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
  final String? sourcePlanId;
  final Uint8List? mediaBytes;
  final String? proofNote;

  List<PostComment> get comments => _comments;

  FeedPost copyWith({
    String? authorId,
    PostOutcome? outcome,
    MediaKind? mediaKind,
    String? planTitle,
    String? mediaHeadline,
    String? mentorMessage,
    DateTime? createdAt,
    int? likes,
    List<PostComment>? comments,
    bool? isLiked,
    bool? isSaved,
    int? streakDays,
    bool clearStreakDays = false,
    String? sourcePlanId,
    bool clearSourcePlanId = false,
    Uint8List? mediaBytes,
    bool clearMediaBytes = false,
    String? proofNote,
    bool clearProofNote = false,
  }) {
    return FeedPost(
      id: id,
      authorId: authorId ?? this.authorId,
      outcome: outcome ?? this.outcome,
      mediaKind: mediaKind ?? this.mediaKind,
      planTitle: planTitle ?? this.planTitle,
      mediaHeadline: mediaHeadline ?? this.mediaHeadline,
      mentorMessage: mentorMessage ?? this.mentorMessage,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? _comments,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      streakDays: clearStreakDays ? null : streakDays ?? this.streakDays,
      sourcePlanId: clearSourcePlanId
          ? null
          : sourcePlanId ?? this.sourcePlanId,
      mediaBytes: clearMediaBytes ? null : mediaBytes ?? this.mediaBytes,
      proofNote: clearProofNote ? null : proofNote ?? this.proofNote,
    );
  }
}
