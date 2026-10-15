import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/auth/data/datasources/token_store.dart';

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
}
