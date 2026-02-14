import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';

import 'package:tizon_app/features/auth/domain/auth_repository.dart';

import 'connectivity_service.dart';
import 'sync_service.dart';
import 'package:tizon_app/app/di.dart';

class AuthService implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivity = getIt<ConnectivityService>();
  final SyncService _sync = getIt<SyncService>();

  /// Inicia sesión con email y contraseña.
  /// Retorna null si fue exitoso, o un mensaje/código de error si falla.
  Future<String?> signInEmail(String email, String password) async {
    final box = await Hive.openBox('usuarios');

    // ✅ LOGIN OFFLINE
    if (!_connectivity.isOnline) {
      final users = box.get('usuarios_local', defaultValue: []) as List;

      final exists = users.any((u) =>
          u['email'] == email.trim() && u['password'] == password.trim());

      if (exists) {
        // ignore: avoid_print
        print('[OFFLINE] Usuario válido en el dispositivo');
        return null;
      }

      return 'NO_LOCAL_USER';
    }

    // ✅ LOGIN ONLINE
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'El usuario no existe en nuestros registros.';
      }
      if (e.code == 'wrong-password') {
        return 'La contraseña es incorrecta.';
      }
      if (e.code == 'invalid-credential') {
        return 'Credenciales inválidas. Verifica tu cédula y contraseña.';
      }
      return e.message;
    }
  }

  /// Registra usuario con email y contraseña.
  /// Retorna null si fue exitoso, o un mensaje/código de error si falla.
  Future<String?> registerEmail(String email, String password) async {
    final box = await Hive.openBox('usuarios');

    // ✅ REGISTRO OFFLINE
    if (!ConnectivityService().isOnline) {
      final users = box.get('usuarios_local', defaultValue: []) as List;
      users.add({'email': email.trim(), 'password': password.trim()});
      await box.put('usuarios_local', users);
      // ignore: avoid_print
      print('[OFFLINE] Usuario guardado offline: $email');
      return null;
    }

    // ✅ REGISTRO ONLINE
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Este usuario ya está registrado.';
      }
      return e.message;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'Inicio de sesión cancelado';

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<void> syncOfflineUsers() async {
    if (ConnectivityService().isOnline) {
      final box = await Hive.openBox('usuarios');
      final users = box.get('usuarios_local', defaultValue: []) as List;

      if (users.isNotEmpty) {
        _sync.startSync();

        for (final user in users) {
          try {
            await _auth.createUserWithEmailAndPassword(
              email: (user['email'] ?? '').toString(),
              password: (user['password'] ?? '').toString(),
            );
            // ignore: avoid_print
            print('[SYNC] Usuario creado: ${user['email']}');
          } catch (_) {
            try {
              await _auth.signInWithEmailAndPassword(
                email: (user['email'] ?? '').toString(),
                password: (user['password'] ?? '').toString(),
              );
              // ignore: avoid_print
              print('[SYNC] Usuario logueado: ${user['email']}');
            } catch (e) {
              // ignore: avoid_print
              print('[SYNC] Falló: ${user['email']} → $e');
            }
          }
        }

        await box.delete('usuarios_local');
        _sync.endSync();
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // ===== Implementación del contrato AuthRepository =====

  @override
  Future<void> signIn(String email, String password) async {
    final err = await signInEmail(email, password);
    if (err != null) {
      throw Exception(err);
    }
  }

  @override
  Future<void> register(String email, String password) async {
    final err = await registerEmail(email, password);
    if (err != null) {
      throw Exception(err);
    }
  }

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ===== Helpers =====
  User? get currentUser => _auth.currentUser;
}
