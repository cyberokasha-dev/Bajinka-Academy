import 'package:flutter_test/flutter_test.dart';
import 'package:bajinka_academy/main.dart';
void main() {
  testWidgets('guest sees honest progress and Google sign in', (tester) async {
    await tester.pumpWidget(const AcademyApp());
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Your progress'), findsOneWidget);
    expect(find.textContaining('No required activities'), findsOneWidget);
    await tester.ensureVisible(find.text('Explore course map'));
    await tester.tap(find.text('Explore course map'));
    await tester.pumpAndSettle();
    expect(find.text('Python Foundations'), findsOneWidget);
    expect(find.text('Functions and Variables'), findsOneWidget);
  });
}
