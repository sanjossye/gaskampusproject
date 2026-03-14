import 'package:flutter_test/flutter_test.dart';

import 'package:gas_kampusapp/main.dart';

void main() {
  testWidgets('Onboarding screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GasKampusApp());
    await tester.pump();

    expect(find.text('Kirim & Antar Teman'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
