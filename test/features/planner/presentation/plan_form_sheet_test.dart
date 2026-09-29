import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/features/planner/presentation/plan_form_sheet.dart';

void main() {
  testWidgets('새 계획은 선택한 날짜의 현재 시각과 1시간 뒤 마감을 제안한다', (tester) async {
    final now = DateTime(2026, 9, 19, 19, 11, 42);

    await tester.pumpWidget(_app(now: now, initialDate: DateTime(2026, 9, 19)));

    expect(find.textContaining('오후 7:11'), findsOneWidget);
    expect(find.textContaining('오후 8:11'), findsOneWidget);
    expect(find.text('지금'), findsOneWidget);
    expect(find.text('+15분'), findsOneWidget);
    expect(find.text('30분'), findsOneWidget);
  });

  testWidgets('빠른 설정으로 시작과 완료 시간을 타이핑 없이 바꾼다', (tester) async {
    final now = DateTime(2026, 9, 19, 19, 11, 42);

    await tester.pumpWidget(_app(now: now, initialDate: DateTime(2026, 9, 19)));

    await tester.tap(find.text('+15분'));
    await tester.pump();
    expect(find.textContaining('오후 7:26'), findsOneWidget);
    expect(find.textContaining('오후 8:26'), findsOneWidget);

    await tester.tap(find.text('30분'));
    await tester.pump();
    expect(find.textContaining('오후 7:56'), findsOneWidget);
  });

  testWidgets('시간 카드는 날짜와 시간을 함께 고르는 휠 바텀시트를 연다', (tester) async {
    final now = DateTime(2026, 9, 19, 19, 11, 42);

    await tester.pumpWidget(_app(now: now, initialDate: DateTime(2026, 9, 19)));

    await tester.tap(find.byKey(const ValueKey('startDateTimePicker')));
    await tester.pumpAndSettle();

    expect(find.text('언제 시작할까요?'), findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(find.text('이 시간으로 선택'), findsOneWidget);
  });
}

Widget _app({required DateTime now, required DateTime initialDate}) {
  return MaterialApp(
    home: Scaffold(
      body: PlanFormSheet(
        initialDate: initialDate,
        supportsMediaUpload: false,
        clock: () => now,
        onSubmit: (_) async => null,
      ),
    ),
  );
}
