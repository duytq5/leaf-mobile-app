import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../models/data/models/model_manifest.dart';

/// Thrown when the app cannot convert an image into a tensor.
class PreprocessException implements Exception {
  const PreprocessException(this.message);

  final String message;

  @override
  String toString() => 'PreprocessException: $message';
}

/// Converts image bytes into the tensor that the model expects.
///
/// The steps repeat the evaluation transform of the training code:
///
/// 1. Apply the EXIF orientation. A phone camera writes a rotation flag.
/// 2. Resize the shortest side to [InputSpec.resizeShortest].
/// 3. Crop the centre to [InputSpec.width] by [InputSpec.height].
/// 4. Scale the channel values to the range 0.0 to 1.0.
/// 5. Subtract the mean and divide by the standard deviation.
///
/// The app must repeat all five steps. A different order or an absent step
/// reduces the accuracy without an error message.
class Preprocessor {
  const Preprocessor(this.spec);

  final InputSpec spec;

  /// Converts encoded bytes, for example a JPEG or a PNG file.
  ///
  /// Throws [PreprocessException] when the format is not supported.
  Float32List run(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const PreprocessException('the image format is not supported');
    }
    return runOnImage(decoded);
  }

  /// Converts a decoded image.
  Float32List runOnImage(img.Image source) {
    final upright = img.bakeOrientation(source);
    final resized = _resize(upright);
    final cropped = _centreCrop(resized);
    return _toTensor(cropped);
  }

  img.Image _resize(img.Image source) {
    final shortest = spec.resizeShortest;

    // A null value means the manifest asks for a direct resize. The aspect
    // ratio changes in that case.
    if (shortest == null) {
      return img.copyResize(
        source,
        width: spec.width,
        height: spec.height,
        interpolation: img.Interpolation.linear,
      );
    }

    // Keep the aspect ratio. Torchvision resizes the shortest side.
    final int width;
    final int height;
    if (source.width < source.height) {
      width = shortest;
      height = (source.height * shortest / source.width).round();
    } else {
      height = shortest;
      width = (source.width * shortest / source.height).round();
    }

    return img.copyResize(
      source,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
  }

  img.Image _centreCrop(img.Image source) {
    if (source.width == spec.width && source.height == spec.height) {
      return source;
    }
    if (source.width < spec.width || source.height < spec.height) {
      throw PreprocessException(
        'the image is ${source.width}x${source.height}. '
        'The crop needs ${spec.width}x${spec.height}.',
      );
    }

    return img.copyCrop(
      source,
      x: ((source.width - spec.width) / 2).round(),
      y: ((source.height - spec.height) / 2).round(),
      width: spec.width,
      height: spec.height,
    );
  }

  Float32List _toTensor(img.Image source) {
    final width = spec.width;
    final height = spec.height;
    final tensor = Float32List(3 * width * height);
    final isNchw = spec.layout == 'NCHW';
    final plane = width * height;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = source.getPixel(x, y);
        // The normalized getters give 0.0 to 1.0 for any bit depth.
        final channels = [
          pixel.rNormalized.toDouble(),
          pixel.gNormalized.toDouble(),
          pixel.bNormalized.toDouble(),
        ];

        for (var c = 0; c < 3; c++) {
          final value = (channels[c] - spec.mean[c]) / spec.std[c];
          final index = isNchw
              ? c * plane + y * width + x
              : (y * width + x) * 3 + c;
          tensor[index] = value;
        }
      }
    }

    return tensor;
  }
}
