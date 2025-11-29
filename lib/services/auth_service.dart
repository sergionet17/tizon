import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '11613710443-7c47qha5gap2f42n4scc1ovk5f87rgv2.apps.googleusercontent.com'
        : null,
    scopes: ['email'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  String _generateEmail(String cedula) {
    return '$cedula@tizonapp.com';
  }

  Future<String?> signInWithCedula(String cedula, String password) async {
    try {
      final email = _generateEmail(cedula);
      await _auth.setPersistence(Persistence.LOCAL);
      return await signInEmail(email, password);
    } catch (e) {
      return 'Error al iniciar sesión: $e';
    }
  }

  Future<String?> registerWithCedula(String cedula, String password) async {
    final email = _generateEmail(cedula);
    return registerEmail(email, password);
  }

  Future<String?> signInEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Usuario no encontrado';
      if (e.code == 'wrong-password') return 'Contraseña incorrecta';
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<String?> registerEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Este correo ya está registrado';
      if (e.code == 'weak-password') return 'Contraseña muy débil';
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Inicio de sesión cancelado';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null;
    } catch (e, st) {
      print('Error en signInWithGoogle: $e');
      print(st);
      return 'Error con Google: $e';
    }
  }

  Future<void> checkAuthState() async {
    await _auth.setPersistence(Persistence.LOCAL);
    if (_auth.currentUser != null) {
      print('Usuario autenticado: ${_auth.currentUser!.email}');
    } else {
      print('No hay usuario autenticado');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}