import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/api_exception.dart';
import 'package:leaf_disease_mobile/features/models/data/datasources/model_remote_data_source.dart';

import '../../../../support/fake_http.dart';

const _crops = {
  'crops': [
    {
      'code': 'coffee',
      'display_name': 'Cà phê',
      'description': null,
      'datasets': [
        {'name': 'rocole', 'display_name': 'Lá cà phê (RoCoLe)', 'version': 3},
      ],
    },
  ],
};

const _config = {
  'dataset': 'rocole',
  'model': 'leaf-disease-rocole',
  'version': 3,
  'sha256': 'abababababababababababababababababababababababababababababababab',
  'manifest_url': 'https://s3.test/edge/leaf-disease-rocole/3/manifest.json',
  'model_url': 'https://s3.test/edge/leaf-disease-rocole/3/model.onnx',
  'expires_in': 900,
};

void main() {
  group('getCrops', () {
    test('reads every crop and its datasets', () async {
      final adapter = FakeHttpAdapter({
        'GET https://api.test/v1/crops': FakeResponse.json(200, _crops),
      });
      final source = ModelRemoteDataSourceImpl(fakeDio(adapter));

      final crops = await source.getCrops();

      expect(crops, hasLength(1));
      expect(crops.single.code, 'coffee');
      expect(crops.single.displayName, 'Cà phê');
      expect(crops.single.description, isNull);
      expect(crops.single.datasets.single.name, 'rocole');
      expect(crops.single.datasets.single.displayName, 'Lá cà phê (RoCoLe)');
      expect(crops.single.datasets.single.version, 3);
    });

    test('returns an empty list before any release', () async {
      final adapter = FakeHttpAdapter({
        'GET https://api.test/v1/crops': FakeResponse.json(200, {'crops': []}),
      });

      expect(await ModelRemoteDataSourceImpl(fakeDio(adapter)).getCrops(), []);
    });

    test('throws an ApiException with the code of the error body', () async {
      final adapter = FakeHttpAdapter({
        'GET https://api.test/v1/crops': FakeResponse.json(503, {
          'error': {'code': 'unavailable', 'message': 'The database is off.'},
        }),
      });

      await expectLater(
        ModelRemoteDataSourceImpl(fakeDio(adapter)).getCrops(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 503)
              .having((e) => e.code, 'code', 'unavailable')
              .having((e) => e.message, 'message', 'The database is off.'),
        ),
      );
    });

    test('throws an offline ApiException when the network is down', () async {
      final source = ModelRemoteDataSourceImpl(fakeDio(FakeHttpAdapter({})));

      await expectLater(
        source.getCrops(),
        throwsA(isA<ApiException>().having((e) => e.offline, 'offline', true)),
      );
    });
  });

  group('getDeviceConfig', () {
    test('asks for one dataset and reads the links', () async {
      final adapter = FakeHttpAdapter({
        'GET https://api.test/v1/devices/config?dataset=rocole':
            FakeResponse.json(200, _config),
      });

      final config = await ModelRemoteDataSourceImpl(fakeDio(adapter))
          .getDeviceConfig('rocole');

      expect(config, isNotNull);
      expect(config!.dataset, 'rocole');
      expect(config.model, 'leaf-disease-rocole');
      expect(config.version, 3);
      expect(config.sha256, 'ab' * 32);
      expect(config.modelUrl.path, '/edge/leaf-disease-rocole/3/model.onnx');
      expect(
        config.manifestUrl.path,
        '/edge/leaf-disease-rocole/3/manifest.json',
      );
    });

    test('returns null when no model is released yet', () async {
      final adapter = FakeHttpAdapter({
        'GET https://api.test/v1/devices/config?dataset=rocole':
            FakeResponse.json(404, {
              'error': {'code': 'not_found', 'message': 'No model yet.'},
            }),
      });

      expect(
        await ModelRemoteDataSourceImpl(fakeDio(adapter))
            .getDeviceConfig('rocole'),
        isNull,
      );
    });
  });

  group('the downloads', () {
    test('getManifest parses the platform manifest at the link', () async {
      final adapter = FakeHttpAdapter({
        'GET https://s3.test/m.json': FakeResponse.json(200, {
          'model': 'leaf-disease-rocole',
          'version': 3,
          'format': 'onnx',
          'sha256': 'ab' * 32,
          'size_bytes': 10,
          'preprocess': {
            'input_size': [256, 256],
            'mean': [0.485, 0.456, 0.406],
            'std': [0.229, 0.224, 0.225],
          },
          'labels': [
            {'code': 'healthy', 'display_name': 'Healthy'},
            {'code': 'rust', 'display_name': 'Rust'},
          ],
        }),
      });

      final manifest = await ModelRemoteDataSourceImpl(fakeDio(adapter))
          .getManifest(Uri.parse('https://s3.test/m.json'));

      expect(manifest.modelVersionRef, 'leaf-disease-rocole/3');
      expect(manifest.displayNames, ['Healthy', 'Rust']);
    });

    test('download returns the bytes at the link', () async {
      final adapter = FakeHttpAdapter({
        'GET https://s3.test/model.onnx': const FakeResponse(200, [1, 2, 3]),
      });

      final bytes = await ModelRemoteDataSourceImpl(fakeDio(adapter))
          .download(Uri.parse('https://s3.test/model.onnx'));

      expect(bytes, [1, 2, 3]);
    });

    test('download throws an ApiException on an expired link', () async {
      final adapter = FakeHttpAdapter({
        'GET https://s3.test/model.onnx': const FakeResponse(403, []),
      });

      await expectLater(
        ModelRemoteDataSourceImpl(fakeDio(adapter))
            .download(Uri.parse('https://s3.test/model.onnx')),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
    });
  });
}
