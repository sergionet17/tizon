// lib/services/sync_service.dart
import 'package:flutter/foundation.dart';
import 'package:tizon_app/services/auth_service.dart';

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/common.dart';
import '../models/encuesta.dart';
import '../models/finca.dart';
import '../models/medio.dart';
import 'package:tizon_app/core/sync/fincas_sync_handler.dart';
import 'package:tizon_app/core/sync/encuestas_sync_handler.dart';
import 'package:tizon_app/core/sync/medios_sync_handler.dart';

import 'local_db_service.dart';
import 'local_image_service.dart';

import 'package:tizon_app/app/di.dart'
    hide EncuestasSyncHandler, MediosSyncHandler;

enum SyncType { users, fincas, encuestas, medios, all }

class SyncService {
  SyncService();

  final LocalDbService _localDb = getIt<LocalDbService>();
  final LocalImageService _imageService = getIt<LocalImageService>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final Connectivity _connectivity = Connectivity();

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  Stream<bool> get onSyncChanged => _controller.stream;

  void initialize() {
    // ignore: avoid_print
    print('🔌 [SYNC] Inicializando listener de conectividad...');

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final online = results.any(
          (result) =>
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.wifi,
        );

        if (online) {
          try {
            await getIt<AuthService>().syncOfflineUsers();
          } catch (_) {}
          // ignore: avoid_print
          print('✅ [SYNC] Conexión detectada, iniciando sincronización automática...');
          await syncAll();
        } else {
          // ignore: avoid_print
          print('❌ [SYNC] Sin conexión a internet');
        }
      },
    );
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.close();
  }

  /// Verifica si hay conexión real a internet.
  /// En web no hay acceso a sockets, así que si hay red asumimos conexión.
  Future<bool> hasConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.contains(ConnectivityResult.none)) return false;

      // InternetAddress.lookup no está disponible en web
      if (kIsWeb) return true;

      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void startSync() {
    // ignore: avoid_print
    print('🔄 [SYNC] Iniciando sincronización de usuarios offline...');
    _isSyncing = true;
    _controller.add(true);
  }

  void endSync() {
    // ignore: avoid_print
    print('✅ [SYNC] Sincronización completada.');
    _isSyncing = false;
    _controller.add(false);
  }

  Future<void> syncAll() async {
    if (_isSyncing) {
      // ignore: avoid_print
      print('⚠️ [SYNC] Ya hay una sincronización en curso');
      return;
    }

    final hasConn = await hasConnection();
    if (!hasConn) {
      // ignore: avoid_print
      print('❌ [SYNC] Sin conexión a internet');
      return;
    }

    _isSyncing = true;
    _controller.add(true);
    // ignore: avoid_print
    print('🔄 [SYNC] Iniciando sincronización completa (handlers)...');

    try {
      final handlers = [
        getIt<FincasSyncHandler>(),
        getIt<EncuestasSyncHandler>(),
        getIt<MediosSyncHandler>(),
      ];

      for (final h in handlers) {
        // ignore: avoid_print
        print('➡️ [SYNC] Ejecutando handler: ${h.name}');
        await h.sync();
      }

      // ignore: avoid_print
      print('✅ [SYNC] Sincronización completa exitosa');
    } catch (e) {
      // ignore: avoid_print
      print('❌ [SYNC] Error en sincronización: $e');
    } finally {
      _isSyncing = false;
      _controller.add(false);
    }
  }

  Future<Map<String, int>> getSyncStats() async {
    final fincasPendientes = await _localDb.getFincasPendientesSinc();
    final encuestasPendientes = await _localDb.getEncuestasPendientesSinc();
    final mediosPendientes = await _localDb.getMediosPendientesSinc();

    return {
      'fincas': fincasPendientes.length,
      'encuestas': encuestasPendientes.length,
      'medios': mediosPendientes.length,
      'total': fincasPendientes.length +
          encuestasPendientes.length +
          mediosPendientes.length,
    };
  }
}
