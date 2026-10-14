import 'package:equatable/equatable.dart';

/// One class of the model and its probability.
class ClassScore extends Equatable {
  const ClassScore(this.label, this.probability, {String? code})
    : code = code ?? label;

  /// The name the screen shows.
  final String label;

  /// The class code of the manifest. `POST /v1/captures` keys `probs` by it.
  /// A bundled model has no codes, so its label is its code.
  final String code;

  /// The probability in the range 0.0 to 1.0.
  final double probability;

  /// The probability as a whole percentage, for the screen.
  int get percent => (probability * 100).round();

  @override
  List<Object?> get props => [label, code, probability];

  @override
  String toString() => '$label: ${(probability * 100).toStringAsFixed(1)}%';
}
