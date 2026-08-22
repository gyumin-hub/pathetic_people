import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../view_models/profile_view_model.dart';

class ProfileContentTabs extends StatelessWidget {
  const ProfileContentTabs({
    required this.selectedContent,
    required this.onSelected,
    super.key,
  });

  final ProfileContent selectedContent;
  final ValueChanged<ProfileContent> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      margin: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        color: AppPalette.background,
        border: Border(
          top: BorderSide(color: AppPalette.line),
          bottom: BorderSide(color: AppPalette.line),
        ),
      ),
      child: Row(
        children: ProfileContent.values
            .map((content) {
              final isSelected = content == selectedContent;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(content),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _iconFor(content),
                        color: isSelected ? AppPalette.ink : AppPalette.muted,
                        size: 23,
                      ),
                      if (isSelected)
                        const Positioned(
                          left: 24,
                          right: 24,
                          bottom: 0,
                          child: ColoredBox(
                            color: AppPalette.ink,
                            child: SizedBox(height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  IconData _iconFor(ProfileContent content) {
    return switch (content) {
      ProfileContent.posts => Icons.grid_on_rounded,
      ProfileContent.stats => Icons.insights_outlined,
      ProfileContent.saved => Icons.bookmark_border_rounded,
    };
  }
}
