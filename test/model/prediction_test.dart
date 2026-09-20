import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/src/model/prediction.dart';

const labels = ['coffee___healthy', 'coffee___red_spider_mite', 'coffee___rust'];

Prediction build(List<double> logits) => Prediction.fromLogits(
  logits: logits,
  labels: labels,
  latency: const Duration(milliseconds: 42),
  modelVersion: 'fold-1-best',
);

void main() {
  test('orders the scores with the highest probability first', () {
    final prediction = build([0.1, 3.0, 1.0]);

    expect(prediction.scores.map((s) => s.label), [
      'coffee___red_spider_mite',
      'coffee___rust',
      'coffee___healthy',
    ]);
  });

  test('reports the top class', () {
    final prediction = build([5.0, 0.0, 0.0]);

    expect(prediction.top.label, 'coffee___healthy');
    expect(prediction.top.probability, greaterThan(0.9));
  });

  test('keeps the label paired with its own logit', () {
    // The rare class has the highest logit. The pairing must survive the sort.
    final prediction = build([1.0, 9.0, 2.0]);

    expect(prediction.top.label, 'coffee___red_spider_mite');
  });

  test('produces probabilities that sum to one', () {
    final prediction = build([2.0, -1.0, 0.5]);

    final total = prediction.scores
        .map((s) => s.probability)
        .reduce((a, b) => a + b);
    expect(total, closeTo(1.0, 1e-12));
  });

  test('carries the latency and the model version', () {
    final prediction = build([1.0, 1.0, 1.0]);

    expect(prediction.latency.inMilliseconds, 42);
    expect(prediction.modelVersion, 'fold-1-best');
  });

  test('computes the uncertainty from the same distribution', () {
    final confident = build([10.0, 0.0, 0.0]);
    final unsure = build([1.0, 1.0, 1.0]);

    expect(unsure.uncertainty.entropy, greaterThan(confident.uncertainty.entropy));
    expect(unsure.uncertainty.margin, lessThan(confident.uncertainty.margin));
  });

  test('rejects a logit count that differs from the label count', () {
    expect(
      () => Prediction.fromLogits(
        logits: [1.0, 2.0],
        labels: labels,
        latency: Duration.zero,
        modelVersion: 'v',
      ),
      throwsArgumentError,
    );
  });

  test('returns an unmodifiable score list', () {
    final prediction = build([1.0, 2.0, 3.0]);

    expect(
      () => prediction.scores.add(const ClassScore('x', 0.0)),
      throwsUnsupportedError,
    );
  });
}
