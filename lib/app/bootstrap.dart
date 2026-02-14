import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tizon_app/services/auth_service.dart';
import 'package:tizon_app/services/connectivity_service.dart';
import 'package:tizon_app/services/sync_service.dart';

import '../firebase_options.dart';
import '../services/hive_init.dart';
import '../services/sync_status.dart';
import 'di.dart';

class AppBootstrap {
  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await HiveInit.initialize();

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // 1 sola instancia global
    final connectivity = getIt.get<ConnectivityService>();
    final syncService = getIt.get<SyncService>();
    final authService = getIt.get<AuthService>();

    await connectivity.initialize();
    syncService.initialize();
    await authService.syncOfflineUsers();

    if (connectivity.isOnline) {
      await _runFullSync(syncService);
    } else {
      SyncStatus.set(SyncState.offline, msg: 'Sin internet');
    }
  }

  Future<void> _runFullSync(SyncService syncService) async {
    SyncStatus.set(SyncState.syncing, msg: 'Sincronizando…');
    try {
      await syncService.syncAll();
      SyncStatus.set(SyncState.idleOnline, msg: 'Todo al día');
    } catch (e) {
      SyncStatus.set(SyncState.error, msg: 'Error: $e');
    }
  }
}
