/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'package:flutter/material.dart';
import 'package:saber/data/extensions/axis_extensions.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tools/eraser.dart';
import 'package:saber/i18n/strings.g.dart';

/// Controls the diameter of the area eraser.
class EraserModal extends StatefulWidget {
  const EraserModal({super.key, required this.getTool});

  final Eraser Function() getTool;

  @override
  State<EraserModal> createState() => _EraserModalState();
}

class _EraserModalState extends State<EraserModal> {
  @override
  Widget build(BuildContext context) {
    final eraser = widget.getTool();
    final axis = stows.editorToolbarAlignment.value.axis.opposite;
    final slider = Slider(
      min: Eraser.sizeMin,
      max: Eraser.sizeMax,
      divisions: ((Eraser.sizeMax - Eraser.sizeMin) / Eraser.sizeStep).round(),
      value: eraser.size,
      label: eraser.size.round().toString(),
      onChanged: (value) => setState(() => eraser.size = value),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${t.editor.penOptions.size}: ${eraser.size.round()}'),
          SizedBox(
            width: axis == Axis.horizontal ? 150 : 48,
            height: axis == Axis.vertical ? 150 : 48,
            child: axis == Axis.horizontal
                ? slider
                : RotatedBox(quarterTurns: 1, child: slider),
          ),
        ],
      ),
    );
  }
}
