import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/class_score.dart';

void main() {
  test('two scores with the same label and probability are equal', () {
    expect(
      const ClassScore('coffee___rust', 0.5),
      const ClassScore('coffee___rust', 0.5),
    );
  });

  test('two scores with a different probability are not equal', () {
    expect(
      const ClassScore('coffee___rust', 0.5) ==
          const ClassScore('coffee___rust', 0.6),
      isFalse,
    );
  });

  test('rounds the probability to a whole percentage', () {
    expect(const ClassScore('a', 0.874).percent, 87);
    expect(const ClassScore('a', 0.875).percent, 88);
    expect(const ClassScore('a', 1.0).percent, 100);
    expect(const ClassScore('a', 0.0).percent, 0);
  });

  test('prints the label and the percentage', () {
    expect(const ClassScore('coffee___rust', 0.87).toString(),
        'coffee___rust: 87.0%');
  });
}
