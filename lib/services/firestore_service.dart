import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ===== MÉTODOS EXISTENTES (no tocar) =====
  
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

  // ===== NUEVOS MÉTODOS PARA FINCAS =====

  // Obtener el ID del usuario actual
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // Obtener todas las fincas del usuario
Stream<List<Finca>> getUserFincas() {
  if (userId == null) return Stream.value([]);

  return _db
      .collection('fincas')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final fincas = snapshot.docs
            .map((doc) => Finca.fromFirestore(doc))
            .toList();
        
        fincas.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        
        return fincas;
      });
}

  // Crear una nueva finca
  Future<void> createFinca({
    required String nombre,
    required String ubicacion,
    String? cultivo,
    double? area,
  }) async {
    if (userId == null) throw Exception('Usuario no autenticado');

    await _db.collection('fincas').add({
      'userId': userId,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'cultivo': cultivo,
      'area': area,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar una finca
  Future<void> deleteFinca(String fincaId) async {
    await _db.collection('fincas').doc(fincaId).delete();
  }

  // Actualizar una finca
  Future<void> updateFinca({
    required String fincaId,
    String? nombre,
    String? ubicacion,
    String? cultivo,
    double? area,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (nombre != null) data['nombre'] = nombre;
    if (ubicacion != null) data['ubicacion'] = ubicacion;
    if (cultivo != null) data['cultivo'] = cultivo;
    if (area != null) data['area'] = area;

    await _db.collection('fincas').doc(fincaId).update(data);
  }
}

// ===== MODELO DE FINCA =====

class Finca {
  final String id;
  final String userId;
  final String nombre;
  final String ubicacion;
  final String? cultivo;
  final double? area;
  final DateTime? createdAt;

  Finca({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.ubicacion,
    this.cultivo,
    this.area,
    this.createdAt,
  });

  factory Finca.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Finca(
      id: doc.id,
      userId: data['userId'] ?? '',
      nombre: data['nombre'] ?? '',
      ubicacion: data['ubicacion'] ?? '',
      cultivo: data['cultivo'],
      area: data['area']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'cultivo': cultivo,
      'area': area,
    };
  }
}