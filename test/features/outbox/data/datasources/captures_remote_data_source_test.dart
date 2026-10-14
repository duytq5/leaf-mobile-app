import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/api_exception.dart';
import 'package:leaf_disease_mobile/features/outbox/data/datasources/captures_remote_data_source.dart';

import '../../../../support/fake_http.dart';
import '../../../../support/outbox_fixtures.dart';

void main() {
  test('create posts the capture with the bearer token', () async {
    final adapter = FakeHttpAdapter({
      'POST https://api.test/v1/captures': FakeResponse.json(200, {
        'capture_id': pendingCapture().captureId,
        'status': 'upload_required',
        'upload': {
          'url': 'https://s3.test/incoming/x.jpg?sig=1',
          'method': 'PUT',
          'headers': {'Content-Type': 'image/jpeg'},
          'expires_in': 900,
        },
      }),
    });

    final answer = await CapturesRemoteDataSourceImpl(fakeDio(adapter))
        .create(token: 'at', capture: pendingCapture());

    final request = adapter.requests.single;
    expect(request.headers['Authorization'], 'Bearer at');
    expect(
      jsonDecode(utf8.decode(adapter.bodies.single)),
      pendingCapture().toRequestJson(),
    );
    expect(answer.alreadyExists, isFalse);
    expect(answer.uploadUrl.toString(), 'https://s3.test/incoming/x.jpg?sig=1');
    expect(answer.uploadHeaders, {'Content-Type': 'image/jpeg'});
  });

  test('create reads already_exists', () async {
    final adapter = FakeHttpAdapter({
      'POST https://api.test/v1/captures': FakeResponse.json(200, {
        'capture_id': pendingCapture().captureId,
        'status': 'already_exists',
      }),
    });

    final answer = await CapturesRemoteDataSourceImpl(fakeDio(adapter))
        .create(token: 'at', capture: pendingCapture());

    expect(answer.alreadyExists, isTrue);
  });

  test('a daily limit is an ApiException with Retry-After', () async {
    final adapter = FakeHttpAdapter({
      'POST https://api.test/v1/captures': FakeResponse(
        429,
        utf8.encode(
          jsonEncode({
            'error': {'code': 'quota_exceeded', 'message': 'Daily limit.'},
          }),
        ),
        headers: const {
          'content-type': ['application/json'],
          'retry-after': ['120'],
        },
      ),
    });

    await expectLater(
      CapturesRemoteDataSourceImpl(fakeDio(adapter))
          .create(token: 'at', capture: pendingCapture()),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'quota_exceeded')
            .having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(minutes: 2),
            ),
      ),
    );
  });

  test('upload puts the bytes with the signed headers and no token', () async {
    final adapter = FakeHttpAdapter({
      'PUT https://s3.test/incoming/x.jpg?sig=1': const FakeResponse(200, []),
    });

    await CapturesRemoteDataSourceImpl(fakeDio(adapter)).upload(
      url: Uri.parse('https://s3.test/incoming/x.jpg?sig=1'),
      headers: const {
        'Content-Type': 'image/jpeg',
        'Content-Length': '3',
        'x-amz-checksum-sha256': 'q',
      },
      bytes: [1, 2, 3],
    );

    final request = adapter.requests.single;
    expect(adapter.bodies.single, [1, 2, 3]);
    expect(request.headers['x-amz-checksum-sha256'], 'q');
    expect(
      request.headers['content-type'] ?? request.contentType,
      'image/jpeg',
    );
    expect(
      request.headers['content-length'] ?? request.headers['Content-Length'],
      '3',
    );
    expect(request.headers.containsKey('Authorization'), isFalse);
  });
}
