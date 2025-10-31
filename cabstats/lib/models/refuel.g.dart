// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refuel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RefuelAdapter extends TypeAdapter<Refuel> {
  @override
  final int typeId = 8;

  @override
  Refuel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Refuel(
      id: fields[0] as String?,
      cost: fields[1] as double,
      kilometers: fields[2] as double,
      timestamp: fields[3] as DateTime,
      location: fields[4] as String?,
      notes: fields[5] as String?,
      lastModified: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Refuel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cost)
      ..writeByte(2)
      ..write(obj.kilometers)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefuelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
