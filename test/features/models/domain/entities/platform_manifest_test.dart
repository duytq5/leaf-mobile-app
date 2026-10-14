import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/model_manifest.dart';

/// A manifest as the platform writes it to `edge/{model}/{version}/manifest.json`.
Map<String, dynamic> platformJson() => {
  'model': 'leaf-disease-rocole',
  'version': 13,
  'format': 'onnx',
  'sha256': 'b' * 64,
  'size_bytes': 13000000,
  'preprocess': {
    'input_size': [256, 224],
    'mean': [0.485, 0.456, 0.406],
    'std': [0.229, 0.224, 0.225],
  },
  'labels': [
    {'code': 'healthy', 'display_name': 'Healthy'},
    {'code': 'rust', 'display_name': 'Rust'},
  ],
};

void main() {
  group('ModelManifest.fromPlatformJson', () {
    test('reads the model, the version and the file facts', () {
      final manifest = ModelManifest.fromPlatformJson(platformJson());

      expect(manifest.modelId, 'leaf-disease-rocole');
      expect(manifest.version, '13');
      expect(manifest.sha256, 'b' * 64);
      expect(manifest.bytes, 13000000);
    });

    test('names the model version as the captures API expects', () {
      final manifest = ModelManifest.fromPlatformJson(platformJson());

      expect(manifest.modelVersionRef, 'leaf-disease-rocole/13');
    });

    test('reads the input size as height then width, with a plain resize', () {
      final input = ModelManifest.fromPlatformJson(platformJson()).input;

      expect(input.height, 256);
      expect(input.width, 224);
      expect(input.layout, 'NCHW');
      expect(input.resizeShortest, isNull);
      expect(input.std, [0.229, 0.224, 0.225]);
    });

    test('keeps the codes in output order and the names beside them', () {
      final manifest = ModelManifest.fromPlatformJson(platformJson());

      expect(manifest.labels, ['healthy', 'rust']);
      expect(manifest.displayNames, ['Healthy', 'Rust']);
    });

    test('rejects a label without a code', () {
      final json = platformJson()
        ..['labels'] = [
          {'display_name': 'Healthy'},
          {'code': 'rust', 'display_name': 'Rust'},
        ];

      expect(
        () => ModelManifest.fromPlatformJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects a format other than onnx', () {
      final json = platformJson()..['format'] = 'tflite';

      expect(
        () => ModelManifest.fromPlatformJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects an input size that is not two numbers', () {
      final json = platformJson();
      (json['preprocess'] as Map<String, dynamic>)['input_size'] = [256];

      expect(
        () => ModelManifest.fromPlatformJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects a version below 1', () {
      final json = platformJson()..['version'] = 0;

      expect(
        () => ModelManifest.fromPlatformJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });
  });

  group('toPlatformJson', () {
    test('writes a manifest that parses back to the same model', () {
      final first = ModelManifest.fromPlatformJson(platformJson());
      final again = ModelManifest.fromPlatformJson(first.toPlatformJson());

      expect(again.modelVersionRef, first.modelVersionRef);
      expect(again.sha256, first.sha256);
      expect(again.bytes, first.bytes);
      expect(again.labels, first.labels);
      expect(again.displayNames, first.displayNames);
      expect(again.input.height, 256);
      expect(again.input.width, 224);
    });
  });

  group('a bundled manifest', () {
    test('shows each code as its own name', () {
      final manifest = ModelManifest.fromJson({
        'model_id': 'fastvit_t8_rocole',
        'version': 'fold-1-best',
        'input': {
          'width': 256,
          'height': 256,
          'layout': 'NCHW',
          'mean': [0.485, 0.456, 0.406],
          'std': [0.229, 0.224, 0.225],
        },
        'labels': ['coffee___healthy', 'coffee___rust'],
      });

      expect(manifest.displayNames, manifest.labels);
    });

    test('has no model version the captures API knows', () {
      final manifest = ModelManifest.fromJson({
        'model_id': 'fastvit_t8_rocole',
        'version': 'fold-1-best',
        'input': {
          'width': 256,
          'height': 256,
          'layout': 'NCHW',
          'mean': [0.485, 0.456, 0.406],
          'std': [0.229, 0.224, 0.225],
        },
        'labels': ['coffee___healthy', 'coffee___rust'],
      });

      expect(manifest.modelVersionRef, isNull);
    });
  });
}
