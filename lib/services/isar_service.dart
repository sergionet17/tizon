import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/finca.dart';
import '../models/encuesta.dart';
import '../models/medio.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();
  
  Isar? _isar;
  
  Future<Isar> get isar async {
    if (_isar != null) return _isar!;
    _isar = await _initIsar();
    return _isar!;
  }
  
  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [FincaSchema, EncuestaSchema, MedioSchema],
      directory: dir.path,
    );
  }
  
  // ===== FINCAS =====
  
  Future<List<Finca>> getFincas() async {
    final db = await isar;
    return await db.fincas.where().findAll();
  }
  
  Future<Finca?> getFinca(Id id) async {
    final db = await isar;
    return await db.fincas.get(id);
  }
  
  Future<Id> saveFinca(Finca finca) async {
    final db = await isar;
    return await db.writeTxn(() async {
      return await db.fincas.put(finca);
    });
  }
  
  Future<void> deleteFinca(Id id) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.fincas.delete(id);
    });
  }
  
  // ===== ENCUESTAS =====
  
  Future<List<Encuesta>> getEncuestas() async {
    final db = await isar;
    return await db.encuestas.where().sortByCreatedAtDesc().findAll();
  }
  
  Future<List<Encuesta>> getEncuestasByFinca(String fincaId) async {
    final db = await isar;
    return await db.encuestas
        .filter()
        .fincaIdEqualTo(fincaId)
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  Future<Encuesta?> getEncuesta(Id id) async {
    final db = await isar;
    return await db.encuestas.get(id);
  }
  
  Future<Id> saveEncuesta(Encuesta encuesta) async {
    final db = await isar;
    return await db.writeTxn(() async {
      return await db.encuestas.put(encuesta);
    });
  }
  
  // ===== MEDIOS =====
  
  Future<List<Medio>> getMediosByEncuesta(String encuestaId) async {
    final db = await isar;
    return await db.medios
        .filter()
        .encuestaIdEqualTo(encuestaId)
        .findAll();
  }
  
  Future<Id> saveMedio(Medio medio) async {
    final db = await isar;
    return await db.writeTxn(() async {
      return await db.medios.put(medio);
    });
  }
  
  // ===== SINCRONIZACIÓN =====
  
  Future<List<Finca>> getFincasPendientesSinc() async {
    final db = await isar;
    return await db.fincas
        .filter()
        .estadoSincEqualTo(EstadoSincronizacion.pendiente)
        .findAll();
  }
  
  Future<List<Encuesta>> getEncuestasPendientesSinc() async {
    final db = await isar;
    return await db.encuestas
        .filter()
        .estadoSincEqualTo(EstadoSincronizacion.pendiente)
        .findAll();
  }
  
  Future<List<Medio>> getMediosPendientesSinc() async {
    final db = await isar;
    return await db.medios
        .filter()
        .estadoSincEqualTo(EstadoSincronizacion.pendiente)
        .findAll();
  }
}