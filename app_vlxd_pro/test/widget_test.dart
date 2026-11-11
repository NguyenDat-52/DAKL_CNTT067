import 'package:flutter_test/flutter_test.dart';
import 'package:app_vlxd_pro/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VLXDProApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('VLXD-PRO'), findsWidgets);
  });
}
