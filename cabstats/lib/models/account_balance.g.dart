// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_balance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountBalanceAdapter extends TypeAdapter<AccountBalance> {
  @override
  final int typeId = 10;

  @override
  AccountBalance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountBalance(
      accountId: fields[0] as String,
      accountName: fields[1] as String,
      accountType: fields[2] as String,
      balance: fields[3] as double,
      lastUpdated: fields[4] as DateTime,
      lastModified: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AccountBalance obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.accountId)
      ..writeByte(1)
      ..write(obj.accountName)
      ..writeByte(2)
      ..write(obj.accountType)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountBalanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
