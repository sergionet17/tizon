// lib/services/sync_service.dart
import 'package:tizon_app/services/auth_service.dart';

// Dart: utilidades de async (Stream, StreamController, StreamSubscription)
import 'dart:async';

// Dart: manejo de archivos locales e InternetAddress.lookup (ping real)
import 'dart:io';

// Plugin: detecta cambios de conectividad (wifi/mobile/none)
import 'package:connectivity_plus/connectivity_plus.dart';

// Firebase: base de datos (Firestore)
import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase: auth (para userId y sesión actual)
import 'package:firebase_auth/firebase_auth.dart';

// Firebase: almacenamiento (subir imágenes/audios)
import 'package:firebase_storage/firebase_storage.dart';

// Modelos locales (Hive) que ya tienes en tu app
import '../models/common.dart';
import '../models/encuesta.dart';
import '../models/finca.dart';
import '../models/medio.dart';
import 'package:tizon_app/core/sync/fincas_sync_handler.dart';
import 'package:tizon_app/core/sync/encuestas_sync_handler.dart';
import 'package:tizon_app/core/sync/medios_sync_handler.dart';

// Servicios locales (Hive + manejo de imágenes locales)
import 'local_db_service.dart';
import 'local_image_service.dart';

// ✅ DI: para usar UNA sola instancia global (evita duplicados)
// Asegúrate de que esto exista (ya lo tienes): lib/app/di.dart
import 'package:tizon_app/app/di.dart'
    hide EncuestasSyncHandler, MediosSyncHandler;

/// Tipos de sincronización (hoy no lo usas mucho, pero está bien tenerlo)
enum SyncType { users, fincas, encuestas, medios, all }

/// SyncService = orquestador de sincronización offline -> online.
/// - Lee pendientes en Hive (LocalDbService)
/// - Sube archivos a Storage (FirebaseStorage)
/// - Crea/actualiza docs en Firestore
/// - Marca el estado en Hive (sincronizada / error)
class SyncService {
  SyncService();

  // ✅ Dependencias (usando DI)
  //
  // Antes: final LocalDbService _localDb = LocalDbService();
  // Eso creaba una instancia nueva y podía duplicar estado/listeners.
  //
  // Ahora: traemos las instancias únicas registradas en get_it.
  final LocalDbService _localDb = getIt<LocalDbService>();
  final LocalImageService _imageService = getIt<LocalImageService>();

  // Firebase singletons (estos ya son singletons internos, está ok)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Plugin de conectividad (escucha wifi/mobile/none)
  final Connectivity _connectivity = Connectivity();

  // Controlador para notificar a la UI si está sincronizando (true/false)
  // broadcast => varios listeners pueden escuchar (banner, icono, etc.)
  final _controller = StreamController<bool>.broadcast();

  // Suscripción al stream de conectividad (para poder cancelarla luego)
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Flag interno: evita correr 2 sync al tiempo
  bool _isSyncing = false;

  // Getter: permite a otros saber si está sincronizando
  bool get isSyncing => _isSyncing;

  // Stream: permite a la UI escuchar cambios de estado (sync/no sync)
  Stream<bool> get onSyncChanged => _controller.stream;

  /// Inicializa el listener de conectividad.
  /// Idea: si vuelve internet, corre sync automático.
  void initialize() {
    // (En producción cambia print por logger, pero por ahora ok)
    // ignore: avoid_print
    print('🔌 [SYNC] Inicializando listener de conectividad...');

    // Nos suscribimos a cambios (wifi/mobile/none)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        // Si detecta wifi o datos, intenta sincronizar
        final online = results.any(
          (result) =>
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.wifi,
        );

        if (online) {
          // Sync usuarios offline primero
          try { await getIt<AuthService>().syncOfflineUsers(); } catch(_) {}
          // ignore: avoid_print
          print(
              '✅ [SYNC] Conexión detectada, iniciando sincronización automática...');
          await syncAll(); // corre sync completo
        } else {
          // ignore: avoid_print
          print('❌ [SYNC] Sin conexión a internet');
        }
      },
    );
  }

  /// Detiene el servicio (muy importante para no filtrar memoria).
  /// Si no lo cancelas, el listener puede quedar vivo aunque cambies pantallas.
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.close();
  }

  /// Verifica si hay conexión REAL a internet.
  /// - connectivity_plus solo te dice "tengo wifi", pero puede ser wifi sin internet.
  /// - Por eso hacemos lookup a 'google.com' con timeout.
  Future<bool> hasConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();

      // Si no hay ninguna red, no hay internet.
      if (results.contains(ConnectivityResult.none)) {
        return false;
      }

      // Verificar conectividad real con DNS lookup (con timeout).
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      // Si resolvió y hay dirección válida, asumimos internet.
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      // Si falla lookup o timeout -> asumimos sin internet
      return false;
    }
  }

  // ===== MÉTODOS PÚBLICOS PARA SINCRONIZACIÓN =====

  /// startSync/endSync: hoy los estás usando desde AuthService para mostrar UI.
  /// No hacen la sync real, solo cambian estado y notifican.
  void startSync() {
    // ignore: avoid_print
    print('🔄 [SYNC] Iniciando sincronización de usuarios offline...');
    _isSyncing = true;
    _controller.add(true); // notifica a la UI
  }

  void endSync() {
    // ignore: avoid_print
    print('✅ [SYNC] Sincronización completada.');
    _isSyncing = false;
    _controller.add(false); // notifica a la UI
  }

  /// Sincroniza todos los datos pendientes (Fincas -> Encuestas -> Medios).
  /// Ese orden es clave porque hay dependencias:
  /// - encuesta depende de finca
  /// - medio depende de encuesta
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
      // ✅ Orden importante por dependencias
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

  /// Sincroniza medios (fotos/audios) pendientes desde Hive a Storage + Firestore.
  /// Dependen de que la encuesta tenga firebaseId.

  // ===== MÉTODOS AUXILIARES =====

  /// Devuelve conteos para UI (badge, indicador, etc.)
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
