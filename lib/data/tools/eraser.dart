/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'dart:math';
import 'dart:ui';

import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tools/_tool.dart';
import 'package:sbn/tool_id.dart';

double square(double x) => x * x;
double sqrDistanceBetween(Offset p1, Offset p2) =>
    square(p1.dx - p2.dx) + square(p1.dy - p2.dy);

class Eraser extends Tool {
  static var currentEraser = Eraser(size: stows.lastEraserSize.value);

  static const double sizeMin = 1;
  static const double sizeMax = 25;
  static const double sizeStep = 1;

  double _size;
  double get size => _size;
  set size(double value) {
    final newSize = value.clamp(sizeMin, sizeMax).toDouble();
    if (_size == newSize) return;
    _size = newSize;
    stows.lastEraserSize.value = newSize;
  }

  double get sqrSize => square(size);

  final List<Stroke> _erased = [];
  final Set<Stroke> _replacementStrokes = {};
  Offset? _previousPosition;

  Eraser({double size = 5}) : _size = size;

  @override
  ToolId get toolId => .eraser;

  /// Erases only the portions of [strokes] swept over by the eraser.
  List<Stroke> checkForOverlappingStrokes(
    Offset eraserPos,
    List<Stroke> strokes,
  ) {
    final from = _previousPosition ?? eraserPos;
    final distance = (eraserPos - from).distance;
    final stepLength = max(size * 0.5, 0.5);
    final steps = max(1, (distance / stepLength).ceil());
    for (var step = 1; step <= steps; step++) {
      final position = Offset.lerp(from, eraserPos, step / steps)!;
      _eraseAt(position, strokes);
    }
    _previousPosition = eraserPos;
    return const [];
  }

  /// Returns the original strokes and their surviving replacements.
  EraserResult onDragEnd() {
    final result = EraserResult(
      erasedStrokes: List.of(_erased),
      replacementStrokes: List.of(_replacementStrokes),
    );
    _erased.clear();
    _replacementStrokes.clear();
    _previousPosition = null;
    return result;
  }

  void _eraseAt(Offset position, List<Stroke> strokes) {
    for (var index = strokes.length - 1; index >= 0; index--) {
      final stroke = strokes[index];
      final segments = _remainingSegments(stroke, position, size);
      if (segments == null) continue;

      if (!_replacementStrokes.remove(stroke)) _erased.add(stroke);
      strokes.removeAt(index);

      final replacements = segments
          .where((segment) => segment.length > 1)
          .map((segment) => _strokeFromSegment(stroke, segment))
          .toList();
      strokes.insertAll(index, replacements);
      _replacementStrokes.addAll(replacements);
    }
  }

  static List<List<PointVector>>? _remainingSegments(
    Stroke stroke,
    Offset center,
    double radius,
  ) {
    final points = stroke.pointVectors;
    if (points.isEmpty) return null;
    if (points.length == 1) {
      return sqrDistanceBetween(points.first, center) <= square(radius)
          ? const []
          : null;
    }

    final segments = <List<PointVector>>[];
    var current = <PointVector>[];
    var changed = false;
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final outsideRanges = _outsideRanges(start, end, center, radius);
      if (outsideRanges.length != 1 ||
          outsideRanges.first.$1 != 0 ||
          outsideRanges.first.$2 != 1) {
        changed = true;
      }
      for (final (rangeStart, rangeEnd) in outsideRanges) {
        final first = _interpolate(start, end, rangeStart);
        final last = _interpolate(start, end, rangeEnd);
        if (current.isNotEmpty && !_samePoint(current.last, first)) {
          segments.add(current);
          current = [];
        }
        if (current.isEmpty) current.add(first);
        if (!_samePoint(current.last, last)) current.add(last);
        if (rangeEnd < 1) {
          segments.add(current);
          current = [];
        }
      }
    }
    if (current.isNotEmpty) segments.add(current);
    return changed ? segments : null;
  }

  static List<(double, double)> _outsideRanges(
    PointVector start,
    PointVector end,
    Offset center,
    double radius,
  ) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final fx = start.x - center.dx;
    final fy = start.y - center.dy;
    final a = dx * dx + dy * dy;
    if (a == 0) {
      return fx * fx + fy * fy > radius * radius ? [(0, 1)] : const [];
    }
    final b = 2 * (fx * dx + fy * dy);
    final c = fx * fx + fy * fy - radius * radius;
    final discriminant = b * b - 4 * a * c;
    if (discriminant <= 0) return c > 0 ? [(0, 1)] : const [];

    final root = sqrt(discriminant);
    final enter = ((-b - root) / (2 * a)).clamp(0.0, 1.0).toDouble();
    final exit = ((-b + root) / (2 * a)).clamp(0.0, 1.0).toDouble();
    if (enter == exit) return c > 0 ? [(0, 1)] : const [];
    return [if (enter > 0) (0, enter), if (exit < 1) (exit, 1)];
  }

  static PointVector _interpolate(PointVector a, PointVector b, double t) {
    final pressure = a.pressure == null || b.pressure == null
        ? a.pressure ?? b.pressure
        : a.pressure! + (b.pressure! - a.pressure!) * t;
    return PointVector(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, pressure);
  }

  static bool _samePoint(PointVector a, PointVector b) =>
      a.x == b.x && a.y == b.y && a.pressure == b.pressure;

  static Stroke _strokeFromSegment(Stroke source, List<PointVector> points) =>
      Stroke(
        color: source.color,
        pressureEnabled: source.pressureEnabled,
        options: source.options.copyWith(isComplete: true),
        pageIndex: source.pageIndex,
        page: source.page,
        toolId: source.toolId,
      )..replacePoints(points);
}

/// The atomic change produced by an eraser drag.
class EraserResult {
  const EraserResult({
    required this.erasedStrokes,
    required this.replacementStrokes,
  });

  final List<Stroke> erasedStrokes;
  final List<Stroke> replacementStrokes;
}
