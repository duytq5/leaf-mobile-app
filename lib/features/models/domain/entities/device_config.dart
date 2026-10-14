import 'package:equatable/equatable.dart';

/// The current model of one dataset and the links to download it.
///
/// The links are presigned and expire after [expiresIn].
class DeviceConfig extends Equatable {
  const DeviceConfig({
    required this.dataset,
    required this.model,
    required this.version,
    required this.sha256,
    required this.manifestUrl,
    required this.modelUrl,
    required this.expiresIn,
  });

  final String dataset;

  /// The registered model name, for example `leaf-disease-rocole`.
  final String model;
  final int version;

  /// The SHA-256 of the ONNX file, in lower-case hexadecimal.
  final String sha256;
  final Uri manifestUrl;
  final Uri modelUrl;
  final Duration expiresIn;

  @override
  List<Object?> get props => [dataset, model, version, sha256];
}
