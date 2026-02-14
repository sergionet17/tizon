// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encuesta.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EncuestaAdapter extends TypeAdapter<Encuesta> {
  @override
  final int typeId = 11;

  @override
  Encuesta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Encuesta(
      id: fields[0] as int?,
      firebaseId: fields[1] as String?,
      fincaId: fields[2] as int,
      fecha: fields[3] as DateTime?,
      loteNumero: fields[4] as String?,
      numeroArboles: fields[5] as int?,
      arbolesEnfermos: fields[6] as int?,
      severidad: fields[7] as String?,
      localizacion: fields[8] as LatLng?,
      observaciones: fields[9] as String?,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      estadoSinc: fields[12] as EstadoSincronizacion,
    );
  }

  @override
  void write(BinaryWriter writer, Encuesta obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.firebaseId)
      ..writeByte(2)
      ..write(obj.fincaId)
      ..writeByte(3)
      ..write(obj.fecha)
      ..writeByte(4)
      ..write(obj.loteNumero)
      ..writeByte(5)
      ..write(obj.numeroArboles)
      ..writeByte(6)
      ..write(obj.arbolesEnfermos)
      ..writeByte(7)
      ..write(obj.severidad)
      ..writeByte(8)
      ..write(obj.localizacion)
      ..writeByte(9)
      ..write(obj.observaciones)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.estadoSinc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncuestaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
