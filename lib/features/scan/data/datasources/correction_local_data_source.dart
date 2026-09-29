import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/label_correction.dart';

/// Stores the corrections on the device, one JSON object for each line.
///
/// Stage 3 reads this file and uploads it.
abstract class CorrectionLocalDataSource {
  Future<void> append(LabelCorrection correction);

  Future<List<Map<String, dynamic>>> readAll();
}

class CorrectionLocalDataSourceImpl implements CorrectionLocalDataSource {
  CorrectionLocalDataSourceImpl({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  static const fileName = 'corrections.jsonl';

  final Future<Directory> Function() _directory;

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  @override
  Future<void> append(LabelCorrection correction) async {
    final file = await _file();
    await file.writeAsString(
      '${jsonEncode(correction.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> readAll() async {
    final file = await _file();
    if (!file.existsSync()) return [];

    return file
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }
}
