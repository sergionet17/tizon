// lib/app/bootstrap.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_options.dart';
import '../services/hive_init.dart';
import '../services/connectivity_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/sync_status.dart';

class AppBootstrap {
  final SyncService syncService;
  final ConnectivityService connectivityService;
  final AuthService authService;

  AppBootstrap({
    required this.syncService,
    required this.connectivityService,
    required this.authService,
  });

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await HiveInit.initialize();

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await connectivityService.initialize();

    syncService.initialize();

    await authService.syncOfflineUsers();

    if (connectivityService.isOnline) {
      await runFullSync();
    } else {
      SyncStatus.set(SyncState.offline, msg: 'Sin internet');
    }
  }

  Future<void> runFullSync() async {
    SyncStatus.set(SyncState.syncing, msg: 'Sincronizando…');
    try {
      await syncService.syncAll();
      SyncStatus.set(SyncState.idleOnline, msg: 'Todo al día');
    } catch (e) {
      SyncStatus.set(SyncState.error, msg: 'Error: $e');
    }
  }
}
