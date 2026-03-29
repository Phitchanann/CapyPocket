import 'package:flutter/material.dart';

import 'pages/capy_pocket_app.dart';
import 'state/capy_app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = CapyAppStore();
  await store.initialize();
  runApp(CapyPocketApp(store: store));
}
