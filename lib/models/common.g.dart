// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LatLngAdapter extends TypeAdapter<LatLng> {
  @override
  final int typeId = 3;

  @override
  LatLng read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LatLng(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLngAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EstadoSincronizacionAdapter extends TypeAdapter<EstadoSincronizacion> {
  @override
  final int typeId = 0;

  @override
  EstadoSincronizacion read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EstadoSincronizacion.pendiente;
      case 1:
        return EstadoSincronizacion.sincronizada;
      case 2:
        return EstadoSincronizacion.error;
      default:
        return EstadoSincronizacion.pendiente;
    }
  }

  @override
  void write(BinaryWriter writer, EstadoSincronizacion obj) {
    switch (obj) {
      case EstadoSincronizacion.pendiente:
        writer.writeByte(0);
        break;
      case EstadoSincronizacion.sincronizada:
        writer.writeByte(1);
        break;
      case EstadoSincronizacion.error:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstadoSincronizacionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TipoMedioAdapter extends TypeAdapter<TipoMedio> {
  @override
  final int typeId = 2;

  @override
  TipoMedio read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TipoMedio.foto;
      case 1:
        return TipoMedio.audio;
      case 2:
        return TipoMedio.documento;
      default:
        return TipoMedio.foto;
    }
  }

  @override
  void write(BinaryWriter writer, TipoMedio obj) {
    switch (obj) {
      case TipoMedio.foto:
        writer.writeByte(0);
        break;
      case TipoMedio.audio:
        writer.writeByte(1);
        break;
      case TipoMedio.documento:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipoMedioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
