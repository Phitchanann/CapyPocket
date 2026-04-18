import 'package:flutter/material.dart';

import '../data/capy_models.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class QuickAddPage extends StatefulWidget {
  const QuickAddPage({super.key});

  @override
  State<QuickAddPage> createState() => _QuickAddPageState();
}

class _QuickAddPageState extends State<QuickAddPage> {
  String amountText = '0';
  String? selectedCategory;
  CapyTransactionType selectedType = CapyTransactionType.expense;
  bool _seededFromRoute = false;

  double get _amountValue => double.tryParse(amountText) ?? 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededFromRoute) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CapyTransactionType) {
      selectedType = args;
    }
    _seededFromRoute = true;
  }

  void _appendValue(String value) {
    setState(() {
      if (value == '.' && amountText.contains('.')) {
        return;
      }

      if (amountText == '0' && value != '.') {
        amountText = value;
      } else {
        amountText += value;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (amountText.length <= 1) {
        amountText = '0';
        return;
      }
      amountText = amountText.substring(0, amountText.length - 1);
    });
  }

  String _amountLabel() {
    return formatMoney(_amountValue);
  }

  Future<void> _saveQuickTransaction() async {
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0 || selectedCategory == null) {
      showSavedMessage(context, 'Please choose category and amount first.');
      return;
    }

    final store = CapyScope.read(context);
    await store.addTransaction(
      title: 'Quick ${selectedType.name}',
      category: selectedCategory!,
      note: 'Added from quick keypad',
      amount: amount,
      type: selectedType,
    );

    if (!mounted) {
      return;
    }

    if (store.errorMessage != null) {
      showSavedMessage(context, 'Could not save quick transaction.');
      return;
    }

    showSavedMessage(context, 'Quick transaction added.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final categories = store.categories;
    if (categories.isEmpty) {
      selectedCategory = null;
    } else if (!categories.any((item) => item.name == selectedCategory)) {
      selectedCategory = _preferredCategory(categories);
    }

    return CapyPageFrame(
      currentTab: AppTab.money,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          22,
          20,
          132 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New entry', style: theme.textTheme.titleLarge),
            const SizedBox(height: 18),
            Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 154,
                    height: 154,
                    decoration: BoxDecoration(
                      color: capySoftCardColor.withValues(alpha: 0.26),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -42,
                  top: 56,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: capySoftCardAltColor.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Column(
                  children: [
                    const CapyBadge(size: 78, halo: true),
                    const SizedBox(height: 14),
                    Text(
                      _amountLabel(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the keypad for a fast mobile-first entry.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: CapyTransactionType.values.map((entryType) {
                final selected = selectedType == entryType;
                return ChoiceChip(
                  label: Text(entryType.name.toUpperCase()),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    selectedType = entryType;
                    selectedCategory = _preferredCategory(categories);
                  }),
                  selectedColor: capyInkColor,
                  labelStyle: TextStyle(
                    color: selected ? capySurfaceColor : capyInkColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  backgroundColor: capySurfaceColor,
                  side: const BorderSide(color: capyLineColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            WarmCard(
              color: const Color(0xFFF4E9D9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent tags', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(
                    selectedCategory == null
                        ? 'Choose a category to keep your quick entry organized.'
                        : 'Selected category: $selectedCategory',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final item in categories.take(5)) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: Text(item.name),
                                selected: selectedCategory == item.name,
                                onSelected: (_) => setState(
                                  () => selectedCategory = item.name,
                                ),
                                selectedColor: item.color.withValues(
                                  alpha: 0.92,
                                ),
                                backgroundColor: capySurfaceColor,
                                labelStyle: TextStyle(
                                  color: selectedCategory == item.name
                                      ? capySurfaceColor
                                      : capyInkColor,
                                  fontWeight: FontWeight.w700,
                                ),
                                avatar: Icon(
                                  item.icon,
                                  size: 18,
                                  color: selectedCategory == item.name
                                      ? capySurfaceColor
                                      : item.color,
                                ),
                                side: const BorderSide(color: capyLineColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.16,
              ),
              itemBuilder: (context, index) {
                const labels = [
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                  '.',
                  '0',
                  '<',
                ];
                final label = labels[index];
                if (label == '<') {
                  return KeypadButton(
                    icon: Icons.backspace_outlined,
                    onTap: _backspace,
                  );
                }
                return KeypadButton(
                  label: label,
                  onTap: () => _appendValue(label),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: store.isSaving ? null : _saveQuickTransaction,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(store.isSaving ? 'Saving...' : 'Add transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _preferredCategory(List<CapyCategory> categories) {
    if (categories.isEmpty) {
      return null;
    }

    if (selectedType == CapyTransactionType.pocket) {
      for (final category in categories) {
        if (category.name.toLowerCase() == 'pocket') {
          return category.name;
        }
      }
    }

    return categories.first.name;
  }
}
