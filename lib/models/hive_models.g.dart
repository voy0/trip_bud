// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveTripAdapter extends TypeAdapter<HiveTrip> {
  @override
  final int typeId = 0;

  @override
  HiveTrip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveTrip(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      places: (fields[5] as List).cast<HivePlace>(),
      lastModified: fields[6] as DateTime,
      totalDistance: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HiveTrip obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.places)
      ..writeByte(6)
      ..write(obj.lastModified)
      ..writeByte(7)
      ..write(obj.totalDistance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTripAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HivePlaceAdapter extends TypeAdapter<HivePlace> {
  @override
  final int typeId = 1;

  @override
  HivePlace read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePlace(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      address: fields[4] as String,
      orderIndex: fields[5] as int,
      scheduledTime: fields[6] as DateTime?,
      transportMode: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HivePlace obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.orderIndex)
      ..writeByte(6)
      ..write(obj.scheduledTime)
      ..writeByte(7)
      ..write(obj.transportMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePlaceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
