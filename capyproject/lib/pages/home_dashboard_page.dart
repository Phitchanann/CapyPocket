import 'package:flutter/material.dart';

import '../data/capy_models.dart';
import '../state/capy_app_store.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({
    super.key,
    this.showFrame = true,
  });

  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final recentTransactions = store.recentTransactions();
    final primaryGoal = store.primaryGoal;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.transactionCount == 0
                          ? 'Welcome to CapyPocket'
                          : 'CapyPocket is on track',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.transactionCount == 0
                          ? 'Your first wallet is ready for real transactions.'
                          : 'Shake your phone anytime to open quick add.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const CapyBadge(size: 60),
            ],
          ),
          const SizedBox(height: 24),
          _BalanceHeroCard(store: store),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: homeActions.map((action) {
                  return SizedBox(
                    width: itemWidth,
                    child: ActionCard(
                      action: action,
                      onTap: () {
                        switch (action.title) {
                          case 'Receive':
                            Navigator.of(context).pushNamed(
                              '/quick-add',
                              arguments: CapyTransactionType.income,
                            );
                            return;
                          case 'Send':
                            Navigator.of(context).pushNamed('/add-transaction');
                            return;
                          case 'Save':
                            Navigator.of(context).pushNamed(
                              '/quick-add',
                              arguments: CapyTransactionType.pocket,
                            );
                            return;
                          case 'History':
                            navigateToTab(context, AppTab.money);
                            return;
                          default:
                            showSavedMessage(context, '${action.title} coming soon');
                            return;
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          SectionHeading(
            title: 'Savings goals',
            trailing: '${store.activeGoalCount} active',
          ),
          const SizedBox(height: 12),
          if (primaryGoal != null)
            _GoalProgressCard(goal: primaryGoal)
          else
            EmptyStateCard(
              title: 'No goal created yet',
              subtitle:
                  'Create your first savings goal to start tracking progress in your pocket.',
              actionLabel: 'Create first goal',
              onPressed: () => showGoalSetupSheet(context),
              icon: Icons.savings_outlined,
            ),
          const SizedBox(height: 24),
          SectionHeading(
            title: 'Recent moves',
            trailing: '${store.transactionCount} items',
          ),
          const SizedBox(height: 12),
          if (recentTransactions.isEmpty)
            EmptyStateCard(
              title: 'No transactions yet',
              subtitle:
                  'Your home feed will appear here after the first income, expense or pocket transfer is added.',
              actionLabel: 'Add first transaction',
              onPressed: () => Navigator.of(context).pushNamed('/add-transaction'),
              icon: Icons.receipt_long_outlined,
            )
          else
            Column(
              children: [
                for (final transaction in recentTransactions) ...[
                  _RecentTransactionTile(transaction: transaction),
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

    return CapyPageFrame(currentTab: AppTab.home, child: content);
  }
}

class _BalanceHeroCard extends StatelessWidget {
  const _BalanceHeroCard({required this.store});

  final CapyAppStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [capySoftCardColor, capySoftCardAltColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: capyLineColor),
        boxShadow: [
          BoxShadow(
            color: capyInkColor.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 4,
                children: List.generate(
                  4,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: capyInkColor.withValues(alpha: index == 0 ? 1 : 0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const InfoPill(label: 'Shake to quick add'),
            ],
          ),
          const SizedBox(height: 18),
          Text('Pocket balance', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            formatMoney(store.availableBalance),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Net worth: ${formatMoney(store.totalNetWorth)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: capySurfaceColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: capyLineColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InlineMetric(
                    label: 'Income',
                    value: '+${formatMoney(store.totalIncome).replaceFirst('฿', '฿')}',
                    positive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InlineMetric(
                    label: 'Expense',
                    value: '-${formatMoney(store.totalExpense).replaceFirst('฿', '฿')}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InlineMetric(
                    label: 'Pocket',
                    value: '+${formatMoney(store.totalPocketSaved).replaceFirst('฿', '฿')}',
                    positive: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({required this.goal});

  final CapyGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CapyBadge(size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Saved ${formatMoney(goal.savedAmount)} of ${formatMoney(goal.targetAmount)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text('${(goal.progress * 100).round()}%', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
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
              const InfoPill(label: 'Goal active'),
              InfoPill(label: formatShortDate(goal.createdAt)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({required this.transaction});

  final CapyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final amountColor = transaction.isPositive ? capyPositiveColor : capyNegativeColor;
    final icon = switch (transaction.type) {
      CapyTransactionType.income => Icons.arrow_downward_rounded,
      CapyTransactionType.pocket => Icons.savings_rounded,
      CapyTransactionType.expense => Icons.arrow_upward_rounded,
    };

    return WarmCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: amountColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${transaction.category} • ${formatShortDate(transaction.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            transaction.signedAmountLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: amountColor,
                ),
          ),
        ],
      ),
    );
  }
}
