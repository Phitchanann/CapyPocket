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
  DateTime selectedDate = DateTime.now();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
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
      createdAt: selectedDate,
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
      showBottomBar: false,
      showFab: false,
      child: Column(
        children: [
          // ── Top scrollable area ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  // Back + title row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'New Entry',
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Capybara mascot
                  const CapyBadge(size: 72, halo: true),
                  const SizedBox(height: 10),

                  // AMOUNT label
                  Text(
                    'AMOUNT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 2,
                      color: capyMutedColor,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Big amount display — ฿ + value
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '฿',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                          color: capyAccentColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _amountLabel(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Type chips (Expense / Income / Pocket)
                  Wrap(
                    spacing: 8,
                    children: CapyTransactionType.values.map((t) {
                      final sel = selectedType == t;
                      return ChoiceChip(
                        label: Text(t.name.toUpperCase()),
                        selected: sel,
                        onSelected: (_) => setState(() {
                          selectedType = t;
                          selectedCategory = _preferredCategory(categories);
                        }),
                        selectedColor: capyInkColor,
                        labelStyle: TextStyle(
                          color: sel ? capySurfaceColor : capyInkColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        backgroundColor: capySurfaceColor,
                        side: const BorderSide(color: capyLineColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Category chips
                  if (categories.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Category',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: capyInkColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in categories)
                          _QuickCatChip(
                            cat: cat,
                            selected: selectedCategory == cat.name,
                            onTap: () =>
                                setState(() => selectedCategory = cat.name),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Date picker
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Date',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: capyInkColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: capySurfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: capyLineColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: capyMutedColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedDate.toString().split(' ')[0],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: capyInkColor,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: capyMutedColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Fixed numpad + button at bottom ──
          _QuickNumpadSection(
            onKey: _appendValue,
            onBackspace: _backspace,
            isBusy: store.isSaving,
            onSave: _saveQuickTransaction,
          ),
        ],
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

class _QuickCatChip extends StatelessWidget {
  const _QuickCatChip({
    required this.cat,
    required this.selected,
    required this.onTap,
  });

  final CapyCategory cat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(cat.colorValue);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : capySurfaceColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : capyLineColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
              size: 16,
              color: selected ? color : capyMutedColor,
            ),
            const SizedBox(width: 6),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : capyInkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickNumpadSection extends StatelessWidget {
  const _QuickNumpadSection({
    required this.onKey,
    required this.onBackspace,
    required this.isBusy,
    required this.onSave,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final bool isBusy;
  final VoidCallback onSave;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '<'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      color: capySurfaceColor,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.18,
              ),
              itemBuilder: (context, index) {
                final row = index ~/ 3;
                final col = index % 3;
                if (row >= _keys.length) return const SizedBox.shrink();

                final key = _keys[row][col];

                if (key == '<') {
                  return KeypadButton(
                    icon: Icons.backspace_outlined,
                    onTap: onBackspace,
                  );
                }

                return KeypadButton(label: key, onTap: () => onKey(key));
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isBusy ? null : onSave,
                child: Text(isBusy ? 'Saving...' : 'Add Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
