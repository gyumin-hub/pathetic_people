import 'package:flutter/material.dart';

import '../../domain/models/feed_post.dart';
import '../theme/app_palette.dart';

class MediaArtwork extends StatelessWidget {
  const MediaArtwork({
    required this.kind,
    required this.headline,
    required this.outcome,
    this.label,
    this.aspectRatio = 4 / 5,
    this.isVideo = false,
    this.compact = false,
    super.key,
  });

  final MediaKind kind;
  final String headline;
  final PostOutcome outcome;
  final String? label;
  final double aspectRatio;
  final bool isVideo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForKind(kind);
    final foreground = _usesDarkText(kind) ? AppPalette.ink : Colors.white;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: compact ? -26 : -70,
              bottom: compact ? -18 : 24,
              child: Transform.rotate(
                angle: -0.42,
                child: Container(
                  width: compact ? 120 : 280,
                  height: compact ? 48 : 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(80),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 10 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (label != null)
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 5 : 8,
                              vertical: compact ? 3 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              label!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: foreground,
                                fontSize: compact ? 10 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (label == null && isVideo) const Spacer(),
                      if (isVideo)
                        Icon(
                          Icons.play_arrow_rounded,
                          color: foreground,
                          size: compact ? 18 : 24,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    headline,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: compact ? 18 : 34,
                      height: 1.03,
                      fontWeight: FontWeight.w700,
                      letterSpacing: compact ? -0.5 : -1.3,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    Text(
                      outcome == PostOutcome.failure
                          ? 'NOT COMPLETED'
                          : 'COMPLETED',
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _colorsForKind(MediaKind kind) {
    return switch (kind) {
      MediaKind.morning => const [Color(0xFF59636E), Color(0xFF1D232A)],
      MediaKind.workout => const [Color(0xFF343D48), Color(0xFF15191E)],
      MediaKind.study => const [AppPalette.blue, Color(0xFF1E5FC1)],
      MediaKind.reading => const [Color(0xFFFFF0F1), Color(0xFFF7DDE0)],
      MediaKind.journal => const [Color(0xFFE8F3FF), Color(0xFFCFE2F8)],
      MediaKind.water => const [Color(0xFF56A5F8), Color(0xFF125BB8)],
    };
  }

  bool _usesDarkText(MediaKind kind) {
    return kind == MediaKind.reading || kind == MediaKind.journal;
  }
}
