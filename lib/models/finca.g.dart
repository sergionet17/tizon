// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finca.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FincaAdapter extends TypeAdapter<Finca> {
  @override
  final int typeId = 10;

  @override
  Finca read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Finca(
      id: fields[0] as int?,
      nombre: fields[1] as String,
      ubicacion: fields[2] as LatLng,
      firebaseId: fields[3] as String?,
      cultivo: fields[4] as String?,
      area: fields[5] as double?,
      imagePath: fields[6] as String?,
      imageUrl: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      estadoSinc: fields[10] as EstadoSincronizacion,
    );
  }

  @override
  void write(BinaryWriter writer, Finca obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.ubicacion)
      ..writeByte(3)
      ..write(obj.firebaseId)
      ..writeByte(4)
      ..write(obj.cultivo)
      ..writeByte(5)
      ..write(obj.area)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.estadoSinc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FincaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
