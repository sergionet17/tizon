// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medio.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedioAdapter extends TypeAdapter<Medio> {
  @override
  final int typeId = 12;

  @override
  Medio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medio(
      id: fields[0] as int?,
      firebaseId: fields[1] as String?,
      encuestaId: fields[2] as int,
      rutaLocal: fields[3] as String?,
      urlRemota: fields[4] as String?,
      descripcion: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      tipo: fields[8] as TipoMedio,
      estadoSinc: fields[9] as EstadoSincronizacion,
    );
  }

  @override
  void write(BinaryWriter writer, Medio obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.firebaseId)
      ..writeByte(2)
      ..write(obj.encuestaId)
      ..writeByte(3)
      ..write(obj.rutaLocal)
      ..writeByte(4)
      ..write(obj.urlRemota)
      ..writeByte(5)
      ..write(obj.descripcion)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.tipo)
      ..writeByte(9)
      ..write(obj.estadoSinc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
