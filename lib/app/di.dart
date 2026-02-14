import 'package:get_it/get_it.dart';

import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

final getIt = GetIt.instance;

void setupDI() {
  // Services (singletons)
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<SyncService>(() => SyncService());
}
