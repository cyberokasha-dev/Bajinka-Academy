import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bajinka_academy/main.dart';
void main() {
  testWidgets('guest can open course and use notes without login', (tester) async {
    await tester.pumpWidget(const AcademyApp());
    await tester.pumpAndSettle();
    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    await tester.ensureVisible(find.text('Open my course'));
    await tester.tap(find.text('Open my course'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Functions and Variables'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Running and saving Python programs'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR PROGRESS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('phone dashboard has no layout overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AcademyApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
