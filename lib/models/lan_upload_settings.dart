import 'dart:math';

class LanUploadSettings {
  const LanUploadSettings({
    required this.enabled,
    required this.port,
    required this.autoStart,
    required this.token,
  });

  static const defaultPort = 8765;

  static LanUploadSettings defaults() {
    return LanUploadSettings(
      enabled: false,
      port: defaultPort,
      autoStart: false,
      token: generateToken(),
    );
  }

  final bool enabled;
  final int port;
  final bool autoStart;
  final String token;

  LanUploadSettings copyWith({
    bool? enabled,
    int? port,
    bool? autoStart,
    String? token,
  }) {
    return LanUploadSettings(
      enabled: enabled ?? this.enabled,
      port: port ?? this.port,
      autoStart: autoStart ?? this.autoStart,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'port': port,
      'autoStart': autoStart,
      'token': token,
    };
  }

  factory LanUploadSettings.fromJson(Map<String, dynamic> json) {
    final port = json['port'];
    return LanUploadSettings(
      enabled: json['enabled'] == true,
      port: port is int && port >= 1024 && port <= 65535 ? port : defaultPort,
      autoStart: json['autoStart'] == true,
      token: _parseToken(json['token']),
    );
  }

  static String generateToken() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  static String _parseToken(Object? raw) {
    if (raw is String && RegExp(r'^\d{6}$').hasMatch(raw)) {
      return raw;
    }
    return generateToken();
  }
}
