/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/canvas/_asset_cache.dart';
import 'package:saber/components/canvas/image/editor_image.dart';

void main() {
  test('crop keeps source in bounds and updates destination non-destructively', () {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final image = PngEditorImage(
      id: 1,
      assetCache: AssetCache(),
      extension: '.jpg',
      imageProvider: MemoryImage(bytes),
      pageIndex: 0,
      pageSize: const Size(500, 500),
      naturalSize: const Size(200, 100),
      srcRect: const Rect.fromLTWH(0, 0, 200, 100),
      dstRect: const Rect.fromLTWH(20, 30, 400, 200),
      onMoveImage: null,
      onDeleteImage: null,
      onMiscChange: null,
    );
    ImageRectChange? change;
    image.onCropImage = (_, value) => change = value;

    image.cropTo(const Rect.fromLTRB(-10, 10, 150, 90));

    expect(image.srcRect, const Rect.fromLTRB(0, 10, 150, 90));
    expect(image.dstRect, const Rect.fromLTWH(20, 50, 300, 160));
    expect((image.imageProvider as MemoryImage).bytes, bytes);
    expect(change?.previousSource, const Rect.fromLTWH(0, 0, 200, 100));
  });
}
