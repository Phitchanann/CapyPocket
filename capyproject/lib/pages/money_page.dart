import 'package:flutter/material.dart';

import '../data/capy_models.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class MoneyPage extends StatelessWidget {
  const MoneyPage({super.key, this.showFrame = true});

  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final transactions = store.transactions;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Money room', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            transactions.isEmpty
                ? 'A fresh wallet waiting for its first real transaction.'
                : 'Track every income, expense and pocket transfer in one place.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
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
                    Text('Wallet', style: theme.textTheme.titleMedium),
                    InfoPill(label: '${store.transactionCount} moves'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  formatMoney(store.availableBalance),
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Pocket saved ${formatMoney(store.totalPocketSaved)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InlineMetric(
                        label: 'Income',
                        value: '+${formatMoney(store.totalIncome)}',
                        positive: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InlineMetric(
                        label: 'Spent',
                        value: '-${formatMoney(store.totalExpense)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Spending arc', style: theme.textTheme.titleMedium),
                    Text('Last 7 days', style: theme.textTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: CustomPaint(
                    painter: TrendPainter(points: store.weeklyExpensePoints),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: SectionHeading(
                  title: 'Transactions',
                  trailing: 'Tap to edit',
                ),
              ),
              IconButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/monthly-snapshot'),
                icon: const Icon(Icons.calendar_month_rounded),
                tooltip: 'Monthly snapshot',
              ),
              IconButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/insight-analysis'),
                icon: const Icon(Icons.insights_rounded),
                tooltip: 'Insights',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            EmptyStateCard(
              title: 'No transactions yet',
              subtitle:
                  'Add your first movement to start building a snapshot, insights and budgets.',
              actionLabel: 'Add first transaction',
              onPressed: () => showQuickAddSheet(context),
              icon: Icons.payments_outlined,
            )
          else
            Column(
              children: [
                for (final transaction in transactions.take(8)) ...[
                  _MoneyTransactionTile(transaction: transaction),
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

    return CapyPageFrame(currentTab: AppTab.money, child: content);
  }
}

class _MoneyTransactionTile extends StatelessWidget {
  const _MoneyTransactionTile({required this.transaction});

  final CapyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final amountColor = transaction.isPositive
        ? capyPositiveColor
        : capyNegativeColor;
    final icon = switch (transaction.type) {
      CapyTransactionType.income => Icons.arrow_downward_rounded,
      CapyTransactionType.pocket => Icons.savings_rounded,
      CapyTransactionType.expense => Icons.arrow_upward_rounded,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => Navigator.of(
        context,
      ).pushNamed('/edit-transaction', arguments: transaction),
      child: WarmCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: amountColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.category} • ${formatShortDate(transaction.createdAt)} • ${formatTimeLabel(transaction.createdAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.signedAmountLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: amountColor),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.typeLabel,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
