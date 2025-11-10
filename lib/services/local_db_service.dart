// lib/services/local_db_service.dart
import 'package:hive/hive.dart';
import '../models/common.dart';
import '../models/finca.dart';
import '../models/encuesta.dart';
import '../models/medio.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  // Nombres de boxes
  static const _fincasBox = 'fincas';
  static const _encuestasBox = 'encuestas';
  static const _mediosBox = 'medios';

  Future<Box<Finca>> _fincas() async =>
      await Hive.openBox<Finca>(_fincasBox);

  Future<Box<Encuesta>> _encuestas() async =>
      await Hive.openBox<Encuesta>(_encuestasBox);

  Future<Box<Medio>> _medios() async =>
      await Hive.openBox<Medio>(_mediosBox);

  // ===== FINCAS =====
  Future<List<Finca>> getFincas() async {
    final b = await _fincas();
    final list = b.values.toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Future<Finca?> getFinca(Id id) async {
    final b = await _fincas();
    return b.get(id);
  }

  Future<Id> saveFinca(Finca finca) async {
    final b = await _fincas();
    if (finca.id != null) {
      await b.put(finca.id, finca);
      return finca.id!;
    } else {
      final newKey = await b.add(finca);
      finca.id = newKey;
      await b.put(newKey, finca); // persistimos id dentro del objeto
      return newKey;
    }
  }

  Future<void> deleteFinca(Id id) async {
    final b = await _fincas();
    await b.delete(id);
  }

  // ===== ENCUESTAS =====
  Future<List<Encuesta>> getEncuestas() async {
    final b = await _encuestas();
    final list = b.values.toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Future<List<Encuesta>> getEncuestasByFinca(String fincaId) async {
    final b = await _encuestas();
    final list = b.values.where((e) => e.fincaId == fincaId).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }

  Future<Encuesta?> getEncuesta(Id id) async {
    final b = await _encuestas();
    return b.get(id);
  }

  Future<Id> saveEncuesta(Encuesta encuesta) async {
    final b = await _encuestas();
    if (encuesta.id != null) {
      await b.put(encuesta.id, encuesta);
      return encuesta.id!;
    } else {
      final newKey = await b.add(encuesta);
      encuesta.id = newKey;
      await b.put(newKey, encuesta);
      return newKey;
    }
  }

  // ===== MEDIOS =====
  Future<List<Medio>> getMediosByEncuesta(String encuestaId) async {
    final b = await _medios();
    return b.values.where((m) => m.encuestaId == encuestaId).toList();
  }

  Future<Id> saveMedio(Medio medio) async {
    final b = await _medios();
    if (medio.id != null) {
      await b.put(medio.id, medio);
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
}
