import 'package:flutter/material.dart';

import '../state/capy_scope.dart';
import 'ui_kit.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final query = searchController.text.trim().toLowerCase();
    final categories = store.categories
        .where((item) => item.name.toLowerCase().contains(query))
        .toList();

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
            Text('Categories', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Manage the categories stored in your local database.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search categories',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            if (categories.isEmpty)
              EmptyStateCard(
                title: 'No matching categories',
                subtitle:
                    'Add a new category and it will appear here immediately for your transaction forms.',
                actionLabel: 'Add category',
                onPressed: () =>
                    Navigator.of(context).pushNamed('/add-category'),
                icon: Icons.category_outlined,
              )
            else
              Column(
                children: [
                  for (final category in categories) ...[
                    WarmCard(
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(category.icon, color: category.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              category.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const InfoPill(label: 'Ready'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/add-category'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add category'),
            ),
          ],
        ),
      ),
    );
  }
}
