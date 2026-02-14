import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

// ✅ Servicios
import 'services/connectivity_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/hive_init.dart';
import 'services/sync_status.dart';

// ✅ Pantallas
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// ✅ Widgets
import 'widgets/connectivity_indicator.dart';
import 'widgets/sync_indicator.dart';

import 'services/local_db_service.dart';

StreamSubscription<bool>? _connSub;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ [MAIN] Firebase inicializado');

    await HiveInit.initialize();
    print('✅ [MAIN] Hive inicializado');

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await ConnectivityService().initialize();
    print('✅ [MAIN] ConnectivityService inicializado');

    final syncService = SyncService();
    syncService.initialize();
    print('✅ [MAIN] SyncService inicializado');

    // ✅ Sincronizar usuarios offline al iniciar
    await AuthService().syncOfflineUsers();

    // ✅ Intentar sincronizar datos al iniciar (solo si hay internet)
    if (ConnectivityService().isOnline) {
      await _runFullSync(syncService);
    } else {
      SyncStatus.set(SyncState.offline, msg: 'Sin internet');
    }

    // ✅ Listener global: cuando vuelva internet, sincroniza UNA vez por evento
    _connSub?.cancel();
    _connSub =
        ConnectivityService().onConnectivityChanged.listen((isOnline) async {
      if (isOnline) {
        print("🌐 [MAIN] Internet detectado → sincronizando...");
        await AuthService().syncOfflineUsers();
        await _runFullSync(syncService);
      } else {
        SyncStatus.set(SyncState.offline, msg: 'Sin internet');
      }
    });

    runApp(const MyApp());
  } catch (e) {
    print('❌ [MAIN] Error en inicialización: $e');
    runApp(const ErrorApp());
  }
}

Future<void> _runFullSync(SyncService syncService) async {
  // ✅ UI state
  SyncStatus.set(SyncState.syncing, msg: 'Subiendo cambios…');

  try {
    await syncService.syncAll();
    // si sigue online, queda idleOnline
    if (ConnectivityService().isOnline) {
      SyncStatus.set(SyncState.idleOnline, msg: 'Todo al día');
    } else {
      SyncStatus.set(SyncState.offline, msg: 'Sin internet');
    }
  } catch (e) {
    SyncStatus.set(SyncState.error, msg: '$e');
    print('⚠️ [MAIN] Error en sincronización: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tizón',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          Widget child;

          if (snapshot.connectionState == ConnectionState.waiting) {
            print("🟡 [AUTH] Estado: esperando conexión con Firebase");
            child = const Scaffold(
              body: Center(child: CircularProgressIndicator(strokeWidth: 6)),
            );
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            print("✅ [AUTH] Usuario autenticado: ${user.uid}");
            LocalDbService().setUser(user.uid);
            child = const HomeScreen();
          } else {
            print("🔴 [AUTH] No hay usuario → LoginScreen");
            child = const LoginScreen();
          }

          return StreamBuilder<bool>(
            stream: ConnectivityService().onConnectivityChanged,
            initialData: ConnectivityService().isOnline,
            builder: (context, connSnapshot) {
              final isOnline = connSnapshot.data ?? true;
              print("🌐 [CONN] Estado conexión: $isOnline");

              return Stack(
                children: [
                  child,
                  ConnectivityIndicator(isOnline: isOnline),
                  const SyncIndicator(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al inicializar la aplicación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Por favor, reinicia la aplicación'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  main();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
