import 'package:flutter/material.dart';

import '../data/capy_models.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class BudgetSetupPage extends StatelessWidget {
  const BudgetSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final breakdown = store.expenseByCategory.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final activeBudgetCount = breakdown.length;
    final alertCount = breakdown.where((item) {
      final suggestedLimit = _suggestedLimit(item.value);
      return item.value >= suggestedLimit * 0.8;
    }).length;

    return CapyPageFrame(
      showBottomBar: false,
      showFab: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => popOrGoToRoot(context, fallbackTab: AppTab.home),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: Text('Back', style: theme.textTheme.bodyMedium),
              style: TextButton.styleFrom(
                foregroundColor: capyInkColor,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(height: 8),
            Text('Budget setup', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              breakdown.isEmpty
                  ? 'Start adding expenses and CapyPocket will suggest soft budget lines by category.'
                  : 'Suggested limits update from your current spending history in local storage.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: MiniStatCard(
                    label: 'Active',
                    value: '$activeBudgetCount',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MiniStatCard(label: 'Alerts', value: '$alertCount'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MiniStatCard(
                    label: 'Spent',
                    value: formatMoney(store.totalExpense),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (breakdown.isEmpty)
              EmptyStateCard(
                title: 'No budget activity yet',
                subtitle:
                    'Once expenses are recorded, this page will turn them into category-based budget previews.',
                actionLabel: 'Add expense',
                onPressed: () =>
                    Navigator.of(context).pushNamed('/add-transaction'),
                icon: Icons.account_balance_wallet_outlined,
              )
            else
              Column(
                children: [
                  for (final item in breakdown.take(6)) ...[
                    BudgetLimitRow(
                      title: item.key,
                      spent: formatMoney(item.value),
                      limit: formatMoney(_suggestedLimit(item.value)),
                      progress: (item.value / _suggestedLimit(item.value))
                          .clamp(0, 1),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
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
                      Text('Budget notes', style: theme.textTheme.titleMedium),
                      const InfoPill(label: 'Phase 2 ready'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    breakdown.isEmpty
                        ? 'Create categories and add a few transactions first. Budget guidance will appear here automatically.'
                        : 'These limits are gentle suggestions based on current expense data. You can extend this into fixed editable budgets next.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/category-management'),
                    icon: const Icon(Icons.category_outlined),
                    label: const Text('Categories'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/add-transaction'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add expense'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

double _suggestedLimit(double spent) {
  if (spent <= 0) {
    return 1000;
  }

  final padded = spent * 1.2;
  final rounded = (padded / 100).ceil() * 100;
  return rounded < 1000 ? 1000 : rounded.toDouble();
}
