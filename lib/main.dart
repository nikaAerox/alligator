import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/storage/app_storage_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await createAppStorage();
  runApp(MedicareApp(storage: storage));
}
