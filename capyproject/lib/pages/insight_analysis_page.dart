import 'package:capyproject/data/capy_models.dart';
import 'package:flutter/material.dart';

import '../state/capy_scope.dart';
import 'ui_kit.dart';

class InsightAnalysisPage extends StatelessWidget {
  const InsightAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final breakdown = store.expenseByCategory.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final topCategory = breakdown.isEmpty ? null : breakdown.first;
    final averageExpense = store.transactionCount == 0
        ? 0.0
        : store.totalExpense /
            store.transactions.where((item) => item.type.name == 'expense').length.clamp(1, 9999);

    return CapyPageFrame(
      currentTab: AppTab.money,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              store.transactionCount == 0
                  ? 'Insights will appear after a few transactions have been recorded.'
                  : 'Your analytics update automatically from local transaction data.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            WarmCard(
              color: const Color(0xFFF1E6D7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Trend check', style: theme.textTheme.titleMedium),
                      InfoPill(label: topCategory == null ? 'No trend yet' : topCategory.key),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(formatMoney(store.totalExpense), style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    topCategory == null
                        ? 'There is not enough activity yet to highlight spending changes.'
                        : 'Largest spend category right now is ${topCategory.key}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: capySurfaceColor.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: capyLineColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: MiniStatCard(
                            label: 'Top spend',
                            value: topCategory == null ? '฿0.00' : formatMoney(topCategory.value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MiniStatCard(
                            label: 'Avg expense',
                            value: formatMoney(averageExpense),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MiniStatCard(
                            label: 'Pocket',
                            value: formatMoney(store.totalPocketSaved),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            WarmCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CapyBadge(size: 64, halo: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Capy tip', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          topCategory == null
                              ? 'Track a few expenses first, then the app can surface patterns and gentle suggestions.'
                              : 'Your biggest spending is in ${topCategory.key}. Set a goal or category budget to keep it cozy.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeading(title: 'Signals', trailing: '${breakdown.length} updates'),
            const SizedBox(height: 12),
            if (breakdown.isEmpty)
              EmptyStateCard(
                title: 'No signals yet',
                subtitle:
                    'Insight cards will unlock automatically after there is enough spending history to analyze.',
                actionLabel: 'Open money tab',
                onPressed: () => navigateToTab(context, AppTab.money),
                icon: Icons.tips_and_updates_outlined,
              )
            else
              Column(
                children: [
                  for (final item in breakdown.take(3)) ...[
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
