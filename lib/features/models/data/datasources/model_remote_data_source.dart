import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/dio_errors.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/device_config.dart';
import '../../domain/entities/model_manifest.dart';
import '../models/crop_model.dart';
import '../models/device_config_model.dart';

/// Reads the public model routes of the Edge API and downloads model files.
///
/// Every method throws an [ApiException] when a request fails.
abstract class ModelRemoteDataSource {
  /// `GET /v1/crops`. The list is empty until a model is released.
  Future<List<Crop>> getCrops();

  /// `GET /v1/devices/config?dataset=`. Returns null when the dataset has no
  /// released model yet.
  Future<DeviceConfig?> getDeviceConfig(String dataset);

  /// Reads the manifest at a presigned link.
  Future<ModelManifest> getManifest(Uri url);

  /// Reads the bytes at a presigned link. [onProgress] gets a fraction from 0
  /// to 1, or null while the size is unknown.
  Future<Uint8List> download(
    Uri url, {
    void Function(double? progress)? onProgress,
  });
}

class ModelRemoteDataSourceImpl implements ModelRemoteDataSource {
  ModelRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Crop>> getCrops() async {
    final body = await _getJson('/v1/crops');
    return [
      for (final raw in body['crops'] as List)
        cropFromJson(raw as Map<String, dynamic>),
    ];
  }

  @override
  Future<DeviceConfig?> getDeviceConfig(String dataset) async {
    try {
      final body = await _getJson(
        '/v1/devices/config',
        query: {'dataset': dataset},
      );
      return deviceConfigFromJson(body);
    } on ApiException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<ModelManifest> getManifest(Uri url) async =>
      ModelManifest.fromPlatformJson(await _getJson(url.toString()));

  @override
  Future<Uint8List> download(
    Uri url, {
    void Function(double? progress)? onProgress,
  }) async {
    try {
      final response = await _dio.getUri<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress == null
            ? null
            : (received, total) =>
                  onProgress(total > 0 ? received / total : null),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Object?>(path, queryParameters: query);
      final data = response.data;
      // S3 can serve a JSON file as binary/octet-stream, and then Dio hands
      // over the text unparsed.
      if (data is String) return jsonDecode(data) as Map<String, dynamic>;
      if (data is List<int>) {
        return jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      }
      return (data as Map<String, dynamic>?) ?? const {};
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}
