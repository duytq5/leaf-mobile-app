import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/src/model/uncertainty.dart';

void main() {
  group('softmax', () {
    test('returns probabilities that sum to one', () {
      final probabilities = softmax([2.0, 1.0, 0.1, -3.0]);

      final total = probabilities.reduce((a, b) => a + b);
      expect(total, closeTo(1.0, 1e-12));
    });

    test('returns a uniform distribution for equal logits', () {
      final probabilities = softmax([1.5, 1.5, 1.5, 1.5]);

      for (final p in probabilities) {
        expect(p, closeTo(0.25, 1e-12));
      }
    });

    test('stays finite for a large logit', () {
      final probabilities = softmax([1000.0, 999.0, -1000.0]);

      for (final p in probabilities) {
        expect(p.isFinite, isTrue);
      }
      expect(probabilities.reduce((a, b) => a + b), closeTo(1.0, 1e-12));
    });

    test('keeps the order of the logits', () {
      final probabilities = softmax([0.1, 3.0, 1.0]);

      expect(probabilities[1], greaterThan(probabilities[2]));
      expect(probabilities[2], greaterThan(probabilities[0]));
    });

    test('rejects an empty list', () {
      expect(() => softmax([]), throwsArgumentError);
    });
  });

  group('Uncertainty.fromProbabilities', () {
    test('reports maximum uncertainty for a uniform distribution', () {
      final scores = Uncertainty.fromProbabilities([0.25, 0.25, 0.25, 0.25]);

      // The entropy of n equal classes is ln(n).
      expect(scores.entropy, closeTo(math.log(4), 1e-12));
      expect(scores.leastConfidence, closeTo(0.75, 1e-12));
      expect(scores.margin, closeTo(0.0, 1e-12));
    });

    test('reports no uncertainty for a confident prediction', () {
      final scores = Uncertainty.fromProbabilities([1.0, 0.0, 0.0]);

      expect(scores.entropy, closeTo(0.0, 1e-12));
      expect(scores.leastConfidence, closeTo(0.0, 1e-12));
      expect(scores.margin, closeTo(1.0, 1e-12));
    });

    test('takes the margin from the two highest probabilities', () {
      // The two highest values are 0.5 and 0.3. They are not adjacent.
      final scores = Uncertainty.fromProbabilities([0.5, 0.2, 0.3]);

      expect(scores.margin, closeTo(0.2, 1e-12));
      expect(scores.leastConfidence, closeTo(0.5, 1e-12));
    });

    test('reports a full margin for a single class', () {
      final scores = Uncertainty.fromProbabilities([1.0]);

      expect(scores.margin, closeTo(1.0, 1e-12));
      expect(scores.leastConfidence, closeTo(0.0, 1e-12));
    });

    test('ignores a zero probability in the entropy', () {
      final scores = Uncertainty.fromProbabilities([0.5, 0.5, 0.0]);

      expect(scores.entropy.isFinite, isTrue);
      expect(scores.entropy, closeTo(math.log(2), 1e-12));
    });

    test('ranks an uncertain prediction above a confident one', () {
      final uncertain = Uncertainty.fromProbabilities([0.34, 0.33, 0.33]);
      final confident = Uncertainty.fromProbabilities([0.90, 0.05, 0.05]);

      expect(uncertain.entropy, greaterThan(confident.entropy));
      expect(uncertain.leastConfidence, greaterThan(confident.leastConfidence));
      expect(uncertain.margin, lessThan(confident.margin));
    });

    test('rejects an empty list', () {
      expect(() => Uncertainty.fromProbabilities([]), throwsArgumentError);
    });

    test('writes the server field names in toJson', () {
      final json = Uncertainty.fromProbabilities([0.7, 0.3]).toJson();

      expect(json.keys, containsAll(['entropy', 'least_confidence', 'margin']));
    });
  });
}
