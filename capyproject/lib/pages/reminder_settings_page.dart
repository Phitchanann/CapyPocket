import 'package:flutter/material.dart';

import '../state/capy_scope.dart';
import 'ui_kit.dart';

class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  bool _seeded = false;
  bool dailyReminder = false;
  bool weeklySummary = false;
  bool budgetWarning = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }

    final store = CapyScope.read(context);
    dailyReminder = store.transactionCount > 0;
    weeklySummary = store.goals.isNotEmpty;
    budgetWarning = store.expenseByCategory.isNotEmpty;
    _seeded = true;
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() => reminderTime = picked);
    showSavedMessage(context, 'Reminder time updated');
  }

  void _toggleSetting(void Function() update, String message) {
    setState(update);
    showSavedMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final activeCount = [dailyReminder, weeklySummary, budgetWarning]
        .where((value) => value)
        .length;
    final formattedTime = MaterialLocalizations.of(context).formatTimeOfDay(reminderTime);

    return CapyPageFrame(
      currentTab: AppTab.profile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reminders', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              activeCount == 0
                  ? 'Turn on the reminders you want and CapyPocket will keep the wallet flow cozy.'
                  : 'You have $activeCount reminder flows active right now.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            WarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Schedule', style: theme.textTheme.titleMedium),
                      InfoPill(label: formattedTime),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use one reminder time for daily check-ins and weekly summaries.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TimeChip(label: reminderTime.hourOfPeriod == 0 ? '12' : '${reminderTime.hourOfPeriod}'),
                      TimeChip(label: reminderTime.minute.toString().padLeft(2, '0')),
                      TimeChip(label: reminderTime.period == DayPeriod.am ? 'AM' : 'PM'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickReminderTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Change time'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ReminderSwitchRow(
              title: 'Daily reminder',
              subtitle: store.transactionCount == 0
                  ? 'Prompt to add your first transaction.'
                  : 'Check balance and log any missing daily movement.',
              value: dailyReminder,
              onChanged: (_) => _toggleSetting(
                () => dailyReminder = !dailyReminder,
                'Daily reminder updated',
              ),
            ),
            const SizedBox(height: 12),
            ReminderSwitchRow(
              title: 'Weekly summary',
              subtitle: store.goals.isEmpty
                  ? 'Get a weekend recap once goals begin.'
                  : 'Review weekly moves and savings progress every Sunday.',
              value: weeklySummary,
              onChanged: (_) => _toggleSetting(
                () => weeklySummary = !weeklySummary,
                'Weekly summary updated',
              ),
            ),
            const SizedBox(height: 12),
            ReminderSwitchRow(
              title: 'Budget limit warning',
              subtitle: store.expenseByCategory.isEmpty
                  ? 'Warn once categories begin to collect expense data.'
                  : 'Alert when one of your active spending categories gets close to its soft limit.',
              value: budgetWarning,
              onChanged: (_) => _toggleSetting(
                () => budgetWarning = !budgetWarning,
                'Budget warnings updated',
              ),
            ),
            const SizedBox(height: 18),
            WarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reminder notes', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Current data: ${store.transactionCount} transactions, ${store.goals.length} goals, ${store.expenseByCategory.length} spending categories.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
