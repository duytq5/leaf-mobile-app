import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/auth/data/datasources/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a session survives the JSON round trip', () {
    final session = StoredSession(
      accessToken: 'at',
      refreshToken: 'rt',
      expiresAt: DateTime.utc(2026, 10, 14, 13),
    );

    final again = StoredSession.fromJson(session.toJson());

    expect(again.accessToken, 'at');
    expect(again.refreshToken, 'rt');
    expect(again.expiresAt, DateTime.utc(2026, 10, 14, 13));
  });

  group('a new install', () {
    final session = StoredSession(
      accessToken: 'at',
      refreshToken: 'rt',
      expiresAt: DateTime.utc(2026, 10, 14, 13),
    );
    final raw = jsonEncode(session.toJson());

    test(
      'forgets a session the Keychain kept from an earlier install',
      () async {
        // iOS keeps Keychain items after the app is deleted. The app data,
        // with the install mark, goes with the app.
        FlutterSecureStorage.setMockInitialValues({TokenStoreImpl.key: raw});
        SharedPreferences.setMockInitialValues({});
        const storage = FlutterSecureStorage();
        final store = TokenStoreImpl(
          await SharedPreferences.getInstance(),
          storage,
        );

        expect(await store.read(), isNull);
        expect(await storage.read(key: TokenStoreImpl.key), isNull);
      },
    );

    test('keeps the session of this install', () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final store = TokenStoreImpl(await SharedPreferences.getInstance());

      await store.write(session);

      expect((await store.read())?.refreshToken, 'rt');
    });

    test('keeps a session after a restart of the same install', () async {
      FlutterSecureStorage.setMockInitialValues({TokenStoreImpl.key: raw});
      SharedPreferences.setMockInitialValues({TokenStoreImpl.installKey: true});
      final store = TokenStoreImpl(await SharedPreferences.getInstance());

      expect((await store.read())?.refreshToken, 'rt');
    });
  });
}
