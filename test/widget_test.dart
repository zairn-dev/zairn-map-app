import 'package:flutter_test/flutter_test.dart';
import 'package:zairn_map/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ZairnMapApp());
    expect(find.text('Zairn Map'), findsOneWidget);
  });
}
