import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pug_vpn/main.dart';

void main() {
  testWidgets('Home page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('PugVPN'), findsOneWidget);
    expect(find.text('CONNECT'), findsOneWidget);
    expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    expect(find.text('Tap to secure your connection'), findsOneWidget);
  });
}
