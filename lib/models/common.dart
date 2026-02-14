import 'package:hive/hive.dart';

part 'common.g.dart';

@HiveType(typeId: 0)
enum EstadoSincronizacion {
  @HiveField(0)
  pendiente,

  @HiveField(1)
  sincronizada,

  @HiveField(2)
  error,
}

@HiveType(typeId: 2)
enum TipoMedio {
  @HiveField(0)
  foto,

  @HiveField(1)
  audio,

  @HiveField(2)
  documento,
}

@HiveType(typeId: 3)
class LatLng {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  const LatLng({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => '$latitude,$longitude';
}
