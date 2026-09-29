import '../../domain/entities/consent_record.dart';

/// The stored shape of a [ConsentRecord].
class ConsentRecordModel extends ConsentRecord {
  const ConsentRecordModel({required super.agreed, super.agreedAt});

  factory ConsentRecordModel.fromJson(Map<String, dynamic> json) {
    final raw = json['agreed_at'];
    return ConsentRecordModel(
      agreed: json['agreed'] == true,
      agreedAt: raw is String ? DateTime.tryParse(raw) : null,
    );
  }

  factory ConsentRecordModel.fromEntity(ConsentRecord record) =>
      ConsentRecordModel(agreed: record.agreed, agreedAt: record.agreedAt);

  Map<String, dynamic> toJson() => {
    'agreed': agreed,
    if (agreedAt != null) 'agreed_at': agreedAt!.toIso8601String(),
  };
}
