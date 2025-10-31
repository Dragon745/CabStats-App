// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RideAdapter extends TypeAdapter<Ride> {
  @override
  final int typeId = 1;

  @override
  Ride read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ride(
      id: fields[0] as String,
      userId: fields[1] as String,
      startLocality: fields[2] as String,
      endLocality: fields[3] as String?,
      startTime: fields[4] as DateTime,
      endTime: fields[5] as DateTime?,
      km: fields[6] as double,
      fare: fields[7] as double,
      tollFee: fields[8] as double,
      platformFee: fields[9] as double,
      otherFee: fields[10] as double,
      airportFee: fields[11] as double,
      paymentSplits: (fields[12] as Map).cast<String, double>(),
      tollFeeAccount: fields[13] as String,
      platformFeeAccount: fields[14] as String,
      otherFeeAccount: fields[15] as String,
      airportFeeAccount: fields[16] as String,
      status: fields[17] as RideStatus,
      lastModified: fields[18] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Ride obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.startLocality)
      ..writeByte(3)
      ..write(obj.endLocality)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.km)
      ..writeByte(7)
      ..write(obj.fare)
      ..writeByte(8)
      ..write(obj.tollFee)
      ..writeByte(9)
      ..write(obj.platformFee)
      ..writeByte(10)
      ..write(obj.otherFee)
      ..writeByte(11)
      ..write(obj.airportFee)
      ..writeByte(12)
      ..write(obj.paymentSplits)
      ..writeByte(13)
      ..write(obj.tollFeeAccount)
      ..writeByte(14)
      ..write(obj.platformFeeAccount)
      ..writeByte(15)
      ..write(obj.otherFeeAccount)
      ..writeByte(16)
      ..write(obj.airportFeeAccount)
      ..writeByte(17)
      ..write(obj.status)
      ..writeByte(18)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RideStatusAdapter extends TypeAdapter<RideStatus> {
  @override
  final int typeId = 0;

  @override
  RideStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RideStatus.active;
      case 1:
        return RideStatus.completed;
      case 2:
        return RideStatus.cancelled;
      default:
        return RideStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, RideStatus obj) {
    switch (obj) {
      case RideStatus.active:
        writer.writeByte(0);
        break;
      case RideStatus.completed:
        writer.writeByte(1);
        break;
      case RideStatus.cancelled:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
