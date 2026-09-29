import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/consent_record_model.dart';

/// Holds the agreement on the device.
abstract class ConsentLocalDataSource {
  /// Returns null when the user did not answer yet.
  Future<ConsentRecordModel?> read();

  Future<void> write(ConsentRecordModel model);
}

class ConsentLocalDataSourceImpl implements ConsentLocalDataSource {
  ConsentLocalDataSourceImpl(this._preferences);

  static const key = 'consent.record';

  final SharedPreferences _preferences;

  @override
  Future<ConsentRecordModel?> read() async {
    final raw = _preferences.getString(key);
    if (raw == null) return null;
    return ConsentRecordModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> write(ConsentRecordModel model) async {
    await _preferences.setString(key, jsonEncode(model.toJson()));
  }
}
