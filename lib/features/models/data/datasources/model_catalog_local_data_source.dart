import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/leaf_model.dart';
import '../../domain/entities/model_manifest.dart';

/// Reads the models that ship in the assets, and holds the selected id.
abstract class ModelCatalogLocalDataSource {
  Future<List<LeafModel>> readCatalog();

  /// Returns null when the user did not select a model yet.
  String? readSelectedId();

  Future<void> writeSelectedId(String id);
}

class ModelCatalogLocalDataSourceImpl implements ModelCatalogLocalDataSource {
  ModelCatalogLocalDataSourceImpl({
    required this.preferences,
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  static const catalogAsset = 'assets/models/catalog.json';
  static const selectedKey = 'models.selected';

  final SharedPreferences preferences;
  final AssetBundle _bundle;

  @override
  Future<List<LeafModel>> readCatalog() async {
    final catalog =
        jsonDecode(await _bundle.loadString(catalogAsset))
            as Map<String, dynamic>;
    final entries = catalog['models'];
    if (entries is! List || entries.isEmpty) {
      throw const FormatException('the catalog lists no model');
    }

    final models = <LeafModel>[];
    for (final raw in entries) {
      final entry = raw as Map<String, dynamic>;
      final dir = entry['dir'] as String;
      final manifest = ModelManifest.fromJson(
        jsonDecode(await _bundle.loadString('$dir/manifest.json'))
            as Map<String, dynamic>,
      );

      models.add(
        LeafModel(
          id: entry['id'] as String,
          displayName: entry['display_name'] as String,
          dataset: entry['dataset'] as String,
          manifest: manifest,
          modelAsset: '$dir/model.onnx',
        ),
      );
    }
    return models;
  }

  @override
  String? readSelectedId() => preferences.getString(selectedKey);

  @override
  Future<void> writeSelectedId(String id) =>
      preferences.setString(selectedKey, id);
}
