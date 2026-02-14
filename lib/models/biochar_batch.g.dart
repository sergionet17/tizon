// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biochar_batch.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BiocharBatchAdapter extends TypeAdapter<BiocharBatch> {
  @override
  final int typeId = 22;

  @override
  BiocharBatch read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BiocharBatch(
      id: fields[0] as int?,
      firebaseId: fields[1] as String?,
      fincaId: fields[2] as int,
      tipoBiomasa: fields[3] as TipoBiomasa,
      humedadEntrada: fields[4] as int?,
      temperaturaQuema: fields[5] as int,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      estadoSinc: fields[8] as EstadoSincronizacion,
    );
  }

  @override
  void write(BinaryWriter writer, BiocharBatch obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.firebaseId)
      ..writeByte(2)
      ..write(obj.fincaId)
      ..writeByte(3)
      ..write(obj.tipoBiomasa)
      ..writeByte(4)
      ..write(obj.humedadEntrada)
      ..writeByte(5)
      ..write(obj.temperaturaQuema)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.estadoSinc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BiocharBatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TipoBiomasaAdapter extends TypeAdapter<TipoBiomasa> {
  @override
  final int typeId = 21;

  @override
  TipoBiomasa read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TipoBiomasa.maderaSocaCafe;
      case 1:
        return TipoBiomasa.pulpaCafe;
      case 2:
        return TipoBiomasa.otro;
      default:
        return TipoBiomasa.maderaSocaCafe;
    }
  }

  @override
  void write(BinaryWriter writer, TipoBiomasa obj) {
    switch (obj) {
      case TipoBiomasa.maderaSocaCafe:
        writer.writeByte(0);
        break;
      case TipoBiomasa.pulpaCafe:
        writer.writeByte(1);
        break;
      case TipoBiomasa.otro:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipoBiomasaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
