import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> upsertCurrentUser() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await _db.collection('users').doc(u.uid).set({
      'uid': u.uid,
      'email': u.email,
      'displayName': u.displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addFootprintSample({required String category, required double kg}) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await _db.collection('users').doc(u.uid).collection('footprints').add({
      'category': category, // e.g. 'transport'
      'kg': kg,
      'ts': FieldValue.serverTimestamp(),
    });
  }
}
