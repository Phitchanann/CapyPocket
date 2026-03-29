import 'package:capyproject/pages/add_transaction_page.dart';
import 'package:capyproject/pages/app_settings_page.dart';
import 'package:capyproject/pages/budget_setup_page.dart';
import 'package:capyproject/pages/create_account_page.dart';
import 'package:capyproject/pages/goals_page.dart';
import 'package:capyproject/pages/home_dashboard_page.dart';
import 'package:capyproject/pages/login_page.dart';
import 'package:capyproject/pages/money_page.dart';
import 'package:capyproject/pages/profile_page.dart';
import 'package:capyproject/pages/quick_add_page.dart';
import 'package:capyproject/pages/reminder_settings_page.dart';
import 'package:capyproject/pages/ui_kit.dart';
import 'package:capyproject/state/capy_app_store.dart';
import 'package:capyproject/state/capy_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('core pages fit on a compact phone layout', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = CapyAppStore();
    final pages = <Widget>[
      const HomeDashboardPage(),
      const GoalsPage(),
      const MoneyPage(),
      const ProfilePage(),
      const QuickAddPage(),
      const AddTransactionPage(),
      const BudgetSetupPage(),
      const ReminderSettingsPage(),
      const AppSettingsPage(),
      const CreateAccountPage(),
      const LoginPage(),
    ];

    for (final page in pages) {
      await tester.pumpWidget(
        CapyScope(
          store: store,
          child: MaterialApp(
            theme: buildCapyTheme(),
            home: page,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow found in ${page.runtimeType}');
    }
  });
}
