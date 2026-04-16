import 'package:flutter/material.dart';

import '../data/capy_models.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class EditTransactionPage extends StatefulWidget {
  const EditTransactionPage({super.key});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  late final TextEditingController amountController;
  late final TextEditingController titleController;
  late final TextEditingController noteController;

  CapyTransaction? transaction;
  CapyTransactionType type = CapyTransactionType.expense;
  String? category;
  DateTime selectedDate = DateTime.now();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    titleController = TextEditingController();
    noteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CapyTransaction) {
      transaction = args;
      type = args.type;
      category = args.category;
      selectedDate = args.createdAt;
      amountController.text = args.amount.toStringAsFixed(2);
      titleController.text = args.title;
      noteController.text = args.note;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    amountController.dispose();
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _updateTransaction() async {
    if (transaction == null) {
      return;
    }

    final parsedAmount = double.tryParse(
      amountController.text.replaceAll(',', '').trim(),
    );
    if (parsedAmount == null || parsedAmount <= 0 || category == null) {
      showSavedMessage(context, 'Please complete amount and category.');
      return;
    }

    final updated = transaction!.copyWith(
      title: titleController.text.trim().isEmpty
          ? transaction!.title
          : titleController.text.trim(),
      category: category,
      note: noteController.text.trim(),
      amount: parsedAmount,
      type: type,
      createdAt: selectedDate,
    );

    final store = CapyScope.read(context);
    await store.updateTransaction(updated);
    if (!mounted) {
      return;
    }
    if (store.errorMessage != null) {
      showSavedMessage(context, 'Could not update transaction.');
      return;
    }
    showSavedMessage(context, 'Transaction updated.');
    Navigator.of(context).pop();
  }

  Future<void> _deleteTransaction() async {
    if (transaction?.id == null) {
      return;
    }

    final store = CapyScope.read(context);
    await store.deleteTransaction(transaction!.id!);
    if (!mounted) {
      return;
    }
    if (store.errorMessage != null) {
      showSavedMessage(context, 'Could not remove transaction.');
      return;
    }
    showSavedMessage(context, 'Transaction removed.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = CapyScope.watch(context);
    final categories = store.categories;
    final selectedCategory = categories.any((item) => item.name == category)
        ? category
        : (categories.isNotEmpty ? categories.first.name : null);
    category = selectedCategory;

    if (transaction == null) {
      return CapyPageFrame(
        currentTab: AppTab.money,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyStateCard(
              title: 'No transaction selected',
              subtitle: 'Open a transaction from the money page to edit it.',
              actionLabel: 'Back to money',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icons.edit_note_rounded,
            ),
          ),
        ),
      );
    }

    return CapyPageFrame(
      currentTab: AppTab.money,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
        child: WarmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit transaction',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Update amount, category, type or note and save it back to local storage.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '฿ ',
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Choose a title',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: categories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.name,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => category = value),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CapyTransactionType.values.map((entryType) {
                  final selected = type == entryType;
                  return ChoiceChip(
                    label: Text(entryType.name.toUpperCase()),
                    selected: selected,
                    onSelected: (_) => setState(() => type = entryType),
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
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(formatShortDate(selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Short note',
                  hintText: 'Add note',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final deleteButton = OutlinedButton(
                    onPressed: store.isSaving ? null : _deleteTransaction,
                    child: const Text('Delete'),
                  );
                  final updateButton = FilledButton(
                    onPressed: store.isSaving ? null : _updateTransaction,
                    child: Text(
                      store.isSaving ? 'Saving...' : 'Update transaction',
                    ),
                  );

                  if (constraints.maxWidth < 320) {
                    return Column(
                      children: [
                        SizedBox(width: double.infinity, child: deleteButton),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: updateButton),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: deleteButton),
                      const SizedBox(width: 12),
                      Expanded(child: updateButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
