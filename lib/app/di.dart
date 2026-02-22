import 'package:get_it/get_it.dart';

import 'package:tizon_app/services/auth_service.dart';
import 'package:tizon_app/services/connectivity_service.dart';
import 'package:tizon_app/services/local_db_service.dart';
import 'package:tizon_app/services/local_image_service.dart';
import 'package:tizon_app/services/sync_service.dart';

import 'package:tizon_app/core/sync/fincas_sync_handler.dart';
import 'package:tizon_app/core/sync/encuestas_sync_handler.dart';
import 'package:tizon_app/core/sync/medios_sync_handler.dart';

import 'package:tizon_app/features/fincas/domain/finca_repository.dart';
import 'package:tizon_app/features/fincas/data/finca_repository_impl.dart';

final getIt = GetIt.instance;

bool _diInitialized = false;

void setupDI() {
  if (_diInitialized) return; // ✅ evita doble llamada accidental
  _diInitialized = true;

  // Services
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  getIt.registerLazySingleton<SyncService>(() => SyncService());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<LocalDbService>(() => LocalDbService());
  getIt.registerLazySingleton<LocalImageService>(() => LocalImageService());

  // Sync handlers
  getIt.registerLazySingleton<FincasSyncHandler>(() => FincasSyncHandler());
  getIt.registerLazySingleton<EncuestasSyncHandler>(() => EncuestasSyncHandler());
  getIt.registerLazySingleton<MediosSyncHandler>(() => MediosSyncHandler());

  // Repositories
  getIt.registerLazySingleton<FincaRepository>(() => FincaRepositoryImpl());
}