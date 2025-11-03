class Status {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final DeviceInfo deviceInfo;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;

  Status({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.deviceInfo,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceInfo: DeviceInfo.fromJson(json['device_info'] as Map<String, dynamic>),
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'device_info': deviceInfo.toJson(),
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'is_liked': isLiked,
    };
  }

  Status copyWith({
    String? id,
    String? userId,
    String? content,
    String? imageUrl,
    DateTime? timestamp,
    DeviceInfo? deviceInfo,
    int? likes,
    int? comments,
    int? shares,
    bool? isLiked,
  }) {
    return Status(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class DeviceInfo {
  final LocationInfo? location;
  final BatteryInfo? battery;
  final ConnectivityInfo connectivity;
  final String deviceModel;
  final String operatingSystem;
  final String appVersion;

  DeviceInfo({
    this.location,
    this.battery,
    required this.connectivity,
    required this.deviceModel,
    required this.operatingSystem,
    required this.appVersion,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      location: json['location'] != null 
          ? LocationInfo.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      battery: json['battery'] != null
          ? BatteryInfo.fromJson(json['battery'] as Map<String, dynamic>)
          : null,
      connectivity: ConnectivityInfo.fromJson(json['connectivity'] as Map<String, dynamic>),
      deviceModel: json['device_model'] as String,
      operatingSystem: json['operating_system'] as String,
      appVersion: json['app_version'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location?.toJson(),
      'battery': battery?.toJson(),
      'connectivity': connectivity.toJson(),
      'device_model': deviceModel,
      'operating_system': operatingSystem,
      'app_version': appVersion,
    };
  }
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final double? accuracy;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.accuracy,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      city: json['city'] as String?,
      country: json['country'] as String?,
      accuracy: json['accuracy'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'accuracy': accuracy,
    };
  }
}

class BatteryInfo {
  final int level; // 0-100
  final bool isCharging;
  final String chargingStatus; // 'charging', 'discharging', 'full', 'unknown'

  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.chargingStatus,
  });

  factory BatteryInfo.fromJson(Map<String, dynamic> json) {
    return BatteryInfo(
      level: json['level'] as int,
      isCharging: json['is_charging'] as bool,
      chargingStatus: json['charging_status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'is_charging': isCharging,
      'charging_status': chargingStatus,
    };
  }
}

class ConnectivityInfo {
  final String type; // 'wifi', 'mobile', 'ethernet', 'none'
  final String? networkName;
  final int? signalStrength; // 0-100 for mobile, null for wifi
  final bool isConnected;

  ConnectivityInfo({
    required this.type,
    this.networkName,
    this.signalStrength,
    required this.isConnected,
  });

  factory ConnectivityInfo.fromJson(Map<String, dynamic> json) {
    return ConnectivityInfo(
      type: json['type'] as String,
      networkName: json['network_name'] as String?,
      signalStrength: json['signal_strength'] as int?,
      isConnected: json['is_connected'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'network_name': networkName,
      'signal_strength': signalStrength,
      'is_connected': isConnected,
    };
  }
}