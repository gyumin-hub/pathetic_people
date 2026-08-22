import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../domain/models/plan_item.dart';

extension PlanCategoryUi on PlanCategory {
  String get label {
    return switch (this) {
      PlanCategory.health => '건강',
      PlanCategory.study => '공부',
      PlanCategory.routine => '루틴',
      PlanCategory.record => '기록',
    };
  }

  IconData get icon {
    return switch (this) {
      PlanCategory.health => Icons.favorite_outline_rounded,
      PlanCategory.study => Icons.menu_book_rounded,
      PlanCategory.routine => Icons.repeat_rounded,
      PlanCategory.record => Icons.edit_note_rounded,
    };
  }

  Color get color {
    return switch (this) {
      PlanCategory.health => AppPalette.blue,
      PlanCategory.study => const Color(0xFF6857D9),
      PlanCategory.routine => AppPalette.green,
      PlanCategory.record => const Color(0xFF59636E),
    };
  }

  Color get softColor {
    return switch (this) {
      PlanCategory.health => AppPalette.blueSoft,
      PlanCategory.study => const Color(0xFFF0EDFF),
      PlanCategory.routine => const Color(0xFFE9F8F2),
      PlanCategory.record => AppPalette.surfaceStrong,
    };
  }
}

extension PlanProgressUi on PlanProgress {
  String get label {
    return switch (this) {
      PlanProgress.pending => '진행 예정',
      PlanProgress.completed => '달성',
      PlanProgress.failed => '미달성',
    };
  }

  Color get color {
    return switch (this) {
      PlanProgress.pending => AppPalette.muted,
      PlanProgress.completed => AppPalette.green,
      PlanProgress.failed => AppPalette.red,
    };
  }

  Color get softColor {
    return switch (this) {
      PlanProgress.pending => AppPalette.surface,
      PlanProgress.completed => const Color(0xFFE9F8F2),
      PlanProgress.failed => AppPalette.redSoft,
    };
  }
}
