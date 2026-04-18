import 'package:flutter/material.dart';

import '../state/capy_scope.dart';
import 'ui_kit.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  late final TextEditingController nameController;
  IconData selectedIcon = Icons.category_rounded;
  Color selectedColor = const Color(0xFFC38B55);

  final iconChoices = const [
    Icons.restaurant_rounded,
    Icons.receipt_long_rounded,
    Icons.directions_car_filled_rounded,
    Icons.shopping_bag_rounded,
    Icons.savings_rounded,
    Icons.favorite_rounded,
  ];

  final colorChoices = const [
    Color(0xFFC38B55),
    Color(0xFFBF6B59),
    Color(0xFF4F8D69),
    Color(0xFF7C8CC4),
    Color(0xFF9B6ACD),
    Color(0xFFE0A066),
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      showSavedMessage(context, 'Please enter a category name.');
      return;
    }

    final store = CapyScope.read(context);
    await store.addCategory(
      name: name,
      iconCodePoint: selectedIcon.codePoint,
      colorValue: selectedColor.toARGB32(),
    );

    if (!mounted) {
      return;
    }

    if (store.errorMessage != null) {
      showSavedMessage(context, store.errorMessage!);
      return;
    }

    showSavedMessage(context, 'Category created.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = CapyScope.watch(context);

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
              label: Text(
                'Back',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              style: TextButton.styleFrom(
                foregroundColor: capyInkColor,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(height: 8),
            WarmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: selectedColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: capyLineColor),
                      ),
                      child: Icon(selectedIcon, size: 54, color: selectedColor),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Category name',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Icon', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: iconChoices.map((icon) {
                      final selected = selectedIcon == icon;
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() => selectedIcon = icon),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: selected
                                ? selectedColor.withValues(alpha: 0.16)
                                : capySurfaceColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? selectedColor : capyLineColor,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: selected ? selectedColor : capyInkColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text('Color', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: colorChoices.map((color) {
                      final selected = selectedColor == color;
                      return InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? capyInkColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: store.isSaving ? null : _saveCategory,
                    child: Text(store.isSaving ? 'Saving...' : 'Save category'),
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
