// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_transfer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountTransferAdapter extends TypeAdapter<AccountTransfer> {
  @override
  final int typeId = 6;

  @override
  AccountTransfer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountTransfer(
      id: fields[0] as String,
      fromAccountId: fields[1] as String,
      toAccountId: fields[2] as String,
      amount: fields[3] as double,
      note: fields[4] as String?,
      timestamp: fields[5] as DateTime,
      lastModified: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AccountTransfer obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromAccountId)
      ..writeByte(2)
      ..write(obj.toAccountId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTransferAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
