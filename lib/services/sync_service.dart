// lib/services/sync_service.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/finca.dart';
import '../models/encuesta.dart';
import '../models/medio.dart';
import '../models/common.dart';
import 'local_db_service.dart';
import 'local_image_service.dart';

enum SyncType { users, fincas, encuestas, medios, all }

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalDbService _localDb = LocalDbService();
  final LocalImageService _imageService = LocalImageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Connectivity _connectivity = Connectivity();

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;
  Stream<bool> get onSyncChanged => _controller.stream;

  /// Inicializa el listener de conectividad
  void initialize() {
    print('🔌 [SYNC] Inicializando listener de conectividad...');
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        if (results.any((result) => 
            result == ConnectivityResult.mobile || 
            result == ConnectivityResult.wifi)) {
          print('✅ [SYNC] Conexión detectada, iniciando sincronización automática...');
          await syncAll();
        } else {
          print('❌ [SYNC] Sin conexión a internet');
        }
      },
    );
  }

  /// Detiene el servicio
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.close();
  }

  /// Verifica si hay conexión a internet
  Future<bool> hasConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Verificar conectividad real
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ===== MÉTODOS PÚBLICOS PARA SINCRONIZACIÓN =====

  /// Inicia sincronización manual de usuarios (compatibilidad con código existente)
  void startSync() {
    print('🔄 [SYNC] Iniciando sincronización de usuarios offline...');
    _isSyncing = true;
    _controller.add(true);
  }

  /// Finaliza sincronización de usuarios
  void endSync() {
    print('✅ [SYNC] Sincronización completada.');
    _isSyncing = false;
    _controller.add(false);
  }

  /// Sincroniza todos los datos pendientes
  Future<void> syncAll() async {
    if (_isSyncing) {
      print('⚠️ [SYNC] Ya hay una sincronización en curso');
      return;
    }
    
    final hasConn = await hasConnection();
    if (!hasConn) {
      print('❌ [SYNC] Sin conexión a internet');
      return;
    }

    _isSyncing = true;
    _controller.add(true);
    print('🔄 [SYNC] Iniciando sincronización completa...');

    try {
      // 1. Sincronizar fincas primero
      await syncFincas();
      
      // 2. Luego encuestas (dependen de fincas)
      await syncEncuestas();
      
      // 3. Finalmente medios (dependen de encuestas)
      await syncMedios();

      print('✅ [SYNC] Sincronización completa exitosa');
    } catch (e) {
      print('❌ [SYNC] Error en sincronización: $e');
    } finally {
      _isSyncing = false;
      _controller.add(false);
    }
  }

  /// Sincroniza solo las fincas
  Future<void> syncFincas() async {
    print('📊 [SYNC] Sincronizando fincas...');
    final fincasPendientes = await _localDb.getFincasPendientesSinc();
    print('   → ${fincasPendientes.length} fincas pendientes');
    
    for (final finca in fincasPendientes) {
      try {
        print('   🔄 Sincronizando finca: ${finca.nombre}');
        
        String? imageUrl;
        
        // Subir imagen si existe
        if (finca.imagePath != null && await _imageService.imageExists(finca.imagePath!)) {
          print('   📸 Subiendo imagen...');
          imageUrl = await _uploadFile(
            File(finca.imagePath!),
            'fincas/${_auth.currentUser!.uid}/${finca.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }

        // Preparar datos
        final fincaData = {
          'nombre': finca.nombre,
          'ubicacion': finca.ubicacion,
          'cultivo': finca.cultivo,
          'area': finca.area,
          'imageUrl': imageUrl,
          'userId': _auth.currentUser!.uid,
          'createdAt': Timestamp.fromDate(finca.createdAt ?? DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        DocumentReference docRef;
        
        // Actualizar o crear en Firestore
        if (finca.firebaseId != null) {
          docRef = _firestore.collection('fincas').doc(finca.firebaseId);
          await docRef.update(fincaData);
          print('   ✅ Finca actualizada en Firestore');
        } else {
          docRef = await _firestore.collection('fincas').add(fincaData);
          print('   ✅ Finca creada en Firestore con ID: ${docRef.id}');
        }

        // Actualizar en Hive
        final fincaActualizada = finca.copyWith(
          firebaseId: docRef.id,
          imageUrl: imageUrl,
          estadoSinc: EstadoSincronizacion.sincronizada,
          updatedAt: DateTime.now(),
        );
        
        await _localDb.saveFinca(fincaActualizada);
        print('   ✅ Finca actualizada en Hive');
        
      } catch (e) {
        print('   ❌ Error sincronizando finca ${finca.nombre}: $e');
        final fincaConError = finca.copyWith(
          estadoSinc: EstadoSincronizacion.error,
        );
        await _localDb.saveFinca(fincaConError);
      }
    }
  }

  /// Sincroniza solo las encuestas
  Future<void> syncEncuestas() async {
    print('📋 [SYNC] Sincronizando encuestas...');
    final encuestasPendientes = await _localDb.getEncuestasPendientesSinc();
    print('   → ${encuestasPendientes.length} encuestas pendientes');
    
    for (final encuesta in encuestasPendientes) {
      try {
        print('   🔄 Sincronizando encuesta del lote ${encuesta.loteNumero}');
        
        // Verificar que la finca esté sincronizada usando el ID local
        final finca = await _localDb.getFinca(encuesta.fincaId);
        if (finca?.firebaseId == null) {
          print('   ⚠️ Finca ${encuesta.fincaId} no sincronizada, omitiendo encuesta');
          continue;
        }

        final encuestaData = {
          'fincaId': finca!.firebaseId,
          'fecha': Timestamp.fromDate(encuesta.fecha ?? DateTime.now()),
          'loteNumero': encuesta.loteNumero,
          'numeroArboles': encuesta.numeroArboles,
          'arbolesEnfermos': encuesta.arbolesEnfermos,
          'severidad': encuesta.severidad,
          'localizacion': encuesta.localizacion != null ? {
            'latitude': encuesta.localizacion!.latitude,
            'longitude': encuesta.localizacion!.longitude,
          } : null,
          'observaciones': encuesta.observaciones,
          'userId': _auth.currentUser!.uid,
          'createdAt': Timestamp.fromDate(encuesta.createdAt ?? DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        DocumentReference docRef;
        
        if (encuesta.firebaseId != null) {
          docRef = _firestore.collection('encuestas').doc(encuesta.firebaseId);
          await docRef.update(encuestaData);
          print('   ✅ Encuesta actualizada en Firestore');
        } else {
          docRef = await _firestore.collection('encuestas').add(encuestaData);
          print('   ✅ Encuesta creada en Firestore con ID: ${docRef.id}');
        }

        final encuestaActualizada = encuesta.copyWith(
          firebaseId: docRef.id,
          estadoSinc: EstadoSincronizacion.sincronizada,
          updatedAt: DateTime.now(),
        );
        
        await _localDb.saveEncuesta(encuestaActualizada);
        print('   ✅ Encuesta actualizada en Hive');
        
      } catch (e) {
        print('   ❌ Error sincronizando encuesta: $e');
        final encuestaConError = encuesta.copyWith(
          estadoSinc: EstadoSincronizacion.error,
        );
        await _localDb.saveEncuesta(encuestaConError);
      }
    }
  }

  /// Sincroniza solo los medios (fotos/audios)
  Future<void> syncMedios() async {
    print('📷 [SYNC] Sincronizando medios...');
    final mediosPendientes = await _localDb.getMediosPendientesSinc();
    print('   → ${mediosPendientes.length} medios pendientes');
    
    for (final medio in mediosPendientes) {
      try {
        print('   🔄 Sincronizando medio tipo: ${medio.tipo}');
        
        // Verificar que la encuesta esté sincronizada usando el ID local
        final encuesta = await _localDb.getEncuesta(medio.encuestaId);
        if (encuesta?.firebaseId == null) {
          print('   ⚠️ Encuesta ${medio.encuestaId} no sincronizada, omitiendo medio');
          continue;
        }

        String? mediaUrl;
        
        // Subir archivo multimedia
        if (medio.rutaLocal != null && await File(medio.rutaLocal!).exists()) {
          final folder = medio.tipo == TipoMedio.foto ? 'fotos' : 'audios';
          final extension = medio.tipo == TipoMedio.foto ? 'jpg' : 'mp3';
          print('   📤 Subiendo archivo...');
          mediaUrl = await _uploadFile(
            File(medio.rutaLocal!),
            '$folder/${_auth.currentUser!.uid}/${medio.id}_${DateTime.now().millisecondsSinceEpoch}.$extension',
          );
        }

        final medioData = {
          'encuestaId': encuesta!.firebaseId,
          'tipo': medio.tipo.toString().split('.').last,
          'rutaRemota': mediaUrl,
          'descripcion': medio.descripcion,
          'userId': _auth.currentUser!.uid,
          'createdAt': Timestamp.fromDate(medio.createdAt ?? DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        DocumentReference docRef;
        
        if (medio.firebaseId != null) {
          docRef = _firestore.collection('medios').doc(medio.firebaseId);
          await docRef.update(medioData);
          print('   ✅ Medio actualizado en Firestore');
        } else {
          docRef = await _firestore.collection('medios').add(medioData);
          print('   ✅ Medio creado en Firestore con ID: ${docRef.id}');
        }

        final medioActualizado = medio.copyWith(
          firebaseId: docRef.id,
          urlRemota: mediaUrl,
          estadoSinc: EstadoSincronizacion.sincronizada,
          updatedAt: DateTime.now(),
        );
        
        await _localDb.saveMedio(medioActualizado);
        print('   ✅ Medio actualizado en Hive');
        
      } catch (e) {
        print('   ❌ Error sincronizando medio: $e');
        final medioConError = medio.copyWith(
          estadoSinc: EstadoSincronizacion.error,
        );
        await _localDb.saveMedio(medioConError);
      }
    }
  }

  // ===== MÉTODOS AUXILIARES =====

  /// Sube un archivo a Firebase Storage
  Future<String> _uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error subiendo archivo: $e');
    }
  }

  /// Obtiene estadísticas de sincronización
  Future<Map<String, int>> getSyncStats() async {
    final fincasPendientes = await _localDb.getFincasPendientesSinc();
    final encuestasPendientes = await _localDb.getEncuestasPendientesSinc();
    final mediosPendientes = await _localDb.getMediosPendientesSinc();

    return {
      'fincas': fincasPendientes.length,
      'encuestas': encuestasPendientes.length,
      'medios': mediosPendientes.length,
      'total': fincasPendientes.length + encuestasPendientes.length + mediosPendientes.length,
    };
  }
}