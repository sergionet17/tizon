// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually updated to support field 11 (poligono: List<LatLng>)
// Run `dart run build_runner build` to regenerate after further model changes.

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

    // Migración: si no hay polígono (datos viejos), construir uno con el
    // punto de ubicación legacy para no perder información.
    final legacyUbicacion = fields[2] as LatLng?;
    final rawPoligono = fields[11];
    List<LatLng> poligono;
    if (rawPoligono != null) {
      poligono = (rawPoligono as List).cast<LatLng>();
    } else if (legacyUbicacion != null) {
      poligono = [legacyUbicacion];
    } else {
      poligono = [];
    }

    return Finca(
      id: fields[0] as int?,
      nombre: fields[1] as String,
      ubicacion: legacyUbicacion,
      firebaseId: fields[3] as String?,
      cultivo: fields[4] as String?,
      area: fields[5] as double?,
      imagePath: fields[6] as String?,
      imageUrl: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      estadoSinc: fields[10] as EstadoSincronizacion,
      poligono: poligono,
    );
  }

  @override
  void write(BinaryWriter writer, Finca obj) {
    // Guardamos el centroide en el campo legacy (field 2) para
    // compatibilidad con versiones anteriores del adapter.
    final centroide = obj.poligono.isNotEmpty ? obj.centroide : obj.ubicacion;

    writer
      ..writeByte(12) // 12 campos: 0-10 originales + field 11 (poligono)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(centroide)
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
      ..write(obj.estadoSinc)
      ..writeByte(11)
      ..write(obj.poligono);
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
