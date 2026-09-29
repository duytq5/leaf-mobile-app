import 'dart:typed_data';

import 'package:leaf_disease_mobile/features/scan/domain/entities/class_score.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/scan_result.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/uncertainty.dart';

final scanImageBytes = Uint8List.fromList(List.filled(64, 3));

/// A result of the coffee model: rust at 87 percent, as the design shows.
ScanResult coffeeScan({
  List<double> probabilities = const [0.08, 0.05, 0.87],
  String modelId = 'coffee_rocole',
  String modelVersion = 'fold-1-best',
}) {
  const labels = [
    'coffee___healthy',
    'coffee___red_spider_mite',
    'coffee___rust',
  ];
  final scores = <ClassScore>[
    for (var i = 0; i < labels.length; i++)
      ClassScore(labels[i], probabilities[i]),
  ]..sort((a, b) => b.probability.compareTo(a.probability));

  return ScanResult(
    imageBytes: scanImageBytes,
    scores: List.unmodifiable(scores),
    uncertainty: Uncertainty.fromProbabilities(probabilities),
    latency: const Duration(milliseconds: 142),
    modelId: modelId,
    modelVersion: modelVersion,
  );
}
