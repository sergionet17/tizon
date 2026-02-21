import 'package:tizon_app/app/di.dart';
import 'package:tizon_app/features/fincas/presentation/domain/finca_repository.dart';
import 'package:tizon_app/models/finca.dart';
import 'package:tizon_app/services/local_db_service.dart';

class FincaRepositoryImpl implements FincaRepository {
  final LocalDbService _localDb = getIt<LocalDbService>();

  @override
  Future<List<Finca>> getFincas() async {
    // Aquí centralizamos de dónde salen las fincas (hoy Hive)
    return _localDb.getFincas();
  }

  @override
  Future<Finca?> getFinca(String id) async {
    return _localDb.getFinca(id as int);
  }

  @override
  Future<void> saveFinca(Finca finca) async {
    // Guardamos en la caja local lo que viene de la nube
    // Usamos put() para evitar duplicados si ya manejas un ID consistente
    await _localDb.saveFinca(finca);
    // - setear estadoSinc = pendiente
    // - normalizar datos
    // - reglas de negocio
    await _localDb.saveFinca(finca);
  }

  @override
  Future<void> deleteFinca(String id) async {
    await _localDb.deleteFinca(id as int);
  }
}
