import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';

import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = AppBootstrap(
    syncService: SyncService(),
    connectivityService: ConnectivityService(),
    authService: AuthService(),
  );

  await bootstrap.init();

  runApp(const App());
}
