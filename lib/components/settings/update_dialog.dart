/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saber/components/settings/update_manager.dart';
import 'package:saber/components/theming/adaptive_alert_dialog.dart';
import 'package:saber/components/theming/adaptive_linear_progress_indicator.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/locales.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatefulWidget {
  /// Creates an update dialog.
  const UpdateDialog({super.key, this.platform, this.loadReleaseData = true});

  /// Overrides the target platform in tests.
  final TargetPlatform? platform;

  /// Whether release metadata should be loaded.
  @visibleForTesting
  final bool loadReleaseData;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  String? directDownloadLink;
  var downloadNotAvailableYet = false;

  var isDownloading = false;

  /// Null if not started yet, or the progress (0.0 to 1.0) of the download.
  final directDownloadProgress = ValueNotifier<double?>(null);

  late final localeCode = LocaleSettings.currentLocale == .en
      ? null
      : LocaleSettings.currentLocale.languageTag;
  String? englishChangelog;
  String? translatedChangelog;
  var showTranslatedChangelog = true;

  @override
  void initState() {
    super.initState();
    if (widget.loadReleaseData) _load();
  }

  @override
  void dispose() {
    directDownloadProgress.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    directDownloadLink = await UpdateManager.getLatestDownloadUrl(
      null,
      widget.platform,
    );
    if (!mounted) return;
    downloadNotAvailableYet =
        UpdateManager.supportsDirectInstaller(_platform) &&
        directDownloadLink == null;

    englishChangelog = await UpdateManager.getChangelog();
    if (!mounted) return;
    translatedChangelog = localeCode == null
        ? null
        : await UpdateManager.getChangelog(localeCode: localeCode!);
    if (!mounted) return;
    showTranslatedChangelog = translatedChangelog != null;
    setState(() {});
  }

  bool get _canRunUpdateAction {
    if (downloadNotAvailableYet) return false;
    if (isDownloading) return false;
    return true;
  }

  TargetPlatform get _platform => widget.platform ?? defaultTargetPlatform;

  bool get _showsDirectInstall =>
      _platform == .windows && UpdateManager.canDirectlyInstall;

  Uri get _distributionPageUri => UpdateManager.distributionPageUriFor(
    _platform,
    appStore: FlavorConfig.appStore,
  );

  Future<void> _handleUpdateAction() async {
    if (!_canRunUpdateAction) return;
    if (_platform == .windows) {
      await _startWindowsInstaller();
      return;
    }
    await _openDistributionPage();
  }

  Future<void> _openDistributionPage() => launchUrl(_distributionPageUri);

  Future<void> _startWindowsInstaller() async {
    assert(_platform == .windows);
    if (!_showsDirectInstall) return;
    final downloadLink = directDownloadLink;
    if (downloadLink == null || !mounted) return;

    setState(() => isDownloading = true);
    await UpdateManager.directlyDownloadUpdate(
      downloadLink,
      onProgress: (progress) {
        directDownloadProgress.value = progress;
      },
    );
    if (mounted) setState(() => isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveAlertDialog(
      title: Text(t.update.updateAvailable),
      content: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          Text(t.update.updateAvailableDescription),

          if (showTranslatedChangelog && translatedChangelog != null)
            Text(translatedChangelog!)
          else if (englishChangelog != null)
            Text(englishChangelog!),

          if (translatedChangelog != null && englishChangelog != null)
            TextButton(
              onPressed: () => setState(() {
                showTranslatedChangelog = !showTranslatedChangelog;
              }),
              child: Text(
                showTranslatedChangelog
                    ? localeNames[localeCode] ?? localeCode!
                    : localeNames['en']!,
              ),
            ),

          if (downloadNotAvailableYet)
            Text(
              t.update.downloadNotAvailableYet,
              style: TextStyle(color: ColorScheme.of(context).error),
            ),

          if (_showsDirectInstall)
            ValueListenableBuilder(
              valueListenable: directDownloadProgress,
              builder: (context, progress, _) {
                if (progress == null) return const SizedBox();
                return Padding(
                  padding: const .only(top: 16.0),
                  child: AdaptiveLinearProgressIndicator(value: progress),
                );
              },
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
          ),
        ),
        CupertinoDialogAction(
          onPressed: _canRunUpdateAction ? _handleUpdateAction : null,
          child: Text(_actionLabel),
        ),
      ],
    );
  }

  String get _actionLabel {
    if (_showsDirectInstall) return t.update.update;
    if (_platform == .linux) return 'Flathub';
    if (_platform == .android && FlavorConfig.appStore.isNotEmpty) {
      return FlavorConfig.appStore;
    }
    return 'Release information';
  }
}
