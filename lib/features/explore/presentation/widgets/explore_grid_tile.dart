import 'package:flutter/material.dart';

import '../../../../core/widgets/media_artwork.dart';
import '../../../../domain/models/explore_item.dart';

class ExploreGridTile extends StatelessWidget {
  const ExploreGridTile({required this.item, required this.onTap, super.key});

  final ExploreItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.category}, ${item.label}, ${item.title}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: MediaArtwork(
            kind: item.mediaKind,
            headline: item.title,
            outcome: item.outcome,
            label: item.label,
            aspectRatio: 1,
            isVideo: item.isVideo,
            compact: true,
          ),
        ),
      ),
    );
  }
}
