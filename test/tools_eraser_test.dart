/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/data/tools/eraser.dart';
import 'package:sbn/has_size.dart';

final _options = StrokeOptions(
  size: 1, // small size so we have more precision in test
);
const _eraserPos = Offset(50, 50);

void main() {
  test('eraser removes only the touched portion of a stroke', () {
    final eraser = Eraser(size: 10);

    final List<Stroke> strokesToErase = [
      // center
      _strokeWithPoint(_eraserPos),

      // 1 size downwards from center
      _strokeWithPoint(_eraserPos + const Offset(0, 1) * eraser.size),

      // 1 size right from center
      _strokeWithPoint(_eraserPos + const Offset(1, 0) * eraser.size),

      // 1 size diagonally from center
      _strokeWithPoint(_eraserPos + const Offset(1, 1) * sqrt(eraser.size)),

      // 0.5 sizes right from center
      _strokeWithPoint(_eraserPos + const Offset(0.5, 0) * eraser.size),

      // straight line that passes through center
      _strokeWithPoint(_eraserPos + const Offset(-20, -20) * eraser.size)
        ..addPoint(_eraserPos + const Offset(20, 20) * eraser.size)
        ..addPoint(_eraserPos + const Offset(20, 20) * eraser.size),
    ];

    final List<Stroke> strokesToKeep = [
      // > 1 size downwards from center
      _strokeWithPoint(_eraserPos + const Offset(0, 1.1) * eraser.size),

      // > 1 size right from center
      _strokeWithPoint(_eraserPos + const Offset(1.1, 0) * eraser.size),

      // > 1 size diagonally from center
      _strokeWithPoint(_eraserPos + const Offset(1, 1) * eraser.size),

      // 2 sizes right from center
      _strokeWithPoint(_eraserPos + const Offset(2, 0) * eraser.size),
    ];

    final strokes = <Stroke>[...strokesToErase, ...strokesToKeep];
    eraser.checkForOverlappingStrokes(_eraserPos, strokes);
    final result = eraser.onDragEnd();

    expect(result.erasedStrokes.length, strokesToErase.length);
    expect(strokes, containsAll(strokesToKeep));
  });

  test('eraser splits a line and interpolates its boundary points', () {
    final eraser = Eraser(size: 10);
    final stroke = _strokeWithPoint(const Offset(0, 50))
      ..addPoint(const Offset(100, 50), 1);
    final strokes = [stroke];

    eraser.checkForOverlappingStrokes(_eraserPos, strokes);
    final result = eraser.onDragEnd();

    expect(strokes, hasLength(2));
    expect(strokes.first.pointVectors.last.x, closeTo(40, 0.001));
    expect(strokes.last.pointVectors.first.x, closeTo(60, 0.001));
    expect(result.erasedStrokes, hasLength(1));
    expect(result.replacementStrokes, hasLength(2));
  });

  test('fast eraser movement clears the complete swept path', () {
    final eraser = Eraser(size: 5);
    final stroke = _strokeWithPoint(const Offset(50, 0))
      ..addPoint(const Offset(50, 100));
    final strokes = [stroke];

    eraser.checkForOverlappingStrokes(const Offset(0, 50), strokes);
    eraser.checkForOverlappingStrokes(const Offset(100, 50), strokes);

    expect(strokes, hasLength(2));
  });
}

Stroke _strokeWithPoint(Offset point) => Stroke(
  color: Stroke.defaultColor,
  pressureEnabled: Stroke.defaultPressureEnabled,
  options: _options,
  pageIndex: 0,
  page: const HasSize(Size(100, 100)),
  toolId: .fountainPen,
)..addPoint(point);
