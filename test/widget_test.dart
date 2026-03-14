import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pug_vpn/main.dart';

void main() {
  testWidgets('App launches onboarding and navigates to home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('PUGVPN'), findsNWidgets(2));
    expect(find.text('Secure. Fast. Private.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pumpAndSettle();

    expect(find.text('CONNECT'), findsOneWidget);
    expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    expect(find.text('Tap to secure your connection'), findsOneWidget);
  });
}
