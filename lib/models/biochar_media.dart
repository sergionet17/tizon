import 'package:hive/hive.dart';
import 'common.dart';

part 'biochar_media.g.dart';

@HiveType(typeId: 23)
enum TipoBiocharMedia {
  @HiveField(0)
  biomasa,

  @HiveField(1)
  humedad,
}

@HiveType(typeId: 24)
class BiocharMedia {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? firebaseId;

  @HiveField(2)
  int batchId; // id LOCAL del batch

  @HiveField(3)
  TipoBiocharMedia tipo;

  @HiveField(4)
  String? rutaLocal; // path local (móvil) o blob url (web)

  @HiveField(5)
  String? urlRemota; // storage url

  @HiveField(6)
  DateTime? createdAt;

  @HiveField(7)
  EstadoSincronizacion estadoSinc;

  BiocharMedia({
    this.id,
    this.firebaseId,
    required this.batchId,
    required this.tipo,
    this.rutaLocal,
    this.urlRemota,
    DateTime? createdAt,
    this.estadoSinc = EstadoSincronizacion.pendiente,
  }) : createdAt = createdAt ?? DateTime.now();

  BiocharMedia copyWith({
    int? id,
    String? firebaseId,
    int? batchId,
    TipoBiocharMedia? tipo,
    String? rutaLocal,
    String? urlRemota,
    DateTime? createdAt,
    EstadoSincronizacion? estadoSinc,
  }) {
    return BiocharMedia(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      batchId: batchId ?? this.batchId,
      tipo: tipo ?? this.tipo,
      rutaLocal: rutaLocal ?? this.rutaLocal,
      urlRemota: urlRemota ?? this.urlRemota,
      createdAt: createdAt ?? this.createdAt,
      estadoSinc: estadoSinc ?? this.estadoSinc,
    );
  }
}
