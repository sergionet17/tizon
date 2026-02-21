import 'package:tizon_app/app/di.dart';
import 'package:tizon_app/features/fincas/presentation/domain/finca_repository.dart';
import 'package:tizon_app/models/finca.dart';

class FincasController {
  final FincaRepository _repo = getIt<FincaRepository>();

  /// Obtener todas las fincas
  Future<List<Finca>> loadFincas() async {
    return _repo.getFincas();
  }

  /// Guardar finca nueva o editada
  Future<void> saveFinca(Finca finca) async {
    await _repo.saveFinca(finca);
  }

  /// Eliminar finca
  Future<void> deleteFinca(String id) async {
    await _repo.deleteFinca(id);
  }
}
