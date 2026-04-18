import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/capy_models.dart';
import '../services/firebase_service.dart';
import '../state/capy_scope.dart';
import 'ui_kit.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  // Amount is built by numpad — stored as raw string
  String _amountRaw = '';

  CapyTransactionType type = CapyTransactionType.expense;
  String? category;
  DateTime selectedDate = DateTime.now();
  XFile? _slipImage;
  Uint8List? _slipBytes;
  bool _uploadingReceipt = false;
  bool _seededFromRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededFromRoute) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CapyTransactionType) {
      type = args;
    }
    _seededFromRoute = true;
  }

  // ─── Numpad logic ─────────────────────────────────────────────────────────

  void _numpadTap(String key) {
    setState(() {
      if (key == '<') {
        // backspace
        if (_amountRaw.isNotEmpty) {
          _amountRaw = _amountRaw.substring(0, _amountRaw.length - 1);
        }
        return;
      }
      if (key == '.') {
        if (_amountRaw.contains('.')) return; // only one decimal point
        if (_amountRaw.isEmpty) _amountRaw = '0';
        _amountRaw += '.';
        return;
      }
      // Limit to 2 decimal places
      final dotIdx = _amountRaw.indexOf('.');
      if (dotIdx != -1 && _amountRaw.length - dotIdx > 2) return;
      // Prevent leading zeros
      if (_amountRaw == '0') {
        _amountRaw = key;
        return;
      }
      _amountRaw += key;
    });
  }

  String get _displayAmount {
    if (_amountRaw.isEmpty) return '0.00';
    final double? val = double.tryParse(_amountRaw);
    if (val == null) return _amountRaw;
    // If still typing after decimal, show raw
    if (_amountRaw.endsWith('.')) return '${val.toStringAsFixed(0)}.';
    final parts = _amountRaw.split('.');
    if (parts.length == 2 && parts[1].length == 1) {
      return '${val.toStringAsFixed(0)}.${parts[1]}';
    }
    return val == val.truncateToDouble()
        ? val.toStringAsFixed(2)
        : val.toStringAsFixed(2);
  }

  // ─── Date picker ──────────────────────────────────────────────────────────

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

  // ─── Receipt pick ──────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    await _pickSlip(ImageSource.camera);
  }

  Future<void> _pickSlip(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _slipImage = picked;
        _slipBytes = bytes;
      });
    }
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveTransaction() async {
    final parsedAmount = double.tryParse(_amountRaw);
    if (parsedAmount == null || parsedAmount <= 0 || category == null) {
      showSavedMessage(context, 'Please enter amount and select a category.');
      return;
    }

    final store = CapyScope.read(context);
    final uid = store.currentUser?.id;

    String? receiptUrl;
    if (_slipImage != null && uid != null) {
      setState(() => _uploadingReceipt = true);
      try {
        if (kIsWeb && _slipBytes != null) {
          receiptUrl = await FirebaseService.instance.uploadReceiptBytes(
            uid,
            _slipBytes!,
          );
        } else {
          receiptUrl = await FirebaseService.instance.uploadReceipt(
            uid,
            _slipImage!.path,
          );
        }
      } catch (_) {
        // proceed without receipt
      } finally {
        if (mounted) setState(() => _uploadingReceipt = false);
      }
    }

    final saved = await store.addTransaction(
      title: '${type.name[0].toUpperCase()}${type.name.substring(1)} entry',
      category: category!,
      note: '',
      amount: parsedAmount,
      type: type,
      createdAt: selectedDate,
      receiptImageUrl: receiptUrl,
    );

    if (!mounted) return;
    if (!saved || store.errorMessage != null) {
      showSavedMessage(context, 'Could not save transaction.');
      return;
    }
    showSavedMessage(context, 'Transaction saved successfully.');
    Navigator.of(context).pop();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = CapyScope.watch(context);
    final categories = store.categories;

    // auto-select first category
    if (category == null && categories.isNotEmpty) {
      category = categories.first.name;
    }

    final isBusy = store.isSaving || _uploadingReceipt;

    return CapyPageFrame(
      currentTab: AppTab.money,
      showFab: false,
      showBottomBar: false,
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
                          'Add Transaction',
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
                        _displayAmount,
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
                      final sel = type == t;
                      return ChoiceChip(
                        label: Text(t.name.toUpperCase()),
                        selected: sel,
                        onSelected: (_) => setState(() => type = t),
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
                    _CategoryChips(
                      categories: categories,
                      selected: category,
                      onSelect: (name) => setState(() => category = name),
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
                  const SizedBox(height: 16),

                  // Receipt upload zone
                  _ReceiptZone(
                    slipImage: _slipImage,
                    slipBytes: _slipBytes,
                    uploading: _uploadingReceipt,
                    onCamera: _openCamera,
                    onGallery: () => _pickSlip(ImageSource.gallery),
                    onRemove: () => setState(() {
                      _slipImage = null;
                      _slipBytes = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Fixed numpad + button at bottom ──
          _NumpadSection(
            onKey: _numpadTap,
            isBusy: isBusy,
            onSave: _saveTransaction,
          ),
        ],
      ),
    );
  }
}

// ─── Category chips ─────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<CapyCategory> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cat in categories)
          _CatChip(
            cat: cat,
            selected: selected == cat.name,
            onTap: () => onSelect(cat.name),
          ),
      ],
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
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

// ─── Receipt upload zone ──────────────────────────────────────────────────────

class _ReceiptZone extends StatelessWidget {
  const _ReceiptZone({
    required this.slipImage,
    required this.slipBytes,
    required this.uploading,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final XFile? slipImage;
  final Uint8List? slipBytes;
  final bool uploading;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = slipBytes != null;

    if (hasImage) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              slipBytes!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: capyInkColor.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          if (uploading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: capyInkColor.withValues(alpha: 0.4),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Dashed empty zone
    return GestureDetector(
      onTap: onCamera,
      child: DashedBorderBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: capySoftCardColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 28,
                color: capyMutedColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Upload Receipt',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text('Supports JPG, PNG or PDF', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ReceiptBtn(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: onCamera,
                ),
                const SizedBox(width: 10),
                _ReceiptBtn(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: onGallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptBtn extends StatelessWidget {
  const _ReceiptBtn({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: capySurfaceColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: capyLineColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: capyInkColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: capyInkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple dashed-border container
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = capyLineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    const r = 16.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(r),
        ),
      );
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Numpad section ────────────────────────────────────────────────────────────

class _NumpadSection extends StatelessWidget {
  const _NumpadSection({
    required this.onKey,
    required this.isBusy,
    required this.onSave,
  });

  final ValueChanged<String> onKey;
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
      decoration: BoxDecoration(
        color: capyBackgroundColor,
        border: Border(top: BorderSide(color: capyLineColor)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (int i = 0; i < row.length; i++) ...[
                    Expanded(
                      child: _NumKey(label: row[i], onTap: () => onKey(row[i])),
                    ),
                    if (i < row.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isBusy ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE8D3B4),
                foregroundColor: capyInkColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: capyInkColor,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Add Transaction'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBack = label == '<';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: capySurfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: capyLineColor),
          boxShadow: [
            BoxShadow(
              color: capyInkColor.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isBack
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 22,
                  color: capyInkColor,
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: capyInkColor,
                  ),
                ),
        ),
      ),
    );
  }
}
