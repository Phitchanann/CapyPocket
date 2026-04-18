import 'package:flutter/material.dart';

import '../data/capy_models.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.showFrame = true});

  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: WarmCard(
              child: Column(
                children: [
                  const CapyBadge(size: 82, halo: true),
                  const SizedBox(height: 12),
                  Text(
                    store.currentDisplayName,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.currentUser != null
                        ? 'Active wallet • ${store.currentUsername ?? store.currentUser!.email}'
                        : 'Local data mode is active',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MiniStatCard(
                          label: 'Saved',
                          value: formatMoney(store.currentPocketSaved),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MiniStatCard(
                          label: 'Goal',
                          value: formatMoney(store.currentSavingsGoal),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MiniStatCard(
                          label: 'Cash',
                          value: formatMoney(store.currentCashBalance),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SettingToggle(
            icon: Icons.shield_outlined,
            title: 'Safety net reminders',
            subtitle: 'Database is ready for budget and reminder expansion.',
            value: store.goals.isNotEmpty,
            onChanged: (_) => showSavedMessage(
              context,
              'Reminder setup can be extended next.',
            ),
          ),
          const SizedBox(height: 12),
          SettingToggle(
            icon: Icons.vibration_rounded,
            title: 'Shake to quick add',
            subtitle: 'Accelerometer gesture is active across the app.',
            value: true,
            onChanged: (_) => showSavedMessage(
              context,
              'Shake quick add is enabled in this build.',
            ),
          ),
          const SizedBox(height: 12),
          SettingLine(
            icon: Icons.settings_outlined,
            title: 'App settings',
            subtitle: 'Storage, budgets, reminders and project configuration.',
            onTap: () => Navigator.of(context).pushNamed('/app-settings'),
          ),
          const SizedBox(height: 12),
          SettingLine(
            icon: Icons.notifications_active_outlined,
            title: 'Reminder settings',
            subtitle: 'Choose which budget and weekly reminders stay active.',
            onTap: () => Navigator.of(context).pushNamed('/reminder-settings'),
          ),
          const SizedBox(height: 18),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project-ready feature set',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'This build now includes 9+ screens, Firebase sync, and accelerometer-based quick add.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                if (store.isLoggedIn)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        store.logout();
                        if (rootTabNotifier.value != AppTab.home) {
                          rootTabNotifier.value = AppTab.home;
                        }
                        Navigator.of(context).pushReplacementNamed('/root');
                      },
                      child: const Text('Logout'),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final createAccountButton = OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/create-account'),
                        child: const Text('Create account'),
                      );
                      final loginButton = FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/login'),
                        child: const Text('Login'),
                      );

                      if (constraints.maxWidth < 320) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: createAccountButton,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: loginButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: createAccountButton),
                          const SizedBox(width: 12),
                          Expanded(child: loginButton),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!showFrame) {
      return content;
    }

    return CapyPageFrame(currentTab: AppTab.profile, child: content);
  }
}
