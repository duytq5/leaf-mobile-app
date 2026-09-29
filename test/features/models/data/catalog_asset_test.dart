import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// These tests read the asset files from the disk, not through the bundle.
/// They fail when a manifest and its catalog entry disagree.
void main() {
  late Map<String, dynamic> catalog;

  setUpAll(() {
    catalog =
        jsonDecode(File('assets/models/catalog.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  test('the catalog lists the coffee model and the durian model', () {
    final ids = (catalog['models'] as List)
        .map((m) => (m as Map<String, dynamic>)['id'])
        .toList();

    expect(ids, ['coffee_rocole', 'durian']);
  });

  test('every catalog entry has a manifest file', () {
    for (final entry in catalog['models'] as List) {
      final dir = (entry as Map<String, dynamic>)['dir'] as String;

      expect(
        File('$dir/manifest.json').existsSync(),
        isTrue,
        reason: '$dir/manifest.json is absent',
      );
    }
  });

  test('every manifest holds the labels of its trained model', () {
    const expected = {
      'assets/models/coffee': [
        'coffee___healthy',
        'coffee___red_spider_mite',
        'coffee___rust',
      ],
      'assets/models/durian': [
        'Leaf_Algal',
        'Leaf_Blight',
        'Leaf_Colletotrichum',
        'Leaf_Healthy',
        'Leaf_Phomopsis',
        'Leaf_Rhizoctonia',
      ],
    };

    expected.forEach((dir, labels) {
      final manifest =
          jsonDecode(File('$dir/manifest.json').readAsStringSync())
              as Map<String, dynamic>;

      expect(manifest['labels'], labels, reason: '$dir has the wrong labels');
    });
  });

  test('every manifest repeats the evaluation transform of the training code', () {
    for (final entry in catalog['models'] as List) {
      final dir = (entry as Map<String, dynamic>)['dir'] as String;
      final manifest =
          jsonDecode(File('$dir/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      final input = manifest['input'] as Map<String, dynamic>;

      // Resize(292) then CenterCrop(256), from transforms.py with resolution 256.
      expect(input['resize_shortest'], 292, reason: dir);
      expect(input['width'], 256, reason: dir);
      expect(input['height'], 256, reason: dir);
      expect(input['layout'], 'NCHW', reason: dir);
      expect(input['mean'], [0.485, 0.456, 0.406], reason: dir);
      expect(input['std'], [0.229, 0.224, 0.225], reason: dir);
    }
  });
}
