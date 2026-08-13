/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saber/components/canvas/image/editor_image.dart';
import 'package:saber/components/theming/adaptive_icon.dart';
import 'package:saber/components/theming/adaptive_switch.dart';
import 'package:saber/components/theming/saber_theme.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/strings.g.dart';

class CanvasImageDialog extends StatefulWidget {
  const CanvasImageDialog({
    super.key,
    required this.filePath,
    required this.image,
    required this.redrawImage,
    required this.isBackground,
    required this.toggleAsBackground,
    this.singleRow = false,
  });

  final String filePath;
  final EditorImage image;
  final VoidCallback redrawImage;

  final bool isBackground;
  final VoidCallback? toggleAsBackground;

  final bool singleRow;

  @override
  State<CanvasImageDialog> createState() => _CanvasImageDialogState();
}

class _CanvasImageDialogState extends State<CanvasImageDialog> {
  void setInvertible([bool? value]) => setState(() {
    widget.image.invertible = value ?? !widget.image.invertible;
    widget.image.onMiscChange?.call();
    widget.redrawImage();
  });

  Future<void> showCropDialog() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await showDialog<void>(
      context: navigator.context,
      builder: (context) => _ImageCropDialog(
        image: widget.image,
        onApply: (crop) {
          widget.image.cropTo(crop);
          widget.redrawImage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final children = <Widget>[
      MergeSemantics(
        child: _CanvasImageDialogItem(
          onTap: stows.editorAutoInvert.value ? setInvertible : null,
          title: t.editor.imageOptions.invertible,
          child: AdaptiveSwitch(
            value: widget.image.invertible,
            onChanged: stows.editorAutoInvert.value ? setInvertible : null,
            thumbIcon: WidgetStateProperty.all(
              widget.image.invertible
                  ? const Icon(Icons.invert_colors)
                  : const Icon(Icons.invert_colors_off),
            ),
          ),
        ),
      ),
      _CanvasImageDialogItem(
        onTap: widget.image.srcRect.isEmpty
            ? null
            : showCropDialog,
        title: t.editor.imageOptions.crop,
        child: const AdaptiveIcon(
          icon: Icons.crop,
          cupertinoIcon: CupertinoIcons.crop,
        ),
      ),
      _CanvasImageDialogItem(
        onTap: () async {
          final filePathSanitized = widget.filePath.replaceAll(
            RegExp(r'[^a-zA-Z\d]'),
            '_',
          );
          final imageFileName =
              'image$filePathSanitized${widget.image.id}${widget.image.extension}';
          final Uint8List bytes;
          switch (widget.image) {
            case final PdfEditorImage image:
              bytes =
                  image.pdfBytes ??
                  await image.pdfFile?.readAsBytes() ??
                  (throw ArgumentError.value(
                    image,
                    'image',
                    'PDF image has no bytes or file',
                  ));
            case final SvgEditorImage image:
              bytes = switch (image.svgLoader) {
                (final SvgStringLoader loader) => utf8.encode(
                  loader.provideSvg(null),
                ),
                (final SvgFileLoader loader) => await loader.file.readAsBytes(),
                (_) => throw ArgumentError.value(
                  image.svgLoader,
                  'svgLoader',
                  'Unknown SVG loader type',
                ),
              };
            case final PngEditorImage image:
              if (image.imageProvider is MemoryImage) {
                bytes = (image.imageProvider as MemoryImage).bytes;
              } else if (image.imageProvider is FileImage) {
                bytes = await (image.imageProvider as FileImage).file
                    .readAsBytes();
              } else {
                throw ArgumentError.value(
                  image.imageProvider,
                  'imageProvider',
                  'Unknown image provider type',
                );
              }
          }
          if (!context.mounted) return;
          FileManager.exportFile(
            imageFileName,
            bytes,
            isImage: true,
            context: context,
          );
          Navigator.of(context).pop();
        },
        title: t.editor.imageOptions.download,
        child: const AdaptiveIcon(
          icon: Icons.download,
          cupertinoIcon: CupertinoIcons.arrow_down_circle_fill,
        ),
      ),
      _CanvasImageDialogItem(
        onTap: () {
          widget.toggleAsBackground?.call();
          Navigator.of(context).pop();
        },
        title: widget.isBackground
            ? t.editor.imageOptions.removeAsBackground
            : t.editor.imageOptions.setAsBackground,
        child: const AdaptiveIcon(
          icon: Icons.wallpaper,
          cupertinoIcon: CupertinoIcons.photo_fill_on_rectangle_fill,
        ),
      ),
      _CanvasImageDialogItem(
        onTap: () {
          widget.image.onDeleteImage?.call(widget.image);
          widget.redrawImage();
          Navigator.of(context).pop();
        },
        title: t.editor.imageOptions.delete,
        child: const AdaptiveIcon(
          icon: Icons.delete,
          cupertinoIcon: CupertinoIcons.trash_fill,
        ),
      ),
    ];

    final gridView = GridView.count(
      crossAxisCount: widget.singleRow ? children.length : 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      children: children,
    );
    // issues with intrinsic sizes with each type of dialog
    if (platform.isCupertino) {
      return AspectRatio(
        aspectRatio: widget.singleRow ? children.length / 1 : 2,
        child: gridView,
      );
    } else {
      return SizedBox(width: 250, child: gridView);
    }
  }
}

class _ImageCropDialog extends StatefulWidget {
  const _ImageCropDialog({required this.image, required this.onApply});

  final EditorImage image;
  final ValueChanged<Rect> onApply;

  @override
  State<_ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<_ImageCropDialog> {
  static const minimumCropSize = 1.0;

  late Rect crop;
  Rect dragStartCrop = .zero;
  Offset dragStart = .zero;
  _CropDragMode dragMode = .none;

  @override
  void initState() {
    super.initState();
    crop = widget.image.srcRect;
  }

  void startDrag(DragStartDetails details, Size previewSize) {
    dragStart = _toSource(details.localPosition, previewSize);
    dragStartCrop = crop;
    final tolerance = 24 * widget.image.naturalSize.width / previewSize.width;
    final point = dragStart;
    final nearLeft = (point.dx - crop.left).abs() <= tolerance;
    final nearRight = (point.dx - crop.right).abs() <= tolerance;
    final nearTop = (point.dy - crop.top).abs() <= tolerance;
    final nearBottom = (point.dy - crop.bottom).abs() <= tolerance;
    dragMode = switch ((nearLeft, nearRight, nearTop, nearBottom)) {
      (true, _, true, _) => .topLeft,
      (_, true, true, _) => .topRight,
      (true, _, _, true) => .bottomLeft,
      (_, true, _, true) => .bottomRight,
      _ when crop.contains(point) => .move,
      _ => .none,
    };
  }

  void updateDrag(DragUpdateDetails details, Size previewSize) {
    if (dragMode == .none) return;
    final delta = _toSource(details.localPosition, previewSize) - dragStart;
    final bounds = Offset.zero & widget.image.naturalSize;
    Rect next = switch (dragMode) {
      .topLeft => Rect.fromLTRB(
        dragStartCrop.left + delta.dx,
        dragStartCrop.top + delta.dy,
        dragStartCrop.right,
        dragStartCrop.bottom,
      ),
      .topRight => Rect.fromLTRB(
        dragStartCrop.left,
        dragStartCrop.top + delta.dy,
        dragStartCrop.right + delta.dx,
        dragStartCrop.bottom,
      ),
      .bottomLeft => Rect.fromLTRB(
        dragStartCrop.left + delta.dx,
        dragStartCrop.top,
        dragStartCrop.right,
        dragStartCrop.bottom + delta.dy,
      ),
      .bottomRight => Rect.fromLTRB(
        dragStartCrop.left,
        dragStartCrop.top,
        dragStartCrop.right + delta.dx,
        dragStartCrop.bottom + delta.dy,
      ),
      .move => dragStartCrop.shift(delta),
      .none => dragStartCrop,
    };
    if (dragMode == .move) {
      next = next.shift(Offset(
        next.left < bounds.left
            ? bounds.left - next.left
            : next.right > bounds.right
            ? bounds.right - next.right
            : 0,
        next.top < bounds.top
            ? bounds.top - next.top
            : next.bottom > bounds.bottom
            ? bounds.bottom - next.bottom
            : 0,
      ));
    } else {
      next = next.intersect(bounds);
      if (next.width < minimumCropSize || next.height < minimumCropSize) return;
    }
    setState(() => crop = next);
  }

  Offset _toSource(Offset point, Size previewSize) => Offset(
    point.dx * widget.image.naturalSize.width / previewSize.width,
    point.dy * widget.image.naturalSize.height / previewSize.height,
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.editor.imageOptions.crop),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
      child: AspectRatio(
        aspectRatio: widget.image.naturalSize.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewSize = constraints.biggest;
            return GestureDetector(
              key: const Key('imageCropPreview'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => startDrag(details, previewSize),
              onPanUpdate: (details) => updateDrag(details, previewSize),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.image.buildImageWidget(
                    context: context,
                    overrideBoxFit: BoxFit.fill,
                    isBackground: false,
                    invert: false,
                  ),
                  CustomPaint(
                    painter: _CropOverlayPainter(
                      Rect.fromLTRB(
                        crop.left * previewSize.width /
                            widget.image.naturalSize.width,
                        crop.top * previewSize.height /
                            widget.image.naturalSize.height,
                        crop.right * previewSize.width /
                            widget.image.naturalSize.width,
                        crop.bottom * previewSize.height /
                            widget.image.naturalSize.height,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      FilledButton(
        onPressed: () {
          widget.onApply(crop);
          Navigator.pop(context);
        },
        child: Text(t.editor.imageOptions.crop),
      ),
    ],
  );
}

enum _CropDragMode { none, move, topLeft, topRight, bottomLeft, bottomRight }

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter(this.crop);

  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final outside = Path()
      ..addRect(Offset.zero & size)
      ..addRect(crop)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outside, Paint()..color = Colors.black54);
    canvas.drawRect(
      crop,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final point in [
      crop.topLeft,
      crop.topRight,
      crop.bottomLeft,
      crop.bottomRight,
    ]) {
      canvas.drawCircle(point, 7, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) => oldDelegate.crop != crop;
}

class _CanvasImageDialogItem extends StatelessWidget {
  const _CanvasImageDialogItem({
    // ignore: unused_element_parameter
    super.key,
    required this.onTap,
    required this.title,
    required this.child,
  });

  final VoidCallback? onTap;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Material(
      color: colorScheme.primary.withValues(alpha: 0.05),
      borderRadius: const .all(.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const .symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Expanded(child: child),
              Text(title, textAlign: .center),
            ],
          ),
        ),
      ),
    );
  }
}
