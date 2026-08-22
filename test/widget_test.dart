import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathetic_people/app/motive_app.dart';

void main() {
  testWidgets('5개 탭을 전환할 수 있다', (tester) async {
    await tester.pumpWidget(const MotiveApp());
    await tester.pumpAndSettle();

    expect(find.text('motive'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('탐색'), findsWidgets);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('PLANNER'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('메시지'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('pathetic_me'), findsOneWidget);
  });

  testWidgets('360px 화면에서도 주요 탭에 레이아웃 오류가 없다', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MotiveApp());
    await tester.pumpAndSettle();

    for (final icon in [
      Icons.search_rounded,
      Icons.calendar_today_outlined,
      Icons.chat_bubble_outline_rounded,
      Icons.person_outline_rounded,
    ]) {
      await tester.tap(find.byIcon(icon).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
