import 'dart:typed_data';

class WhitelistApp {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final bool isWhitelisted;

  WhitelistApp({
    required this.packageName,
    required this.appName,
    this.icon,
    this.isWhitelisted = false,
  });

  WhitelistApp copyWith({
    String? packageName,
    String? appName,
    Uint8List? icon,
    bool? isWhitelisted,
  }) {
    return WhitelistApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      icon: icon ?? this.icon,
      isWhitelisted: isWhitelisted ?? this.isWhitelisted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isWhitelisted': isWhitelisted,
    };
  }

  factory WhitelistApp.fromJson(Map<String, dynamic> json) {
    return WhitelistApp(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      isWhitelisted: json['isWhitelisted'] as bool? ?? false,
    );
  }
}

