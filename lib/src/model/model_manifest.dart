/// Thrown when a manifest is not valid.
///
/// The app keeps the installed model when this exception occurs.
class ManifestFormatException implements Exception {
  const ManifestFormatException(this.message);

  final String message;

  @override
  String toString() => 'ManifestFormatException: $message';
}

/// The input specification of a model.
///
/// The values travel with the model. The app does not hold them in its code. A
/// new model can change the size or the normalization without a new app
/// release.
class InputSpec {
  const InputSpec({
    required this.width,
    required this.height,
    required this.layout,
    required this.mean,
    required this.std,
  });

  factory InputSpec.fromJson(Map<String, dynamic> json) {
    final width = _requireInt(json, 'width');
    final height = _requireInt(json, 'height');
    if (width <= 0 || height <= 0) {
      throw const ManifestFormatException('input size must be positive');
    }

    final layout = _requireString(json, 'layout');
    if (layout != 'NCHW' && layout != 'NHWC') {
      throw ManifestFormatException('unknown layout "$layout"');
    }

    return InputSpec(
      width: width,
      height: height,
      layout: layout,
      mean: _requireChannelTriple(json, 'mean'),
      std: _requireChannelTriple(json, 'std'),
    );
  }

  final int width;
  final int height;

  /// The tensor layout. The value is `NCHW` or `NHWC`.
  final String layout;

  /// The per-channel mean in red, green, blue order. The range is 0.0 to 1.0.
  final List<double> mean;

  /// The per-channel standard deviation in red, green, blue order.
  final List<double> std;
}

/// The description of one published model.
///
/// The server publishes this record at a fixed URL. The app reads it to decide
/// whether an update is available.
class ModelManifest {
  const ModelManifest({
    required this.modelId,
    required this.version,
    required this.fileUrl,
    required this.sha256,
    required this.bytes,
    required this.input,
    required this.labels,
    required this.minAppBuild,
  });

  /// Parses a manifest.
  ///
  /// Throws [ManifestFormatException] when a field is absent or not valid.
  factory ModelManifest.fromJson(Map<String, dynamic> json) {
    final sha256 = _requireString(json, 'sha256').toLowerCase();
    if (!_sha256Pattern.hasMatch(sha256)) {
      throw const ManifestFormatException(
        'sha256 must be 64 hexadecimal characters',
      );
    }

    final bytes = _requireInt(json, 'bytes');
    if (bytes <= 0) {
      throw const ManifestFormatException('bytes must be positive');
    }

    final rawLabels = json['labels'];
    if (rawLabels is! List || rawLabels.isEmpty) {
      throw const ManifestFormatException('labels must be a non-empty list');
    }

    final inputJson = json['input'];
    if (inputJson is! Map<String, dynamic>) {
      throw const ManifestFormatException('input must be an object');
    }

    return ModelManifest(
      modelId: _requireString(json, 'model_id'),
      version: _requireString(json, 'version'),
      fileUrl: _requireString(json, 'file_url'),
      sha256: sha256,
      bytes: bytes,
      input: InputSpec.fromJson(inputJson),
      labels: rawLabels.map((l) => l.toString()).toList(growable: false),
      minAppBuild: _requireInt(json, 'min_app_build'),
    );
  }

  /// The identity of the model family, for example `fastvit_t8_rocole`.
  final String modelId;

  /// The version of this model, for example `al-round-07`.
  final String version;

  final String fileUrl;

  /// The SHA-256 hash of the model file, in lower-case hexadecimal.
  final String sha256;

  /// The size of the model file in bytes.
  final int bytes;

  final InputSpec input;

  /// The class names in the output order of the model.
  final List<String> labels;

  /// The lowest app build that can run this model.
  final int minAppBuild;

  /// Reports whether this manifest describes a different model than
  /// [installed].
  ///
  /// A null [installed] means no model is installed yet.
  bool isNewerThan(ModelManifest? installed) =>
      installed == null ||
      installed.modelId != modelId ||
      installed.version != version;

  /// Reports whether the app build [appBuild] can run this model.
  bool supportsAppBuild(int appBuild) => appBuild >= minAppBuild;

  Map<String, dynamic> toJson() => {
    'model_id': modelId,
    'version': version,
    'file_url': fileUrl,
    'sha256': sha256,
    'bytes': bytes,
    'input': {
      'width': input.width,
      'height': input.height,
      'layout': input.layout,
      'mean': input.mean,
      'std': input.std,
    },
    'labels': labels,
    'min_app_build': minAppBuild,
  };
}

final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw ManifestFormatException('"$key" must be a non-empty string');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw ManifestFormatException('"$key" must be an integer');
  }
  return value;
}

List<double> _requireChannelTriple(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.length != 3) {
    throw ManifestFormatException('"$key" must hold 3 numbers');
  }
  return value.map((v) {
    if (v is! num) {
      throw ManifestFormatException('"$key" must hold numbers only');
    }
    return v.toDouble();
  }).toList(growable: false);
}
