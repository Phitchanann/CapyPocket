import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'add_category_page.dart';
import 'add_transaction_page.dart';
import 'app_settings_page.dart';
import 'budget_setup_page.dart';
import 'category_management_page.dart';
import 'create_account_page.dart';
import 'edit_transaction_page.dart';
import 'goals_page.dart';
import 'home_dashboard_page.dart';
import 'insight_analysis_page.dart';
import 'login_page.dart';
import 'monthly_snapshot_page.dart';
import 'money_page.dart';
import 'profile_page.dart';
import 'quick_add_page.dart';
import 'reminder_settings_page.dart';
import 'ui_kit.dart';
import '../state/capy_app_store.dart';
import '../state/capy_scope.dart';

class CapyPocketApp extends StatelessWidget {
  const CapyPocketApp({
    super.key,
    required this.store,
  });

  final CapyAppStore store;

  @override
  Widget build(BuildContext context) {
    return CapyScope(
      store: store,
      child: MaterialApp(
        title: 'CapyPocket',
        debugShowCheckedModeBanner: false,
        theme: buildCapyTheme(),
        home: const _RootShellPage(),
        routes: {
          '/quick-add': (_) => const QuickAddPage(),
          '/add-transaction': (_) => const AddTransactionPage(),
          '/edit-transaction': (_) => const EditTransactionPage(),
          '/monthly-snapshot': (_) => const MonthlySnapshotPage(),
          '/insight-analysis': (_) => const InsightAnalysisPage(),
          '/budget-setup': (_) => const BudgetSetupPage(),
          '/category-management': (_) => const CategoryManagementPage(),
          '/add-category': (_) => const AddCategoryPage(),
          '/reminder-settings': (_) => const ReminderSettingsPage(),
          '/app-settings': (_) => const AppSettingsPage(),
          '/create-account': (_) => const CreateAccountPage(),
          '/login': (_) => const LoginPage(),
        },
      ),
    );
  }
}

class _RootShellPage extends StatefulWidget {
  const _RootShellPage();

  @override
  State<_RootShellPage> createState() => _RootShellPageState();
}

class _RootShellPageState extends State<_RootShellPage> {
  StreamSubscription<AccelerometerEvent>? _shakeSubscription;
  bool _quickAddSheetVisible = false;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    rootTabNotifier.value = AppTab.home;
    _shakeSubscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
    );
  }

  @override
  void dispose() {
    _shakeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openQuickAddFromShake() async {
    if (!mounted || _quickAddSheetVisible || Navigator.of(context).canPop()) {
      return;
    }

    _quickAddSheetVisible = true;
    try {
      await showQuickAddSheet(context);
    } finally {
      _quickAddSheetVisible = false;
    }
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final totalForce = event.x.abs() + event.y.abs() + event.z.abs();
    final now = DateTime.now();

    if (totalForce < 34) {
      return;
    }

    if (now.difference(_lastShake) < const Duration(seconds: 2)) {
      return;
    }

    _lastShake = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openQuickAddFromShake();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTab>(
      valueListenable: rootTabNotifier,
      builder: (context, currentTab, _) {
        return CapyPageFrame(
          currentTab: currentTab,
          child: IndexedStack(
            index: AppTab.values.indexOf(currentTab),
            children: const [
              HomeDashboardPage(showFrame: false),
              GoalsPage(showFrame: false),
              MoneyPage(showFrame: false),
              ProfilePage(showFrame: false),
            ],
          ),
        );
      },
    );
  }
}
