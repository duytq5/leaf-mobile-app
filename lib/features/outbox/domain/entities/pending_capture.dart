import 'dart:math';

import 'package:equatable/equatable.dart';

/// A scan waiting in the outbox for `POST /v1/captures` (design doc F1).
///
/// The record never changes after it is stored, so a resend after a lost
/// answer carries the same body, which the platform answers the same way.
class PendingCapture extends Equatable {
  const PendingCapture({
    required this.captureId,
    required this.dataset,
    required this.capturedAt,
    required this.modelVersion,
    required this.probs,
    required this.sha256,
    required this.contentType,
    required this.size,
    required this.imagePath,
  });

  factory PendingCapture.fromJson(Map<String, dynamic> json) => PendingCapture(
    captureId: json['capture_id'] as String,
    dataset: json['dataset'] as String,
    capturedAt: DateTime.parse(json['captured_at'] as String),
    modelVersion: json['model_version'] as String,
    probs: {
      for (final entry in (json['probs'] as Map<String, dynamic>).entries)
        entry.key: (entry.value as num).toDouble(),
    },
    sha256: json['sha256'] as String,
    contentType: json['content_type'] as String,
    size: json['size'] as int,
    imagePath: json['image_path'] as String,
  );

  /// The retry key: a version 4 UUID made on the phone.
  final String captureId;
  final String dataset;

  /// The phone's clock, in UTC.
  final DateTime capturedAt;

  /// `{model}/{version}` of the model that predicted.
  final String modelVersion;

  /// The probability of each class, keyed by class code.
  final Map<String, double> probs;

  final String sha256;
  final String contentType;
  final int size;
  final String imagePath;

  PendingCapture copyWith({String? imagePath}) => PendingCapture(
    captureId: captureId,
    dataset: dataset,
    capturedAt: capturedAt,
    modelVersion: modelVersion,
    probs: probs,
    sha256: sha256,
    contentType: contentType,
    size: size,
    imagePath: imagePath ?? this.imagePath,
  );

  /// The body of `POST /v1/captures` (`CaptureRequest` in `common/edge.py`).
  Map<String, dynamic> toRequestJson() => {
    'capture_id': captureId,
    'dataset': dataset,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    'image': {'sha256': sha256, 'content_type': contentType, 'size': size},
    'inference': {'model_version': modelVersion, 'probs': probs},
  };

  Map<String, dynamic> toJson() => {
    'capture_id': captureId,
    'dataset': dataset,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    'model_version': modelVersion,
    'probs': probs,
    'sha256': sha256,
    'content_type': contentType,
    'size': size,
    'image_path': imagePath,
  };

  @override
  List<Object?> get props => [
    captureId,
    dataset,
    capturedAt,
    modelVersion,
    probs,
    sha256,
    contentType,
    size,
    imagePath,
  ];
}

/// A random version 4 UUID.
String newCaptureId() {
  final random = Random.secure();
  final bytes = [for (var i = 0; i < 16; i++) random.nextInt(256)];
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
