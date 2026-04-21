import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tizon_app/features/auth/presentation/login_screen.dart';
import 'package:tizon_app/features/home/presentation/home_screen.dart';
import 'package:tizon_app/services/auth_service.dart';
import 'package:tizon_app/services/connectivity_service.dart';
import 'package:tizon_app/app/di.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = getIt<ConnectivityService>();
    final authService  = getIt<AuthService>();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // ── CON INTERNET: Firebase respondió ────────────────────────
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data != null) return const HomeScreen();
          if (connectivity.isOnline)  return const LoginScreen();
        }

        // ── SIN INTERNET o Firebase cargando: usar sesión local ─────
        return FutureBuilder<String?>(
          future: authService.getSesionActual(),
          builder: (context, localSnap) {
            if (localSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Hay sesión activa guardada → entrar
            if (localSnap.data != null) return const HomeScreen();
            // No hay sesión → login
            return const LoginScreen();
          },
        );
      },
    );
  }
}
