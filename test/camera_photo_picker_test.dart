/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saber/pages/editor/camera_photo_picker.dart';

void main() {
  test('cancellation returns null', () async {
    final picker = CameraPhotoPicker(capture: () async => null);

    expect(await picker.takePhoto(), isNull);
  });

  test('capture preserves bytes and normalizes the extension', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final picker = CameraPhotoPicker(
      capture: () async => XFile.fromData(bytes, path: '/tmp/photo.JPEG'),
    );

    final photo = await picker.takePhoto();

    expect(photo?.bytes, bytes);
    expect(photo?.extension, '.jpeg');
  });

  test('unsupported or missing extensions fall back to jpg', () async {
    final picker = CameraPhotoPicker(
      capture: () async => XFile.fromData(
        Uint8List.fromList([5, 6]),
        path: '/tmp/captured-photo',
      ),
    );

    expect((await picker.takePhoto())?.extension, '.jpg');
  });
}
