import 'package:hive/hive.dart';
import 'common.dart';

part 'encuesta.g.dart';

@HiveType(typeId: 11)
class Encuesta {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? firebaseId;

  @HiveField(2)
  int fincaId;

  @HiveField(3)
  DateTime? fecha;

  @HiveField(4)
  String? loteNumero;

  @HiveField(5)
  int? numeroArboles;

  @HiveField(6)
  int? arbolesEnfermos;

  @HiveField(7)
  String? severidad;

  @HiveField(8)
  LatLng? localizacion;

  @HiveField(9)
  String? observaciones;

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  DateTime? updatedAt;

  @HiveField(12)
  EstadoSincronizacion estadoSinc;

  Encuesta({
    this.id,
    this.firebaseId,
    required this.fincaId,
    this.fecha,
    this.loteNumero,
    this.numeroArboles,
    this.arbolesEnfermos,
    this.severidad,
    this.localizacion,
    this.observaciones,
    this.createdAt,
    this.updatedAt,
    this.estadoSinc = EstadoSincronizacion.pendiente,
  });

  Encuesta copyWith({
    int? id,
    String? firebaseId,
    int? fincaId,
    DateTime? fecha,
    String? loteNumero,
    int? numeroArboles,
    int? arbolesEnfermos,
    String? severidad,
    LatLng? localizacion,
    String? observaciones,
    DateTime? createdAt,
    DateTime? updatedAt,
    EstadoSincronizacion? estadoSinc,
  }) {
    return Encuesta(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      fincaId: fincaId ?? this.fincaId,
      fecha: fecha ?? this.fecha,
      loteNumero: loteNumero ?? this.loteNumero,
      numeroArboles: numeroArboles ?? this.numeroArboles,
      arbolesEnfermos: arbolesEnfermos ?? this.arbolesEnfermos,
      severidad: severidad ?? this.severidad,
      localizacion: localizacion ?? this.localizacion,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estadoSinc: estadoSinc ?? this.estadoSinc,
    );
  }
}
