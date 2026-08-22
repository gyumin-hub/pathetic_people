import 'feed_post.dart';

class ExploreItem {
  const ExploreItem({
    required this.id,
    required this.title,
    required this.label,
    required this.category,
    required this.mediaKind,
    required this.outcome,
    required this.isVideo,
    required this.popularity,
  });

  final String id;
  final String title;
  final String label;
  final String category;
  final MediaKind mediaKind;
  final PostOutcome outcome;
  final bool isVideo;
  final int popularity;
}
