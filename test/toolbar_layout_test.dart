/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/toolbar/toolbar.dart';
import 'package:saber/data/tools/pen.dart';

void main() {
  testWidgets('lays out in a column with unbounded incoming height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Expanded(child: SizedBox()),
              Toolbar(
                readOnly: false,
                setTool: (_) {},
                currentTool: Pen.currentPen,
                setColor: (_) {},
                quillFocus: ValueNotifier<QuillStruct?>(null),
                textEditing: false,
                toggleTextEditing: () {},
                undo: () {},
                isUndoPossible: false,
                redo: () {},
                isRedoPossible: false,
                toggleFingerDrawing: () {},
                pickPhoto: () {},
                takePhoto: () {},
                showCameraButton: false,
                paste: () {},
                duplicateSelection: () {},
                deleteSelection: () {},
                exportAsSba: null,
                exportAsPdf: null,
                exportAsPng: null,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Toolbar), findsOneWidget);
  });
}
