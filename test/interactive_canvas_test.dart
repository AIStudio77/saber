/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/canvas/interactive_canvas.dart';

void main() {
  testWidgets('stationary additional contacts do not pan the canvas', (
    tester,
  ) async {
    final controller = TransformationController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: InteractiveCanvasViewer(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            transformationController: controller,
            child: const SizedBox.square(dimension: 1000),
          ),
        ),
      ),
    );

    final firstContact = await tester.startGesture(const Offset(100, 100));
    await tester.pump();
    final beforeSecondContact = controller.value.clone();

    final secondContact = await tester.startGesture(const Offset(300, 100));
    await tester.pump();
    expect(controller.value.storage, beforeSecondContact.storage);

    await secondContact.up();
    await tester.pump();
    expect(controller.value.storage, beforeSecondContact.storage);
    await firstContact.up();
  });
}
