import 'package:flutter/material.dart';

import '../state/capy_scope.dart';
import 'ui_kit.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final activeBudgetCount = store.expenseByCategory.length;

    return CapyPageFrame(
      currentTab: AppTab.profile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WarmCard(
              child: Column(
                children: [
                  const CapyBadge(size: 74, halo: true),
                  const SizedBox(height: 12),
                  Text(
                    'CapyPocket settings',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Local SQLite mode keeps your wallet, goals and categories on this device.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MiniStatCard(
                          label: 'Moves',
                          value: '${store.transactionCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MiniStatCard(
                          label: 'Goals',
                          value: '${store.goals.length}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MiniStatCard(
                          label: 'Rules',
                          value: '${store.categories.length}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SettingLine(
              icon: Icons.monetization_on_outlined,
              title: 'Currency',
              subtitle: 'THB display is active across balance and goals.',
            ),
            const SizedBox(height: 12),
            SettingLine(
              icon: Icons.storage_rounded,
              title: 'Storage',
              subtitle: store.isReady
                  ? 'SQLite database connected and ready on this device.'
                  : 'Preparing local database...',
            ),
            const SizedBox(height: 12),
            SettingLine(
              icon: Icons.notifications_active_outlined,
              title: 'Reminder settings',
              subtitle: activeBudgetCount == 0
                  ? 'Tune daily and weekly reminders.'
                  : '$activeBudgetCount categories can trigger warning reminders.',
              onTap: () => Navigator.of(context).pushNamed('/reminder-settings'),
            ),
            const SizedBox(height: 12),
            SettingLine(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Budget setup',
              subtitle: activeBudgetCount == 0
                  ? 'No spending categories tracked yet.'
                  : '$activeBudgetCount spending categories are ready for soft budgets.',
              onTap: () => Navigator.of(context).pushNamed('/budget-setup'),
            ),
            const SizedBox(height: 12),
            SettingLine(
              icon: Icons.category_rounded,
              title: 'Category management',
              subtitle: '${store.categories.length} reusable categories in local storage.',
              onTap: () => Navigator.of(context).pushNamed('/category-management'),
            ),
            const SizedBox(height: 18),
            WarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Project checklist', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    'This build now covers multiple app pages, local database integration, and an accelerometer quick-add feature for Phase 2.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final loginButton = OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  child: const Text('Login'),
                );
                final createAccountButton = FilledButton(
                  onPressed: () => Navigator.of(context).pushNamed('/create-account'),
                  child: const Text('Create account'),
                );

                if (constraints.maxWidth < 320) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: loginButton),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: createAccountButton),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: loginButton),
                    const SizedBox(width: 12),
                    Expanded(child: createAccountButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
