import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/domain/models/plan_item.dart';
import 'package:pathetic_people/features/planner/presentation/plan_proof_sheet.dart';

void main() {
  testWidgets('public proof sharing is off until the user opts in', (
    tester,
  ) async {
    await tester.pumpWidget(_app(onSubmit: (_) async => null));

    final shareSwitch = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(shareSwitch.value, isFalse);
  });

  testWidgets('submission blocks duplicate taps and keeps an error in place', (
    tester,
  ) async {
    final completer = Completer<String?>();
    var submitCount = 0;
    await tester.pumpWidget(
      _app(
        onSubmit: (_) {
          submitCount += 1;
          return completer.future;
        },
      ),
    );

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, '시작 인증 제출'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, '시작 인증 제출'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(submitCount, 1);
    final closeButton = find.widgetWithIcon(IconButton, Icons.close_rounded);
    expect(tester.widget<IconButton>(closeButton).onPressed, isNull);

    completer.complete('서버 저장 실패');
    await tester.pump();

    expect(find.text('서버 저장 실패'), findsOneWidget);
    expect(tester.widget<IconButton>(closeButton).onPressed, isNotNull);
  });
}

Widget _app({
  required Future<String?> Function(PlanProofDraft draft) onSubmit,
}) {
  final now = DateTime.now();
  return MaterialApp(
    home: Scaffold(
      body: PlanProofSheet(
        plan: PlanItem(
          id: 'plan-1',
          title: '공개 도전',
          scheduledAt: now.subtract(const Duration(minutes: 5)),
          verificationDueAt: now.add(const Duration(hours: 1)),
          category: PlanCategory.routine,
          recurrence: '없음',
          experiencePoint: 10,
          progress: PlanProgress.pending,
          visibility: PlanVisibility.publicChallenge,
          photoProofRequired: false,
        ),
        type: PlanProofType.start,
        supportsMediaUpload: false,
        onSubmit: onSubmit,
      ),
    ),
  );
}
