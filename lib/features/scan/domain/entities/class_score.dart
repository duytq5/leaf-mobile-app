import 'package:equatable/equatable.dart';

/// One class of the model and its probability.
class ClassScore extends Equatable {
  const ClassScore(this.label, this.probability);

  /// The label as the manifest spells it.
  final String label;

  /// The probability in the range 0.0 to 1.0.
  final double probability;

  /// The probability as a whole percentage, for the screen.
  int get percent => (probability * 100).round();

  @override
  List<Object?> get props => [label, probability];

  @override
  String toString() => '$label: ${(probability * 100).toStringAsFixed(1)}%';
}
