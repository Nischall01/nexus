import 'package:flutter_test/flutter_test.dart';
import 'package:test_record/main.dart';

void main() {
  testWidgets('App loads shell', (tester) async {
    await tester.pumpWidget(const IssueTrackerApp());
    await tester.pump();
    expect(find.text('Tracker'), findsOneWidget);
  });
}
