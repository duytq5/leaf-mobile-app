import 'package:leaf_disease_mobile/features/outbox/domain/entities/pending_capture.dart';

/// A capture of the released coffee model, waiting to be sent.
PendingCapture pendingCapture({
  String id = '7d9f2c8e-3b1a-4c5d-9e6f-0a1b2c3d4e5f',
}) => PendingCapture(
  captureId: id,
  dataset: 'rocole',
  capturedAt: DateTime.utc(2026, 10, 14, 8, 12),
  modelVersion: 'leaf-disease-rocole/3',
  probs: const {'healthy': 0.25, 'rust': 0.75},
  sha256: 'ab' * 32,
  contentType: 'image/jpeg',
  size: 4,
  imagePath: '/outbox/$id.jpg',
);
