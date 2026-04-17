import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/capy_models.dart';
import '../state/capy_scope.dart';
import 'camera_capture_page.dart';
import 'ui_kit.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late final TextEditingController amountController;
  late final TextEditingController titleController;
  late final TextEditingController noteController;

  CapyTransactionType type = CapyTransactionType.expense;
  String? category;
  DateTime selectedDate = DateTime.now();
  XFile? _slipImage;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    titleController = TextEditingController();
    noteController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraCapturePage()),
    );
    if (result != null && mounted) {
      setState(() => _slipImage = XFile(result));
    }
  }

  Future<void> _pickSlip(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked != null) {
      setState(() => _slipImage = picked);
    }
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

  Future<void> _saveTransaction() async {
    final parsedAmount = double.tryParse(
      amountController.text.replaceAll(',', '').trim(),
    );
    final trimmedTitle = titleController.text.trim();

    if (parsedAmount == null || parsedAmount <= 0 || category == null) {
      showSavedMessage(context, 'Please complete amount and category.');
      return;
    }

    final store = CapyScope.read(context);
    await store.addTransaction(
      title: trimmedTitle.isEmpty ? '${type.name} entry' : trimmedTitle,
      category: category!,
      note: noteController.text.trim(),
      amount: parsedAmount,
      type: type,
      createdAt: selectedDate,
      receiptImageUrl: _slipImage?.path,
    );

    if (!mounted) {
      return;
    }

    if (store.errorMessage != null) {
      showSavedMessage(context, 'Could not save transaction.');
      return;
    }

    showSavedMessage(context, 'Transaction saved successfully.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final categories = store.categories;
    final selectedCategory = categories.any((item) => item.name == category)
        ? category
        : (categories.isNotEmpty ? categories.first.name : null);
    category = selectedCategory;

    return CapyPageFrame(
      currentTab: AppTab.money,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Transaction details',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                amountController.text.isEmpty
                    ? '฿0.00'
                    : formatMoney(double.tryParse(amountController.text) ?? 0),
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                noteController.text.trim().isEmpty
                    ? 'Add a title and note for this transaction'
                    : noteController.text.trim(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),
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
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Coffee, Salary, Pocket transfer',
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
                labelText: 'Note',
                hintText: 'Add a short note',
              ),
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            WarmCard(
              color: const Color(0xFFF5E7D2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Slip / Receipt', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_slipImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_slipImage!.path),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _slipImage = null),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Remove'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openCamera,
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Retake'),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _SlipButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            onTap: _openCamera,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SlipButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: () => _pickSlip(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final clearButton = OutlinedButton(
                  onPressed: () {
                    amountController.clear();
                    titleController.clear();
                    noteController.clear();
                    setState(() {
                      type = CapyTransactionType.expense;
                      category = categories.isNotEmpty
                          ? categories.first.name
                          : null;
                      selectedDate = DateTime.now();
                    });
                  },
                  child: const Text('Clear'),
                );
                final saveButton = FilledButton(
                  onPressed: store.isSaving ? null : _saveTransaction,
                  child: Text(
                    store.isSaving ? 'Saving...' : 'Save transaction',
                  ),
                );

                if (constraints.maxWidth < 320) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: clearButton),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: saveButton),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: clearButton),
                    const SizedBox(width: 12),
                    Expanded(child: saveButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SlipButton extends StatelessWidget {
  const _SlipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: capySurfaceColor.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: capyLineColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: capyInkColor),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
