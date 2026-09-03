// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/finca.dart';
import '../models/common.dart';
import '../models/encuesta.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Helpers de deserialización ────────────────────────────────────────────

  /// Convierte el array de Firestore [{lat, lng}, ...] a List<LatLng>.
  List<LatLng> _parsePoligono(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((p) {
        return LatLng(
          latitude: (p['lat'] as num?)?.toDouble() ?? 0.0,
          longitude: (p['lng'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    }
    return [];
  }

  /// Lee el centroide legacy {latitude, longitude} guardado antes del polígono.
  LatLng? _parseUbicacionLegacy(dynamic raw) {
    if (raw is Map) {
      final lat = (raw['latitude'] as num?)?.toDouble();
      final lng = (raw['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return LatLng(latitude: lat, longitude: lng);
      }
    }
    return null;
  }

  // ── Fincas ────────────────────────────────────────────────────────────────

  /// Stream de fincas del usuario autenticado desde Firestore.
  Stream<List<Finca>> getUserFincas() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

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
          poligono: _parsePoligono(data['poligono']),
          ubicacion: _parseUbicacionLegacy(data['ubicacion']),
          cultivo: data['cultivo'],
          area: (data['area'] as num?)?.toDouble(),
          imageUrl: data['imageUrl'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  /// Crea una finca en Firestore con su polígono completo.
  /// (Ya no se llama directamente — el SyncService es el que sincroniza,
  ///  pero se mantiene por compatibilidad.)
  Future<void> createFinca({
    required String nombre,
    required List<LatLng> poligono,
    String? cultivo,
    double? area,
    String? imageUrl,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final centroide = poligono.isNotEmpty
        ? LatLng(
            latitude: poligono.map((p) => p.latitude).reduce((a, b) => a + b) /
                poligono.length,
            longitude:
                poligono.map((p) => p.longitude).reduce((a, b) => a + b) /
                    poligono.length,
          )
        : null;

    await _firestore.collection('fincas').add({
      'nombre': nombre,
      if (centroide != null)
        'ubicacion': {
          'latitude': centroide.latitude,
          'longitude': centroide.longitude,
        },
      'poligono': poligono
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'cultivo': cultivo,
      'area': area,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Encuestas ─────────────────────────────────────────────────────────────

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
          fincaId: 0,
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
