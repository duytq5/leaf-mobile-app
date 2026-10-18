import 'package:shared_preferences/shared_preferences.dart';

/// Holds the id of the model the user selected.
abstract class ModelCatalogLocalDataSource {
  /// Returns null when the user did not select a model yet.
  String? readSelectedId();

  Future<void> writeSelectedId(String id);
}

class ModelCatalogLocalDataSourceImpl implements ModelCatalogLocalDataSource {
  ModelCatalogLocalDataSourceImpl({required this.preferences});

  static const selectedKey = 'models.selected';

  final SharedPreferences preferences;

  @override
  String? readSelectedId() => preferences.getString(selectedKey);

  @override
  Future<void> writeSelectedId(String id) =>
      preferences.setString(selectedKey, id);
}
