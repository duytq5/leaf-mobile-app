import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../domain/entities/image_source_kind.dart';

/// Asks the operating system for a photo.
abstract class ImagePickerDataSource {
  /// Returns null when the user cancels.
  Future<Uint8List?> pick(ImageSourceKind source);
}

class ImagePickerDataSourceImpl implements ImagePickerDataSource {
  ImagePickerDataSourceImpl([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(ImageSourceKind source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        ImageSourceKind.camera => ImageSource.camera,
        ImageSourceKind.gallery => ImageSource.gallery,
      },
      // A full size photo costs memory on a low performance device. The model
      // crops to 256 pixels, so a longer side of 1600 loses nothing.
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
