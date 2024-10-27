// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'latlng_bounds_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LatLngBoundsModelAdapter extends TypeAdapter<LatLngBoundsModel> {
  @override
  final int typeId = 2;

  @override
  LatLngBoundsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LatLngBoundsModel(
      swLat: fields[0] as double,
      swLng: fields[1] as double,
      neLat: fields[2] as double,
      neLng: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LatLngBoundsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.swLat)
      ..writeByte(1)
      ..write(obj.swLng)
      ..writeByte(2)
      ..write(obj.neLat)
      ..writeByte(3)
      ..write(obj.neLng);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLngBoundsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
