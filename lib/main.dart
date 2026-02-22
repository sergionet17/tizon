import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupDI();
  await AppBootstrap().init();

  runApp(const App());
}