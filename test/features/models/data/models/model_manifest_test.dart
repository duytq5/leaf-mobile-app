import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/models/data/models/model_manifest.dart';

/// A valid manifest. Each test copies it and changes one field.
Map<String, dynamic> validJson() => {
  'model_id': 'fastvit_t8_rocole',
  'version': 'al-round-07',
  'file_url': 'https://example.org/models/fastvit_t8_al07_int8.onnx',
  'sha256': 'a' * 64,
  'bytes': 3211264,
  'input': {
    'width': 256,
    'height': 256,
    'layout': 'NCHW',
    'mean': [0.485, 0.456, 0.406],
    'std': [0.229, 0.224, 0.225],
  },
  'labels': ['healthy', 'rust', 'red_spider_mite'],
  'min_app_build': 1,
};

void main() {
  group('ModelManifest.fromJson', () {
    test('reads every field of a valid manifest', () {
      final manifest = ModelManifest.fromJson(validJson());

      expect(manifest.modelId, 'fastvit_t8_rocole');
      expect(manifest.version, 'al-round-07');
      expect(manifest.sha256, 'a' * 64);
      expect(manifest.bytes, 3211264);
      expect(manifest.labels, ['healthy', 'rust', 'red_spider_mite']);
      expect(manifest.minAppBuild, 1);
      expect(manifest.input.width, 256);
      expect(manifest.input.layout, 'NCHW');
      expect(manifest.input.mean, [0.485, 0.456, 0.406]);
    });

    test('accepts an upper-case hash and stores it in lower case', () {
      final json = validJson()..['sha256'] = 'A' * 64;

      expect(ModelManifest.fromJson(json).sha256, 'a' * 64);
    });

    test('accepts an integer mean value', () {
      final json = validJson();
      (json['input'] as Map<String, dynamic>)['mean'] = [0, 0, 0];

      expect(ModelManifest.fromJson(json).input.mean, [0.0, 0.0, 0.0]);
    });

    test('rejects a hash that is too short', () {
      final json = validJson()..['sha256'] = 'abc123';

      expect(
        () => ModelManifest.fromJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects a hash with a character that is not hexadecimal', () {
      final json = validJson()..['sha256'] = 'z' * 64;

      expect(
        () => ModelManifest.fromJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects an absent required field', () {
      for (final key in ['model_id', 'version', 'input', 'labels']) {
        final json = validJson()..remove(key);

        expect(
          () => ModelManifest.fromJson(json),
          throwsA(isA<ManifestFormatException>()),
          reason: 'removing "$key" must fail',
        );
      }
    });

    test('accepts an asset manifest without the network fields', () {
      final json = validJson()
        ..remove('file_url')
        ..remove('sha256')
        ..remove('bytes')
        ..remove('min_app_build');

      final manifest = ModelManifest.fromJson(json);

      expect(manifest.fileUrl, isNull);
      expect(manifest.sha256, isNull);
      expect(manifest.bytes, isNull);
      // A manifest without the field runs on every build.
      expect(manifest.minAppBuild, 0);
      expect(manifest.supportsAppBuild(1), isTrue);
      expect(manifest.input.width, 256);
      expect(manifest.labels, hasLength(3));
    });

    test('still rejects a bad hash when the field is present', () {
      final json = validJson()..['sha256'] = 'not-a-hash';

      expect(
        () => ModelManifest.fromJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects an empty label list', () {
      final json = validJson()..['labels'] = <String>[];

      expect(
        () => ModelManifest.fromJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects a size that is not positive', () {
      final json = validJson()..['bytes'] = 0;

      expect(
        () => ModelManifest.fromJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects an unknown layout', () {
      final json = validJson();
      (json['input'] as Map<String, dynamic>)['layout'] = 'HWCN';

      expect(
        () => ModelManifest.fromJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects a mean with the wrong number of channels', () {
      final json = validJson();
      (json['input'] as Map<String, dynamic>)['mean'] = [0.5, 0.5];

      expect(
        () => ModelManifest.fromJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });

    test('rejects an input size that is not positive', () {
      final json = validJson();
      (json['input'] as Map<String, dynamic>)['width'] = -1;

      expect(
        () => ModelManifest.fromJson(json),
        throwsA(isA<ManifestFormatException>()),
      );
    });
  });

  group('isNewerThan', () {
    final installed = ModelManifest.fromJson(validJson());

    test('is true when no model is installed', () {
      expect(installed.isNewerThan(null), isTrue);
    });

    test('is false for the same model and the same version', () {
      final same = ModelManifest.fromJson(validJson());

      expect(same.isNewerThan(installed), isFalse);
    });

    test('is true for a new version', () {
      final next = ModelManifest.fromJson(
        validJson()..['version'] = 'al-round-08',
      );

      expect(next.isNewerThan(installed), isTrue);
    });

    test('is true for a different model family', () {
      final other = ModelManifest.fromJson(
        validJson()..['model_id'] = 'fastvit_t8_durian',
      );

      expect(other.isNewerThan(installed), isTrue);
    });
  });

  group('supportsAppBuild', () {
    test('accepts an app build at the minimum', () {
      final manifest = ModelManifest.fromJson(
        validJson()..['min_app_build'] = 5,
      );

      expect(manifest.supportsAppBuild(5), isTrue);
      expect(manifest.supportsAppBuild(9), isTrue);
    });

    test('rejects an app build below the minimum', () {
      final manifest = ModelManifest.fromJson(
        validJson()..['min_app_build'] = 5,
      );

      expect(manifest.supportsAppBuild(4), isFalse);
    });
  });

  test('toJson omits an absent network field', () {
    final json = validJson()
      ..remove('file_url')
      ..remove('sha256')
      ..remove('bytes');

    final written = ModelManifest.fromJson(json).toJson();

    expect(written.containsKey('file_url'), isFalse);
    expect(written.containsKey('sha256'), isFalse);
    expect(written.containsKey('bytes'), isFalse);
    expect(ModelManifest.fromJson(written).modelId, 'fastvit_t8_rocole');
  });

  test('toJson produces a manifest that parses again', () {
    final original = ModelManifest.fromJson(validJson());

    final parsed = ModelManifest.fromJson(original.toJson());

    expect(parsed.modelId, original.modelId);
    expect(parsed.version, original.version);
    expect(parsed.sha256, original.sha256);
    expect(parsed.labels, original.labels);
    expect(parsed.input.std, original.input.std);
  });
}
