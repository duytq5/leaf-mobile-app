import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:leaf_disease_mobile/features/models/domain/entities/model_manifest.dart';
import 'package:leaf_disease_mobile/features/scan/data/datasources/preprocessor.dart';

const mean = [0.485, 0.456, 0.406];
const std = [0.229, 0.224, 0.225];

InputSpec spec({
  int width = 256,
  int height = 256,
  String layout = 'NCHW',
  int? resizeShortest,
}) => InputSpec(
  width: width,
  height: height,
  layout: layout,
  mean: mean,
  std: std,
  resizeShortest: resizeShortest,
);

img.Image solid(int width, int height, img.Color color) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: color);
  return image;
}

/// The expected value of one channel after the scale and the normalization.
double expected(double raw, int channel) => (raw - mean[channel]) / std[channel];

void main() {
  group('layout', () {
    test('writes NCHW as three separate planes', () {
      final red = solid(256, 256, img.ColorRgb8(255, 0, 0));

      final tensor = Preprocessor(spec()).runOnImage(red);

      const plane = 256 * 256;
      expect(tensor, hasLength(3 * plane));
      expect(tensor[0], closeTo(expected(1.0, 0), 1e-6));
      expect(tensor[plane], closeTo(expected(0.0, 1), 1e-6));
      expect(tensor[2 * plane], closeTo(expected(0.0, 2), 1e-6));
    });

    test('writes NHWC as interleaved channels', () {
      final red = solid(256, 256, img.ColorRgb8(255, 0, 0));

      final tensor = Preprocessor(
        spec(layout: 'NHWC'),
      ).runOnImage(red);

      expect(tensor[0], closeTo(expected(1.0, 0), 1e-6));
      expect(tensor[1], closeTo(expected(0.0, 1), 1e-6));
      expect(tensor[2], closeTo(expected(0.0, 2), 1e-6));
    });

    test('normalizes a mid grey correctly', () {
      final grey = solid(256, 256, img.ColorRgb8(128, 128, 128));

      final tensor = Preprocessor(spec()).runOnImage(grey);

      final raw = 128 / 255;
      expect(tensor[0], closeTo(expected(raw, 0), 1e-4));
    });
  });

  group('resize and crop', () {
    test('keeps the aspect ratio and takes the centre', () {
      // A blue image of 512 by 512 with a red square of 256 in the centre.
      final image = solid(512, 512, img.ColorRgb8(0, 0, 255));
      img.fillRect(
        image,
        x1: 128,
        y1: 128,
        x2: 383,
        y2: 383,
        color: img.ColorRgb8(255, 0, 0),
      );

      // The shortest side stays 512. The centre crop takes the red square.
      final tensor = Preprocessor(
        spec(resizeShortest: 512),
      ).runOnImage(image);

      const plane = 256 * 256;
      // Every pixel of the crop is red.
      expect(tensor[0], closeTo(expected(1.0, 0), 1e-6));
      expect(tensor[plane - 1], closeTo(expected(1.0, 0), 1e-6));
      expect(tensor[2 * plane], closeTo(expected(0.0, 2), 1e-6));
    });

    test('handles a wide image without an error', () {
      final wide = solid(600, 300, img.ColorRgb8(10, 20, 30));

      // The shortest side is 300. It becomes 292. The width becomes 584.
      final tensor = Preprocessor(
        spec(resizeShortest: 292),
      ).runOnImage(wide);

      expect(tensor, hasLength(3 * 256 * 256));
    });

    test('handles a tall image without an error', () {
      final tall = solid(300, 900, img.ColorRgb8(10, 20, 30));

      final tensor = Preprocessor(
        spec(resizeShortest: 292),
      ).runOnImage(tall);

      expect(tensor, hasLength(3 * 256 * 256));
    });

    test('resizes straight to the crop size when resize_shortest is absent', () {
      final wide = solid(1000, 200, img.ColorRgb8(255, 255, 255));

      final tensor = Preprocessor(spec()).runOnImage(wide);

      expect(tensor, hasLength(3 * 256 * 256));
      expect(tensor[0], closeTo(expected(1.0, 0), 1e-6));
    });
  });

  group('run on encoded bytes', () {
    test('decodes a PNG file', () {
      final png = Uint8List.fromList(
        img.encodePng(solid(400, 400, img.ColorRgb8(0, 255, 0))),
      );

      final tensor = Preprocessor(spec(resizeShortest: 292)).run(png);

      const plane = 256 * 256;
      expect(tensor, hasLength(3 * plane));
      expect(tensor[plane], closeTo(expected(1.0, 1), 1e-6));
    });

    test('rejects bytes that are not an image', () {
      final garbage = Uint8List.fromList(List.filled(64, 7));

      expect(
        () => Preprocessor(spec()).run(garbage),
        throwsA(isA<PreprocessException>()),
      );
    });
  });
}
