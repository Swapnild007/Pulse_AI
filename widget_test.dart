import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ai/main.dart';

void main() {
  testWidgets('app has independent branding and three destinations', (tester) async {
    await tester.pumpWidget(const PulseApp());
    expect(find.text('PULSE'), findsOneWidget);
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('Memory'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
