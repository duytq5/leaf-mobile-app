import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/outbox/data/datasources/outbox_local_data_source.dart';

import '../../../../support/outbox_fixtures.dart';

void main() {
  late Directory root;
  late OutboxLocalDataSourceImpl outbox;

  setUp(() {
    root = Directory.systemTemp.createTempSync('outbox_');
    outbox = OutboxLocalDataSourceImpl(directory: () async => root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('a saved capture is listed with its image on disk', () async {
    final saved = await outbox.save(
      pendingCapture(),
      Uint8List.fromList([1, 2, 3, 4]),
    );

    final all = await outbox.list();

    expect(all, [saved]);
    expect(File(saved.imagePath).readAsBytesSync(), [1, 2, 3, 4]);
  });

  test('the list is oldest first', () async {
    final late = pendingCapture(id: 'b');
    final early = pendingCapture(id: 'a');
    await outbox.save(late, Uint8List(1));
    await outbox.save(early, Uint8List(1));

    // Both have the same capture time; the save order decides.
    expect((await outbox.list()).map((c) => c.captureId), ['b', 'a']);
  });

  test('delete removes the record and the image', () async {
    final saved = await outbox.save(pendingCapture(), Uint8List(1));

    await outbox.delete(saved.captureId);

    expect(await outbox.list(), isEmpty);
    expect(File(saved.imagePath).existsSync(), isFalse);
  });

  test('an empty outbox lists nothing', () async {
    expect(await outbox.list(), isEmpty);
  });
}
