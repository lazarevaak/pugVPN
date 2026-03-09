import 'package:flutter_test/flutter_test.dart';
import 'package:pug_vpn/main.dart';

void main() {
  testWidgets('Connect screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('PugVPN'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.textContaining('Backend:'), findsOneWidget);
  });
}
