import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:tizon_app/app/di.dart';
import 'package:tizon_app/core/sync/sync_handler.dart';
import 'package:tizon_app/models/common.dart';
import 'package:tizon_app/services/local_db_service.dart';
import 'package:tizon_app/services/local_image_service.dart';

class FincasSyncHandler implements SyncHandler {
  @override
  String get name => 'Fincas';

  final LocalDbService _localDb = getIt<LocalDbService>();
  final LocalImageService _imageService = getIt<LocalImageService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<void> sync() async {
    // ignore: avoid_print
    print('📊 [SYNC] Sincronizando fincas...');

    final fincasPendientes = await _localDb.getFincasPendientesSinc();
    // ignore: avoid_print
    print('   → ${fincasPendientes.length} fincas pendientes');

    for (final finca in fincasPendientes) {
      try {
        // ignore: avoid_print
        print('   🔄 Sincronizando finca: ${finca.nombre}');

        final uid = _auth.currentUser?.uid;
        if (uid == null) throw Exception('No hay usuario autenticado');

        String? imageUrl;

        if (finca.imagePath != null &&
            await _imageService.imageExists(finca.imagePath!)) {
          // ignore: avoid_print
          print('   📸 Subiendo imagen...');
          imageUrl = await _uploadFile(
            File(finca.imagePath!),
            'fincas/$uid/${finca.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }

        final fincaData = {
          'nombre': finca.nombre,
          'ubicacion': finca.ubicacion,
          'cultivo': finca.cultivo,
          'area': finca.area,
          'imageUrl': imageUrl,
          'userId': uid,
          'createdAt': Timestamp.fromDate(finca.createdAt ?? DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        late final DocumentReference docRef;

        if (finca.firebaseId != null) {
          docRef = _firestore.collection('fincas').doc(finca.firebaseId);
          await docRef.update(fincaData);
          // ignore: avoid_print
          print('   ✅ Finca actualizada en Firestore');
        } else {
          docRef = await _firestore.collection('fincas').add(fincaData);
          // ignore: avoid_print
          print('   ✅ Finca creada en Firestore con ID: ${docRef.id}');
        }

        final fincaActualizada = finca.copyWith(
          firebaseId: docRef.id,
          imageUrl: imageUrl,
          estadoSinc: EstadoSincronizacion.sincronizada,
          updatedAt: DateTime.now(),
        );

        await _localDb.saveFinca(fincaActualizada);
        // ignore: avoid_print
        print('   ✅ Finca actualizada en Hive');
      } catch (e) {
        // ignore: avoid_print
        print('   ❌ Error sincronizando finca ${finca.nombre}: $e');

        final fincaConError = finca.copyWith(
          estadoSinc: EstadoSincronizacion.error,
        );

        await _localDb.saveFinca(fincaConError);
      }
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return uploadTask.ref.getDownloadURL();
  }
}
