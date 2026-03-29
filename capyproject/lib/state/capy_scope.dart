import 'package:flutter/widgets.dart';

import 'capy_app_store.dart';

class CapyScope extends InheritedNotifier<CapyAppStore> {
  const CapyScope({
    super.key,
    required CapyAppStore store,
    required super.child,
  }) : super(notifier: store);

  static CapyAppStore watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CapyScope>();
    assert(scope != null, 'CapyScope.watch called with no CapyScope found.');
    return scope!.notifier!;
  }

  static CapyAppStore read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<CapyScope>();
    final scope = element?.widget as CapyScope?;
    assert(scope != null, 'CapyScope.read called with no CapyScope found.');
    return scope!.notifier!;
  }
}
