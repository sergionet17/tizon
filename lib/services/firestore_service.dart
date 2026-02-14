// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/finca.dart'; // IMPORTAR del modelo correcto
import '../models/encuesta.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener fincas del usuario desde Firestore
  Stream<List<Finca>> getUserFincas() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('fincas')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Finca(
          firebaseId: doc.id,
          nombre: data['nombre'] ?? '',
          ubicacion: data['ubicacion'] ?? '',
          cultivo: data['cultivo'],
          area: data['area']?.toDouble(),
          imageUrl: data['imageUrl'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  // Crear finca en Firestore (ya no se usa directamente, usa sync_service)
  Future<void> createFinca({
    required String nombre,
    required String ubicacion,
    String? cultivo,
    double? area,
    String? imageUrl,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    await _firestore.collection('fincas').add({
      'nombre': nombre,
      'ubicacion': ubicacion,
      'cultivo': cultivo,
      'area': area,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Obtener encuestas de una finca desde Firestore
  Stream<List<Encuesta>> getEncuestasByFinca(String fincaFirebaseId) {
    return _firestore
        .collection('encuestas')
        .where('fincaId', isEqualTo: fincaFirebaseId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Encuesta(
          firebaseId: doc.id,
          fincaId: 0, // ID local, no disponible aquí
          fecha: (data['fecha'] as Timestamp?)?.toDate(),
          loteNumero: data['loteNumero'],
          numeroArboles: data['numeroArboles'],
          arbolesEnfermos: data['arbolesEnfermos'],
          severidad: data['severidad'],
          observaciones: data['observaciones'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }
}