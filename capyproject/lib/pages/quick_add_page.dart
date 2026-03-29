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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New entry', style: theme.textTheme.titleLarge),
            const SizedBox(height: 18),
            const Center(child: CapyBadge(size: 72, halo: true)),
            const SizedBox(height: 12),
            Center(child: Text(formatMoney(double.tryParse(amountText) ?? 0), style: theme.textTheme.headlineMedium)),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Tap the keypad for a fast mobile-first entry.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: capySurfaceColor,
                  side: const BorderSide(color: capyLineColor),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item.name),
                      selected: selectedCategory == item.name,
                      onSelected: (_) => setState(() => selectedCategory = item.name),
                      selectedColor: item.color.withValues(alpha: 0.9),
                      backgroundColor: capySurfaceColor,
                      labelStyle: TextStyle(
                        color: selectedCategory == item.name ? capySurfaceColor : capyInkColor,
                        fontWeight: FontWeight.w700,
                      ),
                      avatar: Icon(item.icon, size: 18, color: selectedCategory == item.name ? capySurfaceColor : item.color),
                      side: const BorderSide(color: capyLineColor),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            WarmCard(
              color: const Color(0xFFF4E6D5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent tags', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    selectedCategory == null
                        ? 'Choose a category to keep your quick entry organized.'
                        : 'Selected category: $selectedCategory',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final label in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'])
                  KeypadButton(
                    label: label,
                    onTap: () => _appendValue(label),
                  ),
                KeypadButton(
                  icon: Icons.backspace_outlined,
                  onTap: _backspace,
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: store.isSaving ? null : _saveQuickTransaction,
              child: Text(store.isSaving ? 'Saving...' : 'Add transaction'),
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
