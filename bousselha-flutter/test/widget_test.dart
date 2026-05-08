import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bousselha_flutter/main.dart';
import 'package:bousselha_flutter/shared/providers/app_providers.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          carsProvider.overrideWith((ref) async => []),
          contractsProvider.overrideWith((ref) async => []),
          maintenanceProvider.overrideWith((ref) async => []),
        ],
        child: const BousselhaApp(),
      ),
    );
    expect(find.textContaining('BOUSSELHA CARS'), findsOneWidget);
  });
}
