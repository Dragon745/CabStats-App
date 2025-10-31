// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_fuel_allocation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingFuelAllocationAdapter extends TypeAdapter<PendingFuelAllocation> {
  @override
  final int typeId = 7;

  @override
  PendingFuelAllocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingFuelAllocation(
      id: fields[0] as String,
      amount: fields[1] as double,
      lastUpdated: fields[2] as DateTime,
      rideIds: (fields[3] as List).cast<String>(),
      lastModified: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingFuelAllocation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.lastUpdated)
      ..writeByte(3)
      ..write(obj.rideIds)
      ..writeByte(4)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingFuelAllocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
