import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tizon_app/services/auth_service.dart';
import 'package:tizon_app/services/connectivity_service.dart';
import 'package:tizon_app/services/sync_service.dart';

import '../firebase_options.dart';
import '../services/hive_init.dart';
import '../services/sync_status.dart';
import 'di.dart';

class AppBootstrap {
  Future<void> init() async {
    // 1. Hive primero — local, rápido, no depende de internet
    await HiveInit.initialize();

    // 2. Firebase — con timeout para no bloquear si no hay internet
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 5));

      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // Firebase no disponible — app funciona igual con Hive local
      debugPrint('[BOOTSTRAP] Firebase no disponible: $e');
    }

    // 3. Conectividad — solo inicializar el listener, no bloquear
    final connectivity = getIt.get<ConnectivityService>();
    await connectivity.initialize();

    // 4. Sync y auth en segundo plano — NO bloquean el arranque
    _iniciarSyncEnSegundoPlano();
  }

  /// Corre todo lo pesado DESPUÉS de que la app ya está visible
  /// usando Future.microtask para no bloquear el primer frame
  void _iniciarSyncEnSegundoPlano() {
    Future.microtask(() async {
      final connectivity = getIt.get<ConnectivityService>();
      final syncService  = getIt.get<SyncService>();
      final authService  = getIt.get<AuthService>();

      // Inicializar listener de sync
      syncService.initialize();

      if (!connectivity.isOnline) {
        SyncStatus.set(SyncState.offline, msg: 'Sin internet');
        return;
      }

      // Sync de usuarios offline primero
      try {
        await authService.syncOfflineUsers();
      } catch (e) {
        debugPrint('[BOOTSTRAP] syncOfflineUsers falló: $e');
      }

      // Sync completa de datos
      try {
        SyncStatus.set(SyncState.syncing, msg: 'Sincronizando…');
        await syncService.syncAll();
        SyncStatus.set(SyncState.idleOnline, msg: 'Todo al día');
      } catch (e) {
        SyncStatus.set(SyncState.error, msg: 'Error de sync');
        debugPrint('[BOOTSTRAP] syncAll falló: $e');
      }
    });
  }
}
