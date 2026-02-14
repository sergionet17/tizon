import 'package:hive/hive.dart';
import 'common.dart';

part 'medio.g.dart';

@HiveType(typeId: 12)
class Medio {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? firebaseId;

  @HiveField(2)
  int encuestaId;

  @HiveField(3)
  String? rutaLocal;

  // nombre real del modelo
  @HiveField(4)
  String? urlRemota;

  @HiveField(5)
  String? descripcion;

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  @HiveField(8)
  TipoMedio tipo;

  @HiveField(9)
  EstadoSincronizacion estadoSinc;

  Medio({
    this.id,
    this.firebaseId,
    required this.encuestaId,
    this.rutaLocal,
    this.urlRemota,
    this.descripcion,
    this.createdAt,
    this.updatedAt,
    required this.tipo,
    this.estadoSinc = EstadoSincronizacion.pendiente,
  });

  Medio copyWith({
    int? id,
    String? firebaseId,
    int? encuestaId,
    String? rutaLocal,
    String? urlRemota,
    String? descripcion,
    DateTime? createdAt,
    DateTime? updatedAt,
    TipoMedio? tipo,
    EstadoSincronizacion? estadoSinc,
  }) {
    return Medio(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      encuestaId: encuestaId ?? this.encuestaId,
      rutaLocal: rutaLocal ?? this.rutaLocal,
      urlRemota: urlRemota ?? this.urlRemota,
      descripcion: descripcion ?? this.descripcion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tipo: tipo ?? this.tipo,
      estadoSinc: estadoSinc ?? this.estadoSinc,
    );
  }
}
