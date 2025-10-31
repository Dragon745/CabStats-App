// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_tips.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingTipsAdapter extends TypeAdapter<PendingTips> {
  @override
  final int typeId = 9;

  @override
  PendingTips read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingTips(
      id: fields[0] as String,
      amount: fields[1] as double,
      rideIds: (fields[2] as List).cast<String>(),
      lastUpdated: fields[3] as DateTime,
      lastModified: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingTips obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.rideIds)
      ..writeByte(3)
      ..write(obj.lastUpdated)
      ..writeByte(4)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingTipsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
