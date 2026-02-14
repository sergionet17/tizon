import 'dart:developer' as developer;

/// Logger central de la app
/// Úsalo para trazabilidad de pantallas
void logScreen({
  required String screenName,
  required String fileName,
}) {
  developer.log(
    'Pantalla activa: $screenName',
    name: 'SCREEN',
    error: fileName,
  );
}
