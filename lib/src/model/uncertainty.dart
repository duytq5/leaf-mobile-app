import 'dart:math' as math;

/// Converts raw model outputs into probabilities.
///
/// The function subtracts the maximum logit before the exponential. This keeps
/// the result stable when a logit is large.
///
/// Throws [ArgumentError] when [logits] is empty.
List<double> softmax(List<double> logits) {
  if (logits.isEmpty) {
    throw ArgumentError.value(logits, 'logits', 'must not be empty');
  }
  final maxLogit = logits.reduce(math.max);
  final exponentials = logits.map((l) => math.exp(l - maxLogit)).toList();
  final total = exponentials.reduce((a, b) => a + b);
  return exponentials.map((e) => e / total).toList(growable: false);
}

/// The acquisition scores for one prediction.
///
/// The server reads these scores to rank the unlabelled pool. Each score is a
/// different acquisition function from the thesis. The app computes all three,
/// so a later round can change the acquisition function without a new app
/// release.
class Uncertainty {
  const Uncertainty({
    required this.entropy,
    required this.leastConfidence,
    required this.margin,
  });

  /// Builds the scores from a probability distribution.
  ///
  /// [probabilities] must sum to about 1.0. Use [softmax] on raw logits first.
  ///
  /// Throws [ArgumentError] when [probabilities] is empty.
  factory Uncertainty.fromProbabilities(List<double> probabilities) {
    if (probabilities.isEmpty) {
      throw ArgumentError.value(
        probabilities,
        'probabilities',
        'must not be empty',
      );
    }

    var entropy = 0.0;
    for (final p in probabilities) {
      // A zero probability contributes zero to the entropy.
      if (p > 0) {
        entropy -= p * math.log(p);
      }
    }

    final sorted = [...probabilities]..sort((a, b) => b.compareTo(a));
    final top = sorted.first;
    // One class means the model has no alternative to compare against.
    final margin = sorted.length == 1 ? 1.0 : top - sorted[1];

    return Uncertainty(
      entropy: entropy,
      leastConfidence: 1.0 - top,
      margin: margin,
    );
  }

  /// The predictive entropy in nats. A high value means low certainty.
  final double entropy;

  /// One minus the highest probability. A high value means low certainty.
  final double leastConfidence;

  /// The difference between the two highest probabilities. A low value means
  /// low certainty.
  final double margin;

  Map<String, dynamic> toJson() => {
    'entropy': entropy,
    'least_confidence': leastConfidence,
    'margin': margin,
  };

  @override
  String toString() =>
      'Uncertainty(entropy: $entropy, leastConfidence: $leastConfidence, '
      'margin: $margin)';
}
