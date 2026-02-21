import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tizon_app/app/di.dart';
import 'package:tizon_app/core/sync/sync_handler.dart';
import 'package:tizon_app/models/common.dart';
import 'package:tizon_app/services/local_db_service.dart';

class EncuestasSyncHandler implements SyncHandler {
  @override
  String get name => 'Encuestas';

  // ✅ Dependencias por DI (una sola instancia)
  final LocalDbService _localDb = getIt<LocalDbService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<void> sync() async {
    // ignore: avoid_print
    print('📋 [SYNC] Sincronizando encuestas...');

    // 1) Trae encuestas pendientes desde Hive (local)
    final encuestasPendientes = await _localDb.getEncuestasPendientesSinc();
    // ignore: avoid_print
    print('   → ${encuestasPendientes.length} encuestas pendientes');

    // 2) Recorre una por una y sube/actualiza en Firestore
    for (final encuesta in encuestasPendientes) {
      try {
        // ignore: avoid_print
        print('   🔄 Sincronizando encuesta del lote ${encuesta.loteNumero}');

        // ✅ Necesitamos usuario logueado para userId
        final uid = _auth.currentUser?.uid;
        if (uid == null) throw Exception('No hay usuario autenticado');

        // 3) Busca la finca local (por id local) para obtener firebaseId
        final finca = await _localDb.getFinca(encuesta.fincaId);

        // Si finca no tiene firebaseId, aún no existe en Firestore -> se omite
        if (finca?.firebaseId == null) {
          // ignore: avoid_print
          print(
              '   ⚠️ Finca ${encuesta.fincaId} no sincronizada, omitiendo encuesta');
          continue;
        }

        // 4) Construye el mapa para Firestore
        final encuestaData = {
          'fincaId': finca!.firebaseId, // referencia a finca en Firestore
          'fecha': Timestamp.fromDate(encuesta.fecha ?? DateTime.now()),
          'loteNumero': encuesta.loteNumero,
          'numeroArboles': encuesta.numeroArboles,
          'arbolesEnfermos': encuesta.arbolesEnfermos,
          'severidad': encuesta.severidad,

          // Si hay ubicación, se envía como mapa simple lat/lng
          'localizacion': encuesta.localizacion != null
              ? {
                  'latitude': encuesta.localizacion!.latitude,
                  'longitude': encuesta.localizacion!.longitude,
                }
              : null,

          'observaciones': encuesta.observaciones,
          'userId': uid,
          'createdAt': Timestamp.fromDate(encuesta.createdAt ?? DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        // 5) Update si ya tiene firebaseId, si no -> add
        late final DocumentReference docRef;

        if (encuesta.firebaseId != null) {
          docRef = _firestore.collection('encuestas').doc(encuesta.firebaseId);
          await docRef.update(encuestaData);
          // ignore: avoid_print
          print('   ✅ Encuesta actualizada en Firestore');
        } else {
          docRef = await _firestore.collection('encuestas').add(encuestaData);
          // ignore: avoid_print
          print('   ✅ Encuesta creada en Firestore con ID: ${docRef.id}');
        }

        // 6) Marca en Hive como sincronizada
        final encuestaActualizada = encuesta.copyWith(
          firebaseId: docRef.id,
          estadoSinc: EstadoSincronizacion.sincronizada,
          updatedAt: DateTime.now(),
        );

        await _localDb.saveEncuesta(encuestaActualizada);
        // ignore: avoid_print
        print('   ✅ Encuesta actualizada en Hive');
      } catch (e) {
        // 7) Si falla, marca error en Hive (no se pierde)
        // ignore: avoid_print
        print('   ❌ Error sincronizando encuesta: $e');

        final encuestaConError = encuesta.copyWith(
          estadoSinc: EstadoSincronizacion.error,
        );

        await _localDb.saveEncuesta(encuestaConError);
      }
    }
  }
}
