/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// The result of importing one photo from the native camera.
typedef CameraPhoto = ({Uint8List bytes, String extension});

/// A callback that launches the native camera and returns its temporary file.
typedef CameraCapture = Future<XFile?> Function();

/// Acquires photos through the platform camera without retaining temporary files.
class CameraPhotoPicker {
  /// Creates a picker, optionally replacing the native capture for tests.
  CameraPhotoPicker({CameraCapture? capture})
    : _capture = capture ??
          (() => ImagePicker().pickImage(source: ImageSource.camera));

  static const _supportedExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.tif', '.tiff', '.bmp', '.webp',
  };

  final CameraCapture _capture;

  /// Launches the camera and reads the captured temporary file exactly once.
  ///
  /// Returns `null` when the user cancels. The plugin owns the temporary file;
  /// this method neither copies nor retains it.
  Future<CameraPhoto?> takePhoto() async {
    final file = await _capture();
    if (file == null) return null;

    final extension = p.extension(file.path).toLowerCase();
    return (
      bytes: await file.readAsBytes(),
      extension: _supportedExtensions.contains(extension) ? extension : '.jpg',
    );
  }
}
