import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';

// ✅ Servicios
import 'services/connectivity_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';

// ✅ Pantallas
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// ✅ Widgets
import 'widgets/connectivity_indicator.dart';
import 'widgets/sync_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Inicializar Hive (OBLIGATORIO en Android/iOS)
  await Hive.initFlutter();

  // ✅ Configurar Firestore offline
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ✅ Inicializar conectividad
  await ConnectivityService().initialize();

  // ✅ Sincronizar usuarios offline al iniciar
  await AuthService().syncOfflineUsers();

  runApp(const MyApp());
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
            child = const Scaffold(
              body: Center(child: CircularProgressIndicator(strokeWidth: 6)),
            );
          } else if (snapshot.hasData) {
            child = const HomeScreen();
          } else {
            child = const LoginScreen();
          }

          return StreamBuilder<bool>(
            stream: ConnectivityService().onConnectivityChanged,
            initialData: ConnectivityService().isOnline,
            builder: (context, connSnapshot) {
              final isOnline = connSnapshot.data ?? true;

              // ✅ LOG cuando vuelve internet
              if (isOnline) {
                print("🌐 [MAIN] Internet detectado → intentando sincronizar usuarios...");
                AuthService().syncOfflineUsers();
              }

              return StreamBuilder<bool>(
                stream: SyncService().onSyncChanged,
                initialData: SyncService().isSyncing,
                builder: (context, syncSnapshot) {
                  final isSyncing = syncSnapshot.data ?? false;

                  return Stack(
                    children: [
                      child,
                      ConnectivityIndicator(isOnline: isOnline),
                      SyncIndicator(isSyncing: isSyncing),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}