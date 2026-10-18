import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The tokens of a signed-in user.
class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory StoredSession.fromJson(Map<String, dynamic> json) => StoredSession(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String),
  );

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toUtc().toIso8601String(),
  };
}

/// Keeps the session in the Keychain or the Android Keystore.
abstract class TokenStore {
  Future<StoredSession?> read();

  Future<void> write(StoredSession session);

  Future<void> clear();
}

/// iOS keeps Keychain items after the app is deleted, so a new install could
/// find the session of an old one and skip sign-in. The app data goes with the
/// app, so a mark there tells this install from an earlier one.
class TokenStoreImpl implements TokenStore {
  TokenStoreImpl(this._preferences, [FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'auth.session';

  /// Set in the app data once this install has cleared the Keychain.
  static const installKey = 'auth.installed';

  final SharedPreferences _preferences;
  final FlutterSecureStorage _storage;

  Future<void> _forgetEarlierInstall() async {
    if (_preferences.getBool(installKey) ?? false) return;
    await _storage.delete(key: key);
    await _preferences.setBool(installKey, true);
  }

  @override
  Future<StoredSession?> read() async {
    await _forgetEarlierInstall();
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    try {
      return StoredSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) async {
    await _forgetEarlierInstall();
    await _storage.write(key: key, value: jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: key);
}
