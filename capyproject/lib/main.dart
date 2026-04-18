import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/capy_pocket_app.dart';
import 'state/capy_app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final store = CapyAppStore();
  await store.initialize();
  runApp(CapyPocketApp(store: store));
}
