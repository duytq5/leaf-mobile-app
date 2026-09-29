import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'class_score.dart';
import 'uncertainty.dart';

/// The result of one run of the model on one image.
class ScanResult extends Equatable {
  const ScanResult({
    required this.imageBytes,
    required this.scores,
    required this.uncertainty,
    required this.latency,
    required this.modelId,
    required this.modelVersion,
  });

  /// The image the user selected, as the picker returned it.
  final Uint8List imageBytes;

  /// Every class of the model, with the highest probability first.
  final List<ClassScore> scores;

  final Uncertainty uncertainty;

  /// The preprocessing and the inference together.
  final Duration latency;

  final String modelId;
  final String modelVersion;

  /// The class the screen shows.
  ClassScore get top => scores.first;

  @override
  List<Object?> get props => [
    scores,
    uncertainty,
    latency,
    modelId,
    modelVersion,
    imageBytes.length,
  ];
}
