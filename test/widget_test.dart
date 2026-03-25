import 'package:flutter_test/flutter_test.dart';
import 'package:blue_connect/main.dart';

void main() {
  testWidgets('Blu Connect app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const BluConnectApp());
    expect(find.text('Blu Connect'), findsOneWidget);
  });
}
