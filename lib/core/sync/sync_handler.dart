abstract class SyncHandler {
  /// Nombre para logs/depuración
  String get name;

  /// Ejecuta sincronización del módulo
  Future<void> sync();
}
