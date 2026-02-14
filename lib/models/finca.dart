import 'package:hive/hive.dart';
import 'common.dart';

part 'finca.g.dart';

@HiveType(typeId: 10)
class Finca {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  LatLng ubicacion;

  @HiveField(3)
  String? firebaseId;

  @HiveField(4)
  String? cultivo;

  @HiveField(5)
  double? area;

  @HiveField(6)
  String? imagePath;

  @HiveField(7)
  String? imageUrl;

  @HiveField(8)
  DateTime? createdAt;

  @HiveField(9)
  DateTime? updatedAt;

  @HiveField(10)
  EstadoSincronizacion estadoSinc;

  Finca({
    this.id,
    required this.nombre,
    required this.ubicacion,
    this.firebaseId,
    this.cultivo,
    this.area,
    this.imagePath,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.estadoSinc = EstadoSincronizacion.pendiente,
  });

  Finca copyWith({
    int? id,
    String? nombre,
    LatLng? ubicacion,
    String? firebaseId,
    String? cultivo,
    double? area,
    String? imagePath,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    EstadoSincronizacion? estadoSinc,
  }) {
    return Finca(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      firebaseId: firebaseId ?? this.firebaseId,
      cultivo: cultivo ?? this.cultivo,
      area: area ?? this.area,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estadoSinc: estadoSinc ?? this.estadoSinc,
    );
  }

  String get ubicacionTexto => '${ubicacion.latitude},${ubicacion.longitude}';
}
