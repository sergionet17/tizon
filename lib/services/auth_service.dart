import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Login con email
  Future<String?> signInEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Usuario no encontrado';
      if (e.code == 'wrong-password') return 'Contraseña incorrecta';
      return 'Error: ${e.message}';
    }
  }

  // Registro con email
  Future<String?> registerEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Este correo ya está registrado';
      if (e.code == 'weak-password') return 'Contraseña muy débil';
      return 'Error: ${e.message}';
    }
  }

  // Login con Google
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
    } catch (e) {
      return 'Error con Google: $e';
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}