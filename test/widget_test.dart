import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/main.dart';

void main() {
  testWidgets('App loads shell', (tester) async {
    await tester.pumpWidget(const NexusApp());
    await tester.pump();
    expect(find.text('Nexus'), findsOneWidget);
  });
}
