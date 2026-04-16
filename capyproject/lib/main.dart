import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/capy_pocket_app.dart';
import 'state/capy_app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop uses sqlite via FFI and requires an explicit factory initialization.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await dotenv.load(fileName: '.env.example');
  } catch (_) {
    // Allow startup without env file, app will fallback to dart-define/default values.
  }
  final store = CapyAppStore();
  await store.initialize();
  runApp(CapyPocketApp(store: store));
}
