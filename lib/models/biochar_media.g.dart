// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biochar_media.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BiocharMediaAdapter extends TypeAdapter<BiocharMedia> {
  @override
  final int typeId = 24;

  @override
  BiocharMedia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BiocharMedia(
      id: fields[0] as int?,
      firebaseId: fields[1] as String?,
      batchId: fields[2] as int,
      tipo: fields[3] as TipoBiocharMedia,
      rutaLocal: fields[4] as String?,
      urlRemota: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      estadoSinc: fields[7] as EstadoSincronizacion,
    );
  }

  @override
  void write(BinaryWriter writer, BiocharMedia obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.firebaseId)
      ..writeByte(2)
      ..write(obj.batchId)
      ..writeByte(3)
      ..write(obj.tipo)
      ..writeByte(4)
      ..write(obj.rutaLocal)
      ..writeByte(5)
      ..write(obj.urlRemota)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.estadoSinc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BiocharMediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TipoBiocharMediaAdapter extends TypeAdapter<TipoBiocharMedia> {
  @override
  final int typeId = 23;

  @override
  TipoBiocharMedia read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TipoBiocharMedia.biomasa;
      case 1:
        return TipoBiocharMedia.humedad;
      default:
        return TipoBiocharMedia.biomasa;
    }
  }

  @override
  void write(BinaryWriter writer, TipoBiocharMedia obj) {
    switch (obj) {
      case TipoBiocharMedia.biomasa:
        writer.writeByte(0);
        break;
      case TipoBiocharMedia.humedad:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipoBiocharMediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
