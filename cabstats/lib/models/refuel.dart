class Refuel {
  final String? id;
  final double cost;
  final double kilometers;
  final DateTime timestamp;
  final String? location;
  final String? notes;

  Refuel({
    this.id,
    required this.cost,
    required this.kilometers,
    required this.timestamp,
    this.location,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cost': cost,
      'kilometers': kilometers,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'location': location,
      'notes': notes,
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
    );
  }

  Refuel copyWith({
    String? id,
    double? cost,
    double? kilometers,
    DateTime? timestamp,
    String? location,
    String? notes,
  }) {
    return Refuel(
      id: id ?? this.id,
      cost: cost ?? this.cost,
      kilometers: kilometers ?? this.kilometers,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }
}
