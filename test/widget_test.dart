import 'package:flutter_test/flutter_test.dart';
import 'package:zindalearn/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZindaLearnApp());
    expect(find.byType(ZindaLearnApp), findsOneWidget);
  });
}
