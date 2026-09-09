import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await AppPreferences.create();
  runApp(VisualinApp(preferences: preferences));
}
