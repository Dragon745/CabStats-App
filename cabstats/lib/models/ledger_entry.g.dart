// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerEntryAdapter extends TypeAdapter<LedgerEntry> {
  @override
  final int typeId = 5;

  @override
  LedgerEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerEntry(
      id: fields[0] as String,
      accountId: fields[1] as String,
      rideId: fields[2] as String,
      type: fields[3] as TransactionType,
      category: fields[4] as TransactionCategory,
      nature: fields[5] as TransactionNature,
      amount: fields[6] as double,
      description: fields[7] as String,
      timestamp: fields[8] as DateTime,
      reference: fields[9] as String?,
      lastModified: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.rideId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.nature)
      ..writeByte(6)
      ..write(obj.amount)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.timestamp)
      ..writeByte(9)
      ..write(obj.reference)
      ..writeByte(10)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 2;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.debit;
      case 1:
        return TransactionType.credit;
      default:
        return TransactionType.debit;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.debit:
        writer.writeByte(0);
        break;
      case TransactionType.credit:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionCategoryAdapter extends TypeAdapter<TransactionCategory> {
  @override
  final int typeId = 3;

  @override
  TransactionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionCategory.tollFee;
      case 1:
        return TransactionCategory.platformFee;
      case 2:
        return TransactionCategory.airportFee;
      case 3:
        return TransactionCategory.parkingFee;
      case 4:
        return TransactionCategory.fuel;
      case 5:
        return TransactionCategory.cigarettes;
      case 6:
        return TransactionCategory.tea;
      case 7:
        return TransactionCategory.water;
      case 8:
        return TransactionCategory.food;
      case 9:
        return TransactionCategory.goodies;
      case 10:
        return TransactionCategory.cleaning;
      case 11:
        return TransactionCategory.withdrawal;
      case 12:
        return TransactionCategory.saving;
      case 13:
        return TransactionCategory.rent;
      case 14:
        return TransactionCategory.tireMaintenance;
      case 15:
        return TransactionCategory.otherFee;
      case 16:
        return TransactionCategory.paymentReceived;
      case 17:
        return TransactionCategory.rideStart;
      case 18:
        return TransactionCategory.rideEnd;
      case 19:
        return TransactionCategory.rideCancel;
      case 20:
        return TransactionCategory.adjustment;
      default:
        return TransactionCategory.tollFee;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionCategory obj) {
    switch (obj) {
      case TransactionCategory.tollFee:
        writer.writeByte(0);
        break;
      case TransactionCategory.platformFee:
        writer.writeByte(1);
        break;
      case TransactionCategory.airportFee:
        writer.writeByte(2);
        break;
      case TransactionCategory.parkingFee:
        writer.writeByte(3);
        break;
      case TransactionCategory.fuel:
        writer.writeByte(4);
        break;
      case TransactionCategory.cigarettes:
        writer.writeByte(5);
        break;
      case TransactionCategory.tea:
        writer.writeByte(6);
        break;
      case TransactionCategory.water:
        writer.writeByte(7);
        break;
      case TransactionCategory.food:
        writer.writeByte(8);
        break;
      case TransactionCategory.goodies:
        writer.writeByte(9);
        break;
      case TransactionCategory.cleaning:
        writer.writeByte(10);
        break;
      case TransactionCategory.withdrawal:
        writer.writeByte(11);
        break;
      case TransactionCategory.saving:
        writer.writeByte(12);
        break;
      case TransactionCategory.rent:
        writer.writeByte(13);
        break;
      case TransactionCategory.tireMaintenance:
        writer.writeByte(14);
        break;
      case TransactionCategory.otherFee:
        writer.writeByte(15);
        break;
      case TransactionCategory.paymentReceived:
        writer.writeByte(16);
        break;
      case TransactionCategory.rideStart:
        writer.writeByte(17);
        break;
      case TransactionCategory.rideEnd:
        writer.writeByte(18);
        break;
      case TransactionCategory.rideCancel:
        writer.writeByte(19);
        break;
      case TransactionCategory.adjustment:
        writer.writeByte(20);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionNatureAdapter extends TypeAdapter<TransactionNature> {
  @override
  final int typeId = 4;

  @override
  TransactionNature read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionNature.earning;
      case 1:
        return TransactionNature.expense;
      case 2:
        return TransactionNature.transfer;
      case 3:
        return TransactionNature.adjustment;
      default:
        return TransactionNature.earning;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionNature obj) {
    switch (obj) {
      case TransactionNature.earning:
        writer.writeByte(0);
        break;
      case TransactionNature.expense:
        writer.writeByte(1);
        break;
      case TransactionNature.transfer:
        writer.writeByte(2);
        break;
      case TransactionNature.adjustment:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionNatureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
