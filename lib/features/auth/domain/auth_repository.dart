import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signOut();

  Future<void> syncOfflineUsers();
  Stream<User?> get authStateChanges;
}
