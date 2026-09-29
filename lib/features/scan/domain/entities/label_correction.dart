import 'package:equatable/equatable.dart';

/// A label from a person.
///
/// A correction is a stronger signal than an uncertainty score, because it
/// carries the true class. The active learning round reads it first.
class LabelCorrection extends Equatable {
  const LabelCorrection({
    required this.modelId,
    required this.modelVersion,
    required this.predictedLabel,
    required this.correctedLabel,
    required this.submittedAt,
  });

  /// The user chooses this value when no label of the model fits.
  static const notSure = 'not_sure';

  final String modelId;
  final String modelVersion;

  /// The label the model returned.
  final String predictedLabel;

  /// The label the user chose. It is [notSure] when no label fits.
  final String correctedLabel;

  final DateTime submittedAt;

  Map<String, dynamic> toJson() => {
    'model_id': modelId,
    'model_version': modelVersion,
    'predicted_label': predictedLabel,
    'corrected_label': correctedLabel,
    'submitted_at': submittedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    modelId,
    modelVersion,
    predictedLabel,
    correctedLabel,
    submittedAt,
  ];
}
