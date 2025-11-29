import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/connectivity_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/connectivity_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Habilitar persistencia offline en Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Inicializar servicio de conectividad
  await ConnectivityService().initialize();
  
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
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 18),
        ),
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

          // ✅ Indicador de conectividad elegante
          return StreamBuilder<bool>(
            stream: ConnectivityService().onConnectivityChanged,
            initialData: ConnectivityService().isOnline,
            builder: (context, connSnapshot) {
              final isOnline = connSnapshot.data ?? true;
              return Stack(
                children: [
                  child,
                  ConnectivityIndicator(isOnline: isOnline),
                ],
              );
            },
          );
        },
      ),
    );
  }
}