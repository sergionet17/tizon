import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:tizon_app/app/di.dart';
import 'package:tizon_app/core/sync/sync_handler.dart';
import 'package:tizon_app/models/common.dart';
import 'package:tizon_app/models/medio.dart';
import 'package:tizon_app/services/local_db_service.dart';

class MediosSyncHandler implements SyncHandler {
  @override
  String get name => 'Medios';

  // ✅ Dependencias únicas por DI
  final LocalDbService _localDb = getIt<LocalDbService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<void> sync() async {
    // ignore: avoid_print
    print('📷 [SYNC] Sincronizando medios...');

    // 1) Trae pendientes desde local (Hive)
    final mediosPendientes = await _localDb.getMediosPendientesSinc();
    // ignore: avoid_print
    print('   → ${mediosPendientes.length} medios pendientes');

    for (final medio in mediosPendientes) {
      try {
        // ignore: avoid_print
        print('   🔄 Sincronizando medio tipo: ${medio.tipo}');

        // 2) Necesitamos usuario logueado (para rutas y userId)
        final uid = _auth.currentUser?.uid;
        if (uid == null) throw Exception('No hay usuario autenticado');

        // 3) Verifica que la encuesta exista y esté sincronizada (firebaseId)
        final encuesta = await _localDb.getEncuesta(medio.encuestaId);
        if (encuesta?.firebaseId == null) {
          // ignore: avoid_print
          print(
              '   ⚠️ Encuesta ${medio.encuestaId} no sincronizada, omitiendo medio');
          continue;
        }

        String? mediaUrl;

        // 4) Si hay archivo local, lo subimos a Storage
        if (medio.rutaLocal != null && await File(medio.rutaLocal!).exists()) {
          // Carpeta en Storage depende del tipo
          final folder = medio.tipo == TipoMedio.foto ? 'fotos' : 'audios';

          // Extensión: foto = jpg, audio = mp3 (según tu lógica actual)
          final extension = medio.tipo == TipoMedio.foto ? 'jpg' : 'mp3';

          // ignore: avoid_print
          print('   📤 Subiendo archivo...');

          mediaUrl = await _uploadFile(
            File(medio.rutaLocal!),
            '$folder/$uid/${medio.id}_${DateTime.now().millisecondsSinceEpoch}.$extension',
          );
        }

        // 5) Mapa para Firestore
        final medioData = {
          'encuestaId': encuesta!.firebaseId,
          'tipo': medio.tipo.toString().split('.').last,
          'rutaRemota': mediaUrl,
          'descripcion': medio.descripcion,
          'userId': uid,
          'createdAt': Timestamp.fromDate(medio.createdAt ?? DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        // 6) Update si ya existe, si no add
        late final DocumentReference docRef;

        if (medio.firebaseId != null) {
          docRef = _firestore.collection('medios').doc(medio.firebaseId);
          await docRef.update(medioData);
          // ignore: avoid_print
          print('   ✅ Medio actualizado en Firestore');
        } else {
          docRef = await _firestore.collection('medios').add(medioData);
          // ignore: avoid_print
          print('   ✅ Medio creado en Firestore con ID: ${docRef.id}');
        }

        // 7) Marca sincronizada en Hive y guarda URL remota
        final medioActualizado = medio.copyWith(
          firebaseId: docRef.id,
          urlRemota: mediaUrl,
          estadoSinc: EstadoSincronizacion.sincronizada,
          updatedAt: DateTime.now(),
        );

        await _localDb.saveMedio(medioActualizado);
        // ignore: avoid_print
        print('   ✅ Medio actualizado en Hive');
      } catch (e) {
        // 8) Si falla, marca error en Hive (no pierdes el registro)
        // ignore: avoid_print
        print('   ❌ Error sincronizando medio: $e');

        final medioConError = medio.copyWith(
          estadoSinc: EstadoSincronizacion.error,
        );

        await _localDb.saveMedio(medioConError);
      }
    }
  }

  /// Sube a Firebase Storage y retorna URL pública
  Future<String> _uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}
