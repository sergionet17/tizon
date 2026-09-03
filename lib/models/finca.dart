import 'package:hive/hive.dart';
import 'common.dart';

part 'finca.g.dart';

@HiveType(typeId: 10)
class Finca {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String nombre;

  /// Legacy: centroide guardado para compatibilidad con datos viejos.
  /// Para fincas nuevas se calcula automáticamente desde [poligono].
  @HiveField(2)
  LatLng? ubicacion;

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

  /// Lista de puntos que definen el polígono de la finca.
  @HiveField(11)
  List<LatLng> poligono;

  Finca({
    this.id,
    required this.nombre,
    this.ubicacion,
    this.firebaseId,
    this.cultivo,
    this.area,
    this.imagePath,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.estadoSinc = EstadoSincronizacion.pendiente,
    List<LatLng>? poligono,
  }) : poligono = poligono ??
            (ubicacion != null ? [ubicacion] : []);

  /// Centro geométrico del polígono. Si no hay polígono usa [ubicacion] legacy.
  LatLng get centroide {
    if (poligono.isNotEmpty) {
      final lat =
          poligono.map((p) => p.latitude).reduce((a, b) => a + b) /
              poligono.length;
      final lng =
          poligono.map((p) => p.longitude).reduce((a, b) => a + b) /
              poligono.length;
      return LatLng(latitude: lat, longitude: lng);
    }
    return ubicacion ?? const LatLng(latitude: 1.853, longitude: -76.050);
  }

  /// Texto para mostrar la ubicación (usa el centroide).
  String get ubicacionTexto {
    final c = centroide;
    return '${c.latitude.toStringAsFixed(6)}, ${c.longitude.toStringAsFixed(6)}';
  }

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
    List<LatLng>? poligono,
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
      poligono: poligono ?? this.poligono,
    );
  }
}
