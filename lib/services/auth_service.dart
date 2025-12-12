import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> signInEmail(String email, String password) async {
    var box = await Hive.openBox('usuarios');

    // ✅ LOGIN OFFLINE
    if (!ConnectivityService().isOnline) {
      final users = box.get('usuarios_local', defaultValue: []) as List;

      final exists = users.any((u) =>
          u['email'] == email.trim() &&
          u['password'] == password.trim());

      if (exists) {
        print('[OFFLINE] Usuario válido en el dispositivo');
        return null;
      }

      return 'NO_LOCAL_USER'; // ✅ Activa tu modal
    }

    // ✅ LOGIN ONLINE
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      // ✅ Mensajes más claros
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

  Future<String?> registerEmail(String email, String password) async {
    var box = await Hive.openBox('usuarios');

    // ✅ REGISTRO OFFLINE
    if (!ConnectivityService().isOnline) {
      final users = box.get('usuarios_local', defaultValue: []) as List;
      users.add({'email': email.trim(), 'password': password.trim()});
      await box.put('usuarios_local', users);
      print('[OFFLINE] Usuario guardado offline: $email');
      return null;
    }

    // ✅ REGISTRO ONLINE
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
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

  Future<void> syncOfflineUsers() async {
    if (ConnectivityService().isOnline) {
      var box = await Hive.openBox('usuarios');
      final users = box.get('usuarios_local', defaultValue: []) as List;

      if (users.isNotEmpty) {
        SyncService().startSync();

        for (var user in users) {
          try {
            await _auth.createUserWithEmailAndPassword(
              email: user['email'],
              password: user['password'],
            );
            print('[SYNC] Usuario creado: ${user['email']}');
          } catch (_) {
            try {
              await _auth.signInWithEmailAndPassword(
                email: user['email'],
                password: user['password'],
              );
              print('[SYNC] Usuario logueado: ${user['email']}');
            } catch (e) {
              print('[SYNC] Falló: ${user['email']} → $e');
            }
          }
        }

        await box.delete('usuarios_local');
        SyncService().endSync();
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  User? get currentUser => _auth.currentUser;
}