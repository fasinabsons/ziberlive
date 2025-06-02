class Apartment {
  final String id;
  final String name;
  final List<Room> rooms;

  Apartment({required this.id, required this.name, required this.rooms});

  factory Apartment.fromJson(Map<String, dynamic> json) => Apartment(
    id: json['id'],
    name: json['name'],
    rooms: (json['rooms'] as List<dynamic>? ?? []).map((e) => Room.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rooms': rooms.map((e) => e.toJson()).toList(),
  };
}

class Room {
  final String id;
  final String name;
  bool isVacant;

  Room({required this.id, required this.name, this.isVacant = true});

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'],
    name: json['name'],
    isVacant: json['isVacant'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isVacant': isVacant,
  };
}
