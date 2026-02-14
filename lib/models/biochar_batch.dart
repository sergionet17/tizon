import 'package:hive/hive.dart';
import 'common.dart';

part 'biochar_batch.g.dart';

@HiveType(typeId: 21)
enum TipoBiomasa {
  @HiveField(0)
  maderaSocaCafe,

  @HiveField(1)
  pulpaCafe,

  @HiveField(2)
  otro,
}

@HiveType(typeId: 22)
class BiocharBatch {
  // LocalDbService-style: el id se asigna al guardar (no final)
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? firebaseId;

  @HiveField(2)
  int fincaId; // id LOCAL de la finca (Hive)

  @HiveField(3)
  TipoBiomasa tipoBiomasa;

  @HiveField(4)
  int? humedadEntrada; // 0..100

  @HiveField(5)
  int temperaturaQuema; // requerida (°C)

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  @HiveField(8)
  EstadoSincronizacion estadoSinc;

  BiocharBatch({
    this.id,
    this.firebaseId,
    required this.fincaId,
    required this.tipoBiomasa,
    this.humedadEntrada,
    required this.temperaturaQuema,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.estadoSinc = EstadoSincronizacion.pendiente,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  BiocharBatch copyWith({
    int? id,
    String? firebaseId,
    int? fincaId,
    TipoBiomasa? tipoBiomasa,
    int? humedadEntrada,
    int? temperaturaQuema,
    DateTime? createdAt,
    DateTime? updatedAt,
    EstadoSincronizacion? estadoSinc,
  }) {
    return BiocharBatch(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      fincaId: fincaId ?? this.fincaId,
      tipoBiomasa: tipoBiomasa ?? this.tipoBiomasa,
      humedadEntrada: humedadEntrada ?? this.humedadEntrada,
      temperaturaQuema: temperaturaQuema ?? this.temperaturaQuema,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      estadoSinc: estadoSinc ?? this.estadoSinc,
    );
  }
}
