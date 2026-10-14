import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/pending_capture.dart';

/// Keeps the scans that wait to be sent, one JSON record and one image each,
/// in `outbox/`. A record is written after its image, so a listed record
/// always has its image.
abstract class OutboxLocalDataSource {
  /// Stores [capture] and its image, and returns it with the image path set.
  Future<PendingCapture> save(PendingCapture capture, Uint8List image);

  /// Every stored capture, the oldest first.
  Future<List<PendingCapture>> list();

  Future<Uint8List> readImage(PendingCapture capture);

  Future<void> delete(String captureId);
}

class OutboxLocalDataSourceImpl implements OutboxLocalDataSource {
  OutboxLocalDataSourceImpl({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  Future<Directory> _dir() async {
    final dir = Directory('${(await _directory()).path}/outbox');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<PendingCapture> save(PendingCapture capture, Uint8List image) async {
    final dir = await _dir();
    final extension = capture.contentType == 'image/png' ? 'png' : 'jpg';
    final imageFile = File('${dir.path}/${capture.captureId}.$extension')
      ..writeAsBytesSync(image, flush: true);
    final stored = capture.copyWith(imagePath: imageFile.path);
    File('${dir.path}/${capture.captureId}.json')
        .writeAsStringSync(jsonEncode(stored.toJson()), flush: true);
    return stored;
  }

  @override
  Future<List<PendingCapture>> list() async {
    final records =
        (await _dir())
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort(
            (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
          );

    final captures = <PendingCapture>[];
    for (final file in records) {
      try {
        captures.add(
          PendingCapture.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
          ),
        );
      } on Exception {
        // A damaged record can never be sent.
        file.deleteSync();
      }
    }
    return captures;
  }

  @override
  Future<Uint8List> readImage(PendingCapture capture) =>
      File(capture.imagePath).readAsBytes();

  @override
  Future<void> delete(String captureId) async {
    final dir = await _dir();
    for (final name in [
      '$captureId.json',
      '$captureId.jpg',
      '$captureId.png',
    ]) {
      final file = File('${dir.path}/$name');
      if (file.existsSync()) file.deleteSync();
    }
  }
}
