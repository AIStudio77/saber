/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/settings/update_dialog.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/i18n/strings.g.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('Android UI offers only its configured application store', (
    tester,
  ) async {
    FlavorConfig.setup(appStore: 'Google Play');
    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateDialog(platform: .android, loadReleaseData: false),
      ),
    );

    expect(find.text('Google Play'), findsOneWidget);
    expect(find.text(t.update.update), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('Android without a store offers release information only', (
    tester,
  ) async {
    FlavorConfig.setup();
    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateDialog(platform: .android, loadReleaseData: false),
      ),
    );

    expect(find.text('Release information'), findsOneWidget);
    expect(find.text(t.update.update), findsNothing);
  });

  testWidgets('Linux UI directs users to its distribution channel', (
    tester,
  ) async {
    FlavorConfig.setup();
    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateDialog(platform: .linux, loadReleaseData: false),
      ),
    );

    expect(find.text('Flathub'), findsOneWidget);
    expect(find.text(t.update.update), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
