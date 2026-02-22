import 'package:tizon_app/models/finca.dart';

abstract class FincaRepository {
  /// Devuelve todas las fincas locales (Hive por ahora)
  Future<List<Finca>> getFincas();

  /// Devuelve una finca por id local
  Future<Finca?> getFinca(int id);

  /// Guarda (crea/actualiza) una finca en local y la deja lista para sync
  Future<void> saveFinca(Finca finca);

  /// Elimina una finca por id local
  Future<void> deleteFinca(int id);
}
