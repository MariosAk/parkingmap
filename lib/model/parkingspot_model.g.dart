// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parkingspot_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParkingSpotModelAdapter extends TypeAdapter<ParkingSpotModel> {
  @override
  final int typeId = 3;

  @override
  ParkingSpotModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ParkingSpotModel(
      address: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      timestamp: fields[3] as DateTime?,
      probability: fields[4] as double?,
      reports: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ParkingSpotModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.address)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.probability)
      ..writeByte(5)
      ..write(obj.reports);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSpotModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
