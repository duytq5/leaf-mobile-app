import 'package:equatable/equatable.dart';

/// The answer of the user to the upload agreement.
///
/// The app asks one time. The record then stays on the device.
class ConsentRecord extends Equatable {
  const ConsentRecord({required this.agreed, this.agreedAt});

  /// The state before the user answers.
  static const none = ConsentRecord(agreed: false);

  final bool agreed;

  /// The moment of the agreement. It is null while [agreed] is false.
  final DateTime? agreedAt;

  @override
  List<Object?> get props => [agreed, agreedAt];
}
