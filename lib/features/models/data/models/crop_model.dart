import '../../domain/entities/crop.dart';

/// Reads one crop of `GET /v1/crops`.
Crop cropFromJson(Map<String, dynamic> json) => Crop(
  code: json['code'] as String,
  displayName: json['display_name'] as String,
  description: json['description'] as String?,
  datasets: [
    for (final raw in json['datasets'] as List)
      CropDataset(
        name: (raw as Map<String, dynamic>)['name'] as String,
        displayName: raw['display_name'] as String,
        version: raw['version'] as int,
      ),
  ],
);
