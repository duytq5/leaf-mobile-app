import 'uncertainty.dart';

/// One class and its probability.
class ClassScore {
  const ClassScore(this.label, this.probability);

  final String label;

  /// The probability in the range 0.0 to 1.0.
  final double probability;

  @override
  String toString() => '$label: ${(probability * 100).toStringAsFixed(1)}%';
}

/// The complete result for one image.
class Prediction {
  const Prediction({
    required this.scores,
    required this.uncertainty,
    required this.latency,
    required this.modelVersion,
  });

  /// Builds a result from the raw model output.
  ///
  /// [logits] and [labels] must have the same length. The scores come back in
  /// order, with the highest probability first.
  ///
  /// Throws [ArgumentError] when the lengths are different.
  factory Prediction.fromLogits({
    required List<double> logits,
    required List<String> labels,
    required Duration latency,
    required String modelVersion,
  }) {
    if (logits.length != labels.length) {
      throw ArgumentError(
        'the model returns ${logits.length} values but the manifest lists '
        '${labels.length} labels',
      );
    }

    final probabilities = softmax(logits);
    final scores = <ClassScore>[
      for (var i = 0; i < labels.length; i++)
        ClassScore(labels[i], probabilities[i]),
    ]..sort((a, b) => b.probability.compareTo(a.probability));

    return Prediction(
      scores: List.unmodifiable(scores),
      uncertainty: Uncertainty.fromProbabilities(probabilities),
      latency: latency,
      modelVersion: modelVersion,
    );
  }

  /// Every class, with the highest probability first.
  final List<ClassScore> scores;

  final Uncertainty uncertainty;

  /// The time of the preprocessing and the inference together.
  final Duration latency;

  final String modelVersion;

  /// The class with the highest probability.
  ClassScore get top => scores.first;
}
