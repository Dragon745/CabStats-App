import 'package:hive/hive.dart';

part 'refuel.g.dart';

@HiveType(typeId: 8)
class Refuel {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final double cost;
  @HiveField(2)
  final double kilometers;
  @HiveField(3)
  final DateTime timestamp;
  @HiveField(4)
  final String? location;
  @HiveField(5)
  final String? notes;
  @HiveField(6)
  final DateTime lastModified;

  Refuel({
    this.id,
    required this.cost,
    required this.kilometers,
    required this.timestamp,
    this.location,
    this.notes,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cost': cost,
      'kilometers': kilometers,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'location': location,
      'notes': notes,
      'lastModified': lastModified.millisecondsSinceEpoch,
    };
  }

  factory Refuel.fromJson(Map<String, dynamic> json) {
    return Refuel(
      id: json['id'],
      cost: (json['cost'] as num).toDouble(),
      kilometers: (json['kilometers'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      location: json['location'],
      notes: json['notes'],
      lastModified: json['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
          : DateTime.now(),
    );
  }

  Refuel copyWith({
    String? id,
    double? cost,
    double? kilometers,
    DateTime? timestamp,
    String? location,
    String? notes,
    DateTime? lastModified,
  }) {
    return Refuel(
      id: id ?? this.id,
      cost: cost ?? this.cost,
      kilometers: kilometers ?? this.kilometers,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      lastModified: lastModified ?? DateTime.now(),
    );
  }
}
