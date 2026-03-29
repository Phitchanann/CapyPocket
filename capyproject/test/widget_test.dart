import 'package:capyproject/pages/home_dashboard_page.dart';
import 'package:capyproject/state/capy_app_store.dart';
import 'package:capyproject/state/capy_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CapyPocket home dashboard renders', (tester) async {
    final store = CapyAppStore();

    await tester.pumpWidget(
      CapyScope(
        store: store,
        child: const MaterialApp(
          home: HomeDashboardPage(),
        ),
      ),
    );

    expect(find.text('Welcome to CapyPocket'), findsOneWidget);
    expect(
      find.text('Your first wallet is ready for real transactions.'),
      findsOneWidget,
    );
    expect(find.text('No goal created yet'), findsOneWidget);
  });
}
