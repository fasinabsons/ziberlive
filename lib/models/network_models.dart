
// Network SSID model
class NetworkSSIDModel {
  final String id;
  final String name;
  final String? password;
  final bool isSecure;

  NetworkSSIDModel({
    required this.id,
    required this.name,
    this.password,
    this.isSecure = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'isSecure': isSecure,
    };
  }

  factory NetworkSSIDModel.fromJson(Map<String, dynamic> json) {
    return NetworkSSIDModel(
      id: json['id'],
      name: json['name'],
      password: json['password'],
      isSecure: json['isSecure'] ?? false,
    );
  }
}

// Discovered user model
class DiscoveredUserModel {
  final String id;
  final String name;
  final String deviceId;
  final bool isAddedToSystem;

  DiscoveredUserModel({
    required this.id,
    required this.name,
    required this.deviceId,
    this.isAddedToSystem = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceId': deviceId,
      'isAddedToSystem': isAddedToSystem,
    };
  }

  factory DiscoveredUserModel.fromJson(Map<String, dynamic> json) {
    return DiscoveredUserModel(
      id: json['id'],
      name: json['name'],
      deviceId: json['deviceId'],
      isAddedToSystem: json['isAddedToSystem'] ?? false,
    );
  }
}

// For compatibility with existing code that uses NetworkSSID
typedef NetworkSSID = NetworkSSIDModel;
typedef DiscoveredUser = DiscoveredUserModel; 