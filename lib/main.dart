import 'package:flutter/material.dart';
import 'services/preferences_service.dart';
import 'services/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services BEFORE running the app (so providers can access them)
  await PreferencesService.init();
  await HiveService.init();

  runApp(const LogitApp());
}
