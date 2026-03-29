import 'package:capyproject/data/capy_models.dart';
import 'package:flutter/material.dart';

import '../state/capy_scope.dart';
import 'ui_kit.dart';

class MonthlySnapshotPage extends StatelessWidget {
  const MonthlySnapshotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final breakdown = store.expenseByCategory.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final topThree = breakdown.take(3).toList();

    return CapyPageFrame(
      currentTab: AppTab.money,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              title: 'Month ${DateTime.now().month}',
              trailing: store.transactionCount == 0 ? 'No activity' : '${store.transactionCount} moves',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MiniStatCard(
                    label: topThree.isNotEmpty ? topThree[0].key : 'Bills',
                    value: topThree.isNotEmpty ? formatMoney(topThree[0].value) : '฿0.00',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MiniStatCard(
                    label: topThree.length > 1 ? topThree[1].key : 'Savings',
                    value: topThree.length > 1 ? formatMoney(topThree[1].value) : '฿0.00',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MiniStatCard(
                    label: topThree.length > 2 ? topThree[2].key : 'Fun',
                    value: topThree.length > 2 ? formatMoney(topThree[2].value) : '฿0.00',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            WarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Spending breakdown', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      Text('Expense only', style: theme.textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 150,
                    child: CustomPaint(
                      painter: TrendPainter(points: store.weeklyExpensePoints),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeading(title: 'Top categories', trailing: '${breakdown.length} items'),
            const SizedBox(height: 12),
            if (breakdown.isEmpty)
              EmptyStateCard(
                title: 'No monthly snapshot yet',
                subtitle:
                    'Once your first transactions arrive, this page will summarize spending by category.',
                actionLabel: 'Add first transaction',
                onPressed: () => Navigator.of(context).pushNamed('/add-transaction'),
                icon: Icons.insert_chart_outlined_rounded,
              )
            else
              Column(
                children: [
                  for (final item in breakdown.take(6)) ...[
                    WarmCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(item.key, style: theme.textTheme.titleMedium),
                          ),
                          Text(formatMoney(item.value), style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
