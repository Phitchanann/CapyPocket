import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/capy_models.dart';
import '../state/capy_scope.dart';

const capyBackgroundColor = Color(0xFFFBF7F1);
const capySurfaceColor = Color(0xFFFFFFFF);
const capySoftCardColor = Color(0xFFF3E3CE);
const capySoftCardAltColor = Color(0xFFE8D3B4);
const capyLineColor = Color(0xFFE7D7C4);
const capyInkColor = Color(0xFF3E2F22);
const capyMutedColor = Color(0xFF8B7764);
const capyAccentColor = Color(0xFFC38B55);
const capyPositiveColor = Color(0xFF4F8D69);
const capyNegativeColor = Color(0xFFBF6B59);
const capyBodyColor = Color(0xFFA56B3F);
const capyBodyDarkColor = Color(0xFF7D4E2E);

ThemeData buildCapyTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: capyAccentColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: capyInkColor,
          secondary: capyAccentColor,
          tertiary: capySoftCardAltColor,
          surface: capySurfaceColor,
        ),
  );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: capyLineColor),
  );

  return base.copyWith(
    scaffoldBackgroundColor: capyBackgroundColor,
    textTheme: base.textTheme.copyWith(
      headlineMedium: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: capyInkColor,
        height: 1.05,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: capyInkColor,
        height: 1.1,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: capyInkColor,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: capyInkColor,
      ),
      bodyLarge: const TextStyle(
        fontSize: 15,
        color: capyInkColor,
        height: 1.4,
      ),
      bodyMedium: const TextStyle(
        fontSize: 13,
        color: capyMutedColor,
        height: 1.45,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: capyInkColor,
        letterSpacing: 0.2,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: capyMutedColor,
        letterSpacing: 0.2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: capySurfaceColor,
      hintStyle: const TextStyle(fontSize: 13, color: capyMutedColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: capyAccentColor, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: capyInkColor,
        foregroundColor: capySurfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: capyInkColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        side: const BorderSide(color: capyLineColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: capyInkColor,
      contentTextStyle: TextStyle(
        color: capySurfaceColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

enum AppTab { home, goals, money, profile }

final ValueNotifier<AppTab> rootTabNotifier = ValueNotifier(AppTab.home);

void navigateToTab(BuildContext context, AppTab tab) {
  final navigator = Navigator.of(context);
  final isAtRoot = !navigator.canPop();
  final isSameTab = rootTabNotifier.value == tab;

  if (isAtRoot && isSameTab) {
    return;
  }

  if (!isSameTab) {
    rootTabNotifier.value = tab;
  }

  if (isAtRoot) {
    return;
  }

  navigator.popUntil((route) => route.isFirst);
}

class CapyPageFrame extends StatelessWidget {
  const CapyPageFrame({
    super.key,
    required this.child,
    this.currentTab,
    this.showBottomBar = true,
    this.showFab = true,
    this.onFabPressed,
  });

  final Widget child;
  final AppTab? currentTab;
  final bool showBottomBar;
  final bool showFab;
  final VoidCallback? onFabPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: showBottomBar,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [capyBackgroundColor, Color(0xFFF6EFE4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: SoftBackground()),
            SafeArea(bottom: false, child: child),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: showFab
          ? FloatingActionButton(
              backgroundColor: capyInkColor,
              foregroundColor: capySurfaceColor,
              elevation: 2,
              onPressed: onFabPressed ?? () => showQuickAddSheet(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: showBottomBar
          ? BottomBar(
              currentTab: currentTab,
              onChanged: (tab) => navigateToTab(context, tab),
              interactive: true,
            )
          : null,
    );
  }
}

class WarmCard extends StatelessWidget {
  const WarmCard({
    super.key,
    required this.child,
    this.color = capySurfaceColor,
  });

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: capyLineColor),
        boxShadow: [
          BoxShadow(
            color: capyInkColor.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    required this.trailing,
  });

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(trailing, style: theme.textTheme.labelMedium),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                trailing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        );
      },
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: capySurfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: capyLineColor),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class MiniStatCard extends StatelessWidget {
  const MiniStatCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: capySurfaceColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: capyLineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class InlineMetric extends StatelessWidget {
  const InlineMetric({
    super.key,
    required this.label,
    required this.value,
    this.positive = false,
  });

  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: positive ? capyPositiveColor : capyNegativeColor,
          ),
        ),
      ],
    );
  }
}

class CapyBadge extends StatelessWidget {
  const CapyBadge({super.key, required this.size, this.halo = false});

  final double size;
  final bool halo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (halo)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: capySoftCardColor.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          Positioned(
            top: size * 0.14,
            left: size * 0.18,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: const BoxDecoration(
                color: capyBodyDarkColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.14,
            right: size * 0.18,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: const BoxDecoration(
                color: capyBodyDarkColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: size * 0.68,
            height: size * 0.68,
            decoration: BoxDecoration(
              color: capyBodyColor,
              borderRadius: BorderRadius.circular(size * 0.26),
            ),
          ),
          Positioned(
            bottom: size * 0.23,
            child: Container(
              width: size * 0.36,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D3B4),
                borderRadius: BorderRadius.circular(size * 0.16),
              ),
            ),
          ),
          Positioned(
            top: size * 0.38,
            left: size * 0.31,
            child: Container(
              width: size * 0.06,
              height: size * 0.06,
              decoration: const BoxDecoration(
                color: capyInkColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.38,
            right: size * 0.31,
            child: Container(
              width: size * 0.06,
              height: size * 0.06,
              decoration: const BoxDecoration(
                color: capyInkColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.33,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: capyBodyDarkColor,
                borderRadius: BorderRadius.circular(size * 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -10,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: capySoftCardAltColor.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 260,
            left: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: capySoftCardColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 180,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: capySoftCardAltColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AmountChip extends StatelessWidget {
  const AmountChip({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: capySurfaceColor,
      side: const BorderSide(color: capyLineColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onPressed: onPressed,
    );
  }
}

class KeypadButton extends StatelessWidget {
  const KeypadButton({super.key, this.label, this.icon, this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: capySurfaceColor.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: capyLineColor),
            boxShadow: [
              BoxShadow(
                color: capyInkColor.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: capyInkColor, size: 22)
                : Text(
                    label ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class FormFieldCard extends StatelessWidget {
  const FormFieldCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: capySoftCardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: capyInkColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded, color: capyMutedColor),
        ],
      ),
    );
  }
}

class BudgetLimitRow extends StatelessWidget {
  const BudgetLimitRow({
    super.key,
    required this.title,
    required this.spent,
    required this.limit,
    this.progress = 0.68,
  });

  final String title;
  final String spent;
  final String limit;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(limit, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text('Spent $spent', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: capySoftCardColor,
              color: capyAccentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: capyInkColor, size: 30),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class ReminderSwitchRow extends StatelessWidget {
  const ReminderSwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class TimeChip extends StatelessWidget {
  const TimeChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: capySurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: capyLineColor),
      ),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class SettingLine extends StatelessWidget {
  const SettingLine({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = WarmCard(
      child: Row(
        children: [
          Icon(icon, color: capyInkColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Icon(
            onTap == null
                ? Icons.info_outline_rounded
                : Icons.chevron_right_rounded,
            color: capyMutedColor,
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return GestureDetector(onTap: onTap, child: card);
  }
}

class SettingToggle extends StatelessWidget {
  const SettingToggle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Row(
        children: [
          Icon(icon, color: capyInkColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class AuthCard extends StatefulWidget {
  const AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.fields,
    this.onSubmit,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final List<String> fields;
  final Function(String username)? onSubmit;

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.fields.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: CapyBadge(size: 66, halo: true)),
          const SizedBox(height: 16),
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(widget.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ..._controllers.asMap().entries.map((entry) {
            final field = widget.fields[entry.key];
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: controller,
                obscureText: field.toLowerCase().contains('password'),
                decoration: InputDecoration(labelText: field),
              ),
            );
          }),
          FilledButton(
            onPressed: () {
              final username = _controllers.first.text.isNotEmpty
                  ? _controllers.first.text
                  : 'User';
              widget.onSubmit?.call(username);
            },
            child: Text(widget.buttonLabel),
          ),
        ],
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onPressed,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      color: const Color(0xFFF6EEDF),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: capySurfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: capyLineColor),
            ),
            child: Icon(icon, color: capyInkColor, size: 34),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class ActionItem {
  const ActionItem({
    required this.title,
    required this.caption,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String caption;
  final IconData icon;
  final Color tint;
}

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.action, required this.onTap});

  final ActionItem action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: capySurfaceColor.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: capyLineColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: action.tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: action.tint),
            ),
            const SizedBox(height: 14),
            Text(action.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(action.caption, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class TransactionEntry {
  const TransactionEntry({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.tint,
    this.positive = false,
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color tint;
  final bool positive;
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.entry});

  final TransactionEntry entry;

  @override
  Widget build(BuildContext context) {
    final amountColor = entry.positive ? capyPositiveColor : capyInkColor;

    return WarmCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: entry.tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(entry.icon, color: entry.tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.amount,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }
}

class SignalRow extends StatelessWidget {
  const SignalRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: capySoftCardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: capyInkColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrendPainter extends CustomPainter {
  const TrendPainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = capyLineColor
      ..strokeWidth = 1;

    for (var index = 1; index <= 3; index++) {
      final y = (size.height / 4) * index;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) {
      return;
    }

    final path = Path();
    final fillPath = Path();
    final highestPoint = points.reduce(
      (current, next) => current > next ? current : next,
    );
    final denominator = highestPoint <= 0 ? 1.0 : highestPoint;
    final usableHeight = size.height - 24;
    final step = points.length == 1 ? 0.0 : size.width / (points.length - 1);

    for (var index = 0; index < points.length; index++) {
      final x = step * index;
      final normalizedPoint = points[index] / denominator;
      final y = size.height - (normalizedPoint * usableHeight) - 12;
      if (index == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x55C38B55), Color(0x00C38B55)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    final linePaint = Paint()
      ..color = capyAccentColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = capyInkColor;
    for (var index = 0; index < points.length; index++) {
      final x = step * index;
      final normalizedPoint = points[index] / denominator;
      final y = size.height - (normalizedPoint * usableHeight) - 12;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = capySurfaceColor);
    }
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) {
    return !listEquals(oldDelegate.points, points);
  }
}

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.currentTab,
    required this.onChanged,
    this.interactive = true,
  });

  final AppTab? currentTab;
  final ValueChanged<AppTab> onChanged;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: capySurfaceColor.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: capyLineColor),
            boxShadow: [
              BoxShadow(
                color: capyInkColor.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: BottomBarItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentTab == AppTab.home,
                  onTap: interactive ? () => onChanged(AppTab.home) : null,
                ),
              ),
              Expanded(
                child: BottomBarItem(
                  icon: Icons.savings_outlined,
                  label: 'Goals',
                  selected: currentTab == AppTab.goals,
                  onTap: interactive ? () => onChanged(AppTab.goals) : null,
                ),
              ),
              const SizedBox(width: 62),
              Expanded(
                child: BottomBarItem(
                  icon: Icons.insert_chart_outlined_rounded,
                  label: 'Money',
                  selected: currentTab == AppTab.money,
                  onTap: interactive ? () => onChanged(AppTab.money) : null,
                ),
              ),
              Expanded(
                child: BottomBarItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  selected: currentTab == AppTab.profile,
                  onTap: interactive ? () => onChanged(AppTab.profile) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomBarItem extends StatelessWidget {
  const BottomBarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? capyInkColor : capyMutedColor;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

const homeActions = [
  ActionItem(
    title: 'Receive',
    caption: 'Add money in fast',
    icon: Icons.call_received_rounded,
    tint: capyPositiveColor,
  ),
  ActionItem(
    title: 'Send',
    caption: 'Pay from your wallet',
    icon: Icons.send_rounded,
    tint: capyNegativeColor,
  ),
  ActionItem(
    title: 'Save',
    caption: 'Grow your capy pocket',
    icon: Icons.savings_rounded,
    tint: capyAccentColor,
  ),
  ActionItem(
    title: 'History',
    caption: 'Review past moves',
    icon: Icons.history_rounded,
    tint: capyInkColor,
  ),
];

Future<void> showQuickAddSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickAddSheet(rootContext: context),
  );
}

Future<void> showGoalSetupSheet(
  BuildContext context, {
  CapyGoal? initialGoal,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _GoalSetupSheet(rootContext: context, initialGoal: initialGoal),
  );
}

class _QuickAddSheet extends StatefulWidget {
  const _QuickAddSheet({required this.rootContext});

  final BuildContext rootContext;

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  late final TextEditingController amountController;
  late final TextEditingController noteController;

  var entryType = 'Expense';
  String? category;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(text: '0.00');
    noteController = TextEditingController();
    final categories = CapyScope.read(widget.rootContext).categories;
    if (categories.isNotEmpty) {
      category = categories.first.name;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  CapyTransactionType _currentType() {
    return switch (entryType) {
      'Income' => CapyTransactionType.income,
      'Pocket' => CapyTransactionType.pocket,
      _ => CapyTransactionType.expense,
    };
  }

  Future<void> _saveEntry() async {
    final rootContext = widget.rootContext;
    final parsedAmount = double.tryParse(
      amountController.text.replaceAll(',', '').trim(),
    );

    if (parsedAmount == null || parsedAmount <= 0 || category == null) {
      showSavedMessage(
        rootContext,
        'Please enter an amount and choose a category.',
      );
      return;
    }

    final store = CapyScope.read(rootContext);
    final selectedCategory = category!;
    final message = '$entryType saved in $selectedCategory';
    await store.addTransaction(
      title: '$entryType • $selectedCategory',
      category: selectedCategory,
      note: noteController.text.trim(),
      amount: parsedAmount,
      type: _currentType(),
    );
    if (!mounted) {
      return;
    }
    if (store.errorMessage != null) {
      if (rootContext.mounted) {
        showSavedMessage(rootContext, 'Could not save entry.');
      }
      return;
    }

    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootContext.mounted) {
        showSavedMessage(rootContext, message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final store = CapyScope.watch(context);
    final categoryOptions = store.categories;
    final selectedCategory =
        categoryOptions.any((item) => item.name == category)
        ? category
        : (categoryOptions.isNotEmpty ? categoryOptions.first.name : null);
    category = selectedCategory;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: capyBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: capyLineColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Quick add',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Start your first entry from 0.00.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Expense', 'Income', 'Pocket']
                      .map(
                        (label) => ChoiceChip(
                          selected: entryType == label,
                          label: Text(label),
                          selectedColor: capyInkColor,
                          labelStyle: TextStyle(
                            color: entryType == label
                                ? capySurfaceColor
                                : capyInkColor,
                            fontWeight: FontWeight.w700,
                          ),
                          side: const BorderSide(color: capyLineColor),
                          backgroundColor: capySurfaceColor,
                          onSelected: (_) {
                            setState(() => entryType = label);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '฿ ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categoryOptions
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.name,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Add a note',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saveEntry,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalSetupSheet extends StatefulWidget {
  const _GoalSetupSheet({required this.rootContext, this.initialGoal});

  final BuildContext rootContext;
  final CapyGoal? initialGoal;

  @override
  State<_GoalSetupSheet> createState() => _GoalSetupSheetState();
}

class _GoalSetupSheetState extends State<_GoalSetupSheet> {
  late final TextEditingController nameController;
  late final TextEditingController targetController;
  late final TextEditingController savedController;

  bool get isEditing => widget.initialGoal != null;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.initialGoal?.name ?? 'Emergency pocket',
    );
    targetController = TextEditingController(
      text: (widget.initialGoal?.targetAmount ?? 10000).toStringAsFixed(0),
    );
    savedController = TextEditingController(
      text: (widget.initialGoal?.savedAmount ?? 0).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    targetController.dispose();
    savedController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final rootContext = widget.rootContext;
    final target = double.tryParse(targetController.text.replaceAll(',', ''));
    final saved =
        double.tryParse(savedController.text.replaceAll(',', '')) ?? 0;
    final name = nameController.text.trim();

    if (name.isEmpty || target == null || target <= 0) {
      showSavedMessage(
        rootContext,
        'Please add a goal name and target amount.',
      );
      return;
    }

    final store = CapyScope.read(rootContext);
    if (isEditing) {
      await store.updateGoal(
        widget.initialGoal!.copyWith(
          name: name,
          targetAmount: target,
          savedAmount: saved,
        ),
      );
    } else {
      await store.addGoal(name: name, targetAmount: target, savedAmount: saved);
    }

    if (!mounted) {
      return;
    }

    if (store.errorMessage != null) {
      if (rootContext.mounted) {
        showSavedMessage(rootContext, 'Could not save goal.');
      }
      return;
    }

    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootContext.mounted) {
        showSavedMessage(
          rootContext,
          isEditing ? 'Goal updated.' : 'Goal created.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: capyBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: capyLineColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isEditing ? 'Edit savings goal' : 'Create savings goal',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Set a target so your pocket has something to grow toward.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal name',
                    hintText: 'Emergency pocket',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Target amount',
                    prefixText: '฿ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: savedController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Current saved',
                    prefixText: '฿ ',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saveGoal,
                  icon: const Icon(Icons.savings_rounded),
                  label: Text(isEditing ? 'Update goal' : 'Save goal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showSavedMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
