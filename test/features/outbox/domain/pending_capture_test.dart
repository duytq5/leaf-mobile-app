import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/outbox/domain/entities/pending_capture.dart';

import '../../../support/outbox_fixtures.dart';

void main() {
  test('the request body is the CaptureRequest of the platform', () {
    expect(pendingCapture().toRequestJson(), {
      'capture_id': '7d9f2c8e-3b1a-4c5d-9e6f-0a1b2c3d4e5f',
      'dataset': 'rocole',
      'captured_at': '2026-10-14T08:12:00.000Z',
      'image': {'sha256': 'ab' * 32, 'content_type': 'image/jpeg', 'size': 4},
      'inference': {
        'model_version': 'leaf-disease-rocole/3',
        'probs': {'healthy': 0.25, 'rust': 0.75},
      },
    });
  });

  test('the stored form reads back to the same capture', () {
    final capture = pendingCapture();

    expect(PendingCapture.fromJson(capture.toJson()), capture);
  });

  test('newCaptureId is a version 4 UUID', () {
    final id = newCaptureId();

    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(id),
      isTrue,
    );
    expect(newCaptureId(), isNot(id));
  });
}
