import '../../domain/entities/device_config.dart';

/// Reads the body of `GET /v1/devices/config`.
DeviceConfig deviceConfigFromJson(Map<String, dynamic> json) => DeviceConfig(
  dataset: json['dataset'] as String,
  model: json['model'] as String,
  version: json['version'] as int,
  sha256: (json['sha256'] as String).toLowerCase(),
  manifestUrl: Uri.parse(json['manifest_url'] as String),
  modelUrl: Uri.parse(json['model_url'] as String),
  expiresIn: Duration(seconds: json['expires_in'] as int),
);
