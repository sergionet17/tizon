import 'package:hive/hive.dart';
import '../models/common.dart';
import '../models/finca.dart';
import '../models/encuesta.dart';
import '../models/medio.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  static const _fincasBox = 'fincas';
  static const _encuestasBox = 'encuestas';
  static const _mediosBox = 'medios';

  String? _uid;

  /// Llama esto cuando el usuario inicia sesión
  void setUser(String uid) {
    _uid = uid;
  }

  String _boxName(String base) {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return base; // fallback (no recomendado)
    return '${base}_$uid';
  }

  Future<Box<Finca>> _fincas() async =>
      await Hive.openBox<Finca>(_boxName(_fincasBox));
  Future<Box<Encuesta>> _encuestas() async =>
      await Hive.openBox<Encuesta>(_boxName(_encuestasBox));
  Future<Box<Medio>> _medios() async =>
      await Hive.openBox<Medio>(_boxName(_mediosBox));

  /// Opcional pero recomendado al cerrar sesión
  Future<void> closeUserBoxes() async {
    await Hive.box<Finca>(_boxName(_fincasBox)).close().catchError((_) {});
    await Hive.box<Encuesta>(_boxName(_encuestasBox))
        .close()
        .catchError((_) {});
    await Hive.box<Medio>(_boxName(_mediosBox)).close().catchError((_) {});
  }

  // ===== FINCAS =====
  Future<List<Finca>> getFincas() async {
    print("🎬 DB: Llamando a getFincas(). UID actual: $_uid");

    try {
      final boxName = _boxName(_fincasBox);
      print("📦 DB: Abriendo caja: $boxName");

      final b = await _fincas();
      print("📖 DB: Caja abierta. Contiene ${b.length} elementos.");

      final list = b.values.toList();

      // Ordenar
      list.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

      print("✅ DB: Retornando lista de ${list.length} fincas.");
      return list;
    } catch (e) {
      print("❌ DB ERROR en getFincas: $e");
      return [];
    }
  }

  Future<Finca?> getFinca(int id) async {
    final b = await _fincas();
    return b.get(id);
  }

  Future<int> saveFinca(Finca finca) async {
    final b = await _fincas();
    if (finca.id != null) {
      await b.put(finca.id!, finca);
      return finca.id!;
    } else {
      final newKey = await b.add(finca);
      finca.id = newKey;
      await b.put(newKey, finca);
      return newKey;
    }
  }

  Future<void> deleteFinca(int id) async {
    final b = await _fincas();
    await b.delete(id);
  }

  // ===== ENCUESTAS =====
  Future<List<Encuesta>> getEncuestas() async {
    final b = await _encuestas();
    final list = b.values.toList();
    list.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Future<List<Encuesta>> getEncuestasByFinca(int fincaId) async {
    final b = await _encuestas();
    final list = b.values.where((e) => e.fincaId == fincaId).toList();
    list.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Future<Encuesta?> getEncuesta(int id) async {
    final b = await _encuestas();
    return b.get(id);
  }

  Future<int> saveEncuesta(Encuesta encuesta) async {
    final b = await _encuestas();
    if (encuesta.id != null) {
      await b.put(encuesta.id!, encuesta);
      return encuesta.id!;
    } else {
      final newKey = await b.add(encuesta);
      encuesta.id = newKey;
      await b.put(newKey, encuesta);
      return newKey;
    }
  }

  // ===== MEDIOS =====
  Future<List<Medio>> getMediosByEncuesta(int encuestaId) async {
    final b = await _medios();
    return b.values.where((m) => m.encuestaId == encuestaId).toList();
  }

  Future<int> saveMedio(Medio medio) async {
    final b = await _medios();
    if (medio.id != null) {
      await b.put(medio.id!, medio);
      return medio.id!;
    } else {
      final newKey = await b.add(medio);
      medio.id = newKey;
      await b.put(newKey, medio);
      return newKey;
    }
  }

  // ===== SINCRONIZACIÓN =====
  Future<List<Finca>> getFincasPendientesSinc() async {
    final b = await _fincas();
    return b.values
        .where((f) => f.estadoSinc == EstadoSincronizacion.pendiente)
        .toList();
  }

  Future<List<Encuesta>> getEncuestasPendientesSinc() async {
    final b = await _encuestas();
    return b.values
        .where((e) => e.estadoSinc == EstadoSincronizacion.pendiente)
        .toList();
  }

  Future<List<Medio>> getMediosPendientesSinc() async {
    final b = await _medios();
    return b.values
        .where((m) => m.estadoSinc == EstadoSincronizacion.pendiente)
        .toList();
  }

  // En local_db_service.dart
  Future<void> syncFromFirebase(List<Finca> fincasDesdeFirebase) async {
    final b = await _fincas();
    for (var finca in fincasDesdeFirebase) {
      // Guardamos en la caja local lo que viene de la nube
      // Usamos put() para evitar duplicados si ya manejas un ID consistente
      await b.put(finca.id, finca);
    }
  }
}
