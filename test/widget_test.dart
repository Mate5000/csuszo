import 'package:flutter_test/flutter_test.dart';
import 'package:csuszo/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CsuszoApp());
    expect(find.text('Mérés'), findsOneWidget);
  });
}