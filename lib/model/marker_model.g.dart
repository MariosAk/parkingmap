// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marker_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MarkerModelAdapter extends TypeAdapter<MarkerModel> {
  @override
  final int typeId = 1;

  @override
  MarkerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MarkerModel(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      width: fields[2] as double,
      height: fields[3] as double,
      alignment: fields[4] as Alignment?,
      rotate: fields[5] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, MarkerModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.width)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.alignment)
      ..writeByte(5)
      ..write(obj.rotate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
