import 'package:flutter_test/flutter_test.dart';
import 'package:bajinka_academy/main.dart';
void main() {
  testWidgets('preview does not claim completed work and course opens', (tester) async {
    await tester.pumpWidget(const AcademyApp());
    expect(find.text('Phase 1 preview'), findsOneWidget);
    await tester.tap(find.text('Explore course map'));
    await tester.pumpAndSettle();
    expect(find.text('Python Foundations'), findsOneWidget);
    expect(find.text('Functions and Variables'), findsOneWidget);
  });
}
