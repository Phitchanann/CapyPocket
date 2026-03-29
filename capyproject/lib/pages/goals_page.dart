import 'package:flutter/material.dart';

import '../data/capy_models.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({
    super.key,
    this.showFrame = true,
  });

  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final goals = store.goals;
    final totalTarget = goals.fold<double>(0, (sum, item) => sum + item.targetAmount);
    final totalSaved = goals.fold<double>(0, (sum, item) => sum + item.savedAmount);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Savings pocket', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            goals.isEmpty
                ? 'Create the first savings goal and start from zero calmly.'
                : 'Your goals now track real saved amounts and progress.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          WarmCard(
            color: const Color(0xFFF5EBDD),
            child: Column(
              children: [
                const CapyBadge(size: 92, halo: true),
                const SizedBox(height: 14),
                Text(formatMoney(totalSaved), style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  goals.isEmpty ? 'No pocket created yet.' : 'Saved across ${goals.length} goals',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: totalTarget <= 0 ? 0 : (totalSaved / totalTarget).clamp(0, 1),
                    backgroundColor: capySurfaceColor,
                    color: capyAccentColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      totalTarget <= 0 ? '0% of active goals' : '${((totalSaved / totalTarget).clamp(0, 1) * 100).round()}% of active goals',
                      style: theme.textTheme.labelMedium,
                    ),
                    Text(
                      '${formatMoney(totalSaved)} / ${formatMoney(totalTarget)}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: MiniStatCard(label: 'Goals', value: '${goals.length}')),
              const SizedBox(width: 12),
              Expanded(child: MiniStatCard(label: 'Saved', value: formatMoney(totalSaved))),
              const SizedBox(width: 12),
              Expanded(child: MiniStatCard(label: 'Target', value: formatMoney(totalTarget))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: SectionHeading(title: 'Goal list', trailing: 'Tap to edit'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => showGoalSetupSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            EmptyStateCard(
              title: 'No goal yet',
              subtitle:
                  'Create your first savings pocket and start tracking real progress from the app.',
              actionLabel: 'Plan first pocket',
              onPressed: () => showGoalSetupSheet(context),
              icon: Icons.savings_outlined,
            )
          else
            Column(
              children: [
                for (final goal in goals) ...[
                  _GoalTile(goal: goal),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );

    if (!showFrame) {
      return content;
    }

    return CapyPageFrame(currentTab: AppTab.goals, child: content);
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final CapyGoal goal;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => showGoalSetupSheet(context, initialGoal: goal),
      child: WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CapyBadge(size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${formatMoney(goal.savedAmount)} saved of ${formatMoney(goal.targetAmount)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(goal.progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: goal.progress,
                backgroundColor: capySoftCardColor,
                color: capyAccentColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoPill(label: formatShortDate(goal.createdAt)),
                const InfoPill(label: 'Stored locally'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
