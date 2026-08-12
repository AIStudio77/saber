/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:saber/components/settings/update_dialog.dart';
import 'package:saber/components/settings/update_installer.dart' as installer;
import 'package:saber/data/prefs.dart';
import 'package:saber/data/saber_version.dart';
import 'package:saber/data/version.dart' as version;

abstract class UpdateManager {
  static final log = Logger('UpdateManager');

  static final Uri versionUrl = Uri.parse(
    'https://raw.githubusercontent.com/saber-notes/saber/main/lib/data/version.dart',
  );
  static final Uri apiUrl = Uri.parse(
    'https://api.github.com/repos/saber-notes/saber/releases/latest',
  );

  /// The availability of an update.
  static final ValueNotifier<UpdateStatus> status = ValueNotifier(.upToDate);
  static int? newestVersion;

  static var _hasShownUpdateDialog = false;
  static Future<void> showUpdateDialog(
    BuildContext context, {
    bool userTriggered = false,
  }) async {
    if (!userTriggered) {
      if (status.value == .upToDate) {
        // check for updates if not already done
        await stows.shouldCheckForUpdates.waitUntilRead();
        if (!stows.shouldCheckForUpdates.value) return;
        status.value = await _checkForUpdate();
      }
      if (status.value != .updateRecommended) return; // no update available
      if (_hasShownUpdateDialog) return; // already shown
    }

    if (!context.mounted) return;
    _hasShownUpdateDialog = true;
    return await showDialog(
      context: context,
      builder: (context) => const UpdateDialog(),
    );
  }

  static Future<UpdateStatus> _checkForUpdate() async {
    const int currentVersion = version.buildNumber;

    try {
      newestVersion = await getNewestVersion();
    } catch (e, st) {
      log.severe('Failed to check for update: $e', e, st);
      return .upToDate;
    }

    return getUpdateStatus(currentVersion, newestVersion ?? 0);
  }

  /// Returns the version number hosted on GitHub (at [versionUrl]).
  /// If you provide a [latestVersionFile] (i.e. for testing),
  /// it will be used instead of downloading from GitHub.
  @visibleForTesting
  static Future<int?> getNewestVersion([String? latestVersionFile]) async {
    latestVersionFile ??= await _downloadLatestVersionFileFromGitHub();

    // extract the number from the latest version.dart
    final RegExp numberRegex = RegExp(r'(\d+)');
    final RegExpMatch? newestVersionMatch = numberRegex.firstMatch(
      latestVersionFile,
    );
    if (newestVersionMatch == null) return null;

    final int newestVersion = int.tryParse(newestVersionMatch[0] ?? '0') ?? 0;
    if (newestVersion == 0) return null;

    return newestVersion;
  }

  static Future<String> _downloadLatestVersionFileFromGitHub() async {
    // download the latest version.dart
    final http.Response response;
    try {
      response = await http.get(versionUrl);
    } catch (e) {
      throw SocketException('Failed to download version.dart, ${e.toString()}');
    }
    if (response.statusCode >= 400)
      throw SocketException(
        'Failed to download version.dart, HTTP status code ${response.statusCode}',
      );

    return response.body;
  }

  @visibleForTesting
  static UpdateStatus getUpdateStatus(
    int currentVersionNumber,
    int newestVersionNumber,
  ) {
    final currentVersion = SaberVersion.fromNumber(
      currentVersionNumber,
    ).copyWith(revision: 0);
    final newestVersion = SaberVersion.fromNumber(
      newestVersionNumber,
    ).copyWith(revision: 0);

    // Check if we're up to date
    if (newestVersion.buildNumber <= currentVersion.buildNumber) {
      return .upToDate;
    }

    // Check if the update is low priority
    if (!stows.shouldAlwaysAlertForUpdates.value) {
      // Only prompt user every second patch
      if (newestVersion.buildNumber - currentVersion.buildNumber <
          SaberVersion.fromName('0.0.2').buildNumber) {
        return .updateOptional;
      }

      // Don't prompt user when patch version is 0 (e.g. 0.15.0)
      // since there might still be bugs to fix
      if (newestVersion.patch == 0) {
        return .updateOptional;
      }
    }

    return .updateRecommended;
  }

  static Future<String?> getLatestDownloadUrl([
    @visibleForTesting String? apiResponse,
    @visibleForTesting TargetPlatform? platform,
  ]) async {
    platform ??= defaultTargetPlatform;

    if (!supportsDirectInstaller(platform)) return null;

    if (apiResponse == null) {
      final http.Response response;
      try {
        response = await http.get(apiUrl);
      } catch (e) {
        throw const SocketException('Failed to fetch latest release');
      }
      if (response.statusCode >= 400)
        throw SocketException(
          'Failed to fetch latest release, HTTP status code ${response.statusCode}',
        );
      apiResponse = response.body;
    }

    final decodedResponse = jsonDecode(apiResponse);
    if (decodedResponse is! Map<String, dynamic>) return null;
    final assets = decodedResponse['assets'];
    if (assets is! List) return null;
    final RegExp platformFileRegex = UpdateManager.platformFileRegex[platform]!;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = asset['name'];
      if (name is! String || !platformFileRegex.hasMatch(name)) continue;
      final downloadUrl = asset['browser_download_url'];
      if (downloadUrl is! String) continue;
      final uri = Uri.tryParse(downloadUrl);
      if (uri != null && _isTrustedWindowsInstaller(uri)) {
        return uri.toString();
      }
    }
    return null;
  }

  static final Map<TargetPlatform, RegExp> platformFileRegex = {
    // Normal platforms get their updates from app stores, so
    // manual update handling is only needed for Windows.
    .windows: RegExp(r'\.exe$', caseSensitive: false),
  };

  /// Whether [platform] is permitted to discover a direct installer.
  @visibleForTesting
  static bool supportsDirectInstaller(TargetPlatform platform) {
    assert(
      platformFileRegex.keys.every((platform) => platform == .windows),
      'Direct installer patterns must remain Windows-only',
    );
    return platform == .windows;
  }

  /// Whether this process can download and execute a direct installer.
  static bool get canDirectlyInstall =>
      defaultTargetPlatform == .windows &&
      installer.isWindowsInstallerAvailable;

  /// Returns the safe external update destination for a non-Windows platform.
  static Uri externalUpdateUriFor(
    TargetPlatform platform, {
    String appStore = '',
  }) {
    if (platform == .linux) {
      return Uri.parse('https://flathub.org/apps/com.adilhanney.saber');
    }
    if (platform == .android && appStore.toLowerCase().contains('google')) {
      return Uri.parse(
        'https://play.google.com/store/apps/details?id=com.adilhanney.saber',
      );
    }
    if (platform == .android && appStore.toLowerCase().contains('f-droid')) {
      return Uri.parse('https://f-droid.org/packages/com.adilhanney.saber/');
    }
    return Uri.parse('https://github.com/saber-notes/saber/releases');
  }

  /// Downloads the update file from [downloadUrl] and installs it.
  static Future<void> directlyDownloadUpdate(
    String downloadUrl, {
    void Function(double)? onProgress,
  }) async {
    if (!canDirectlyInstall) {
      throw UnsupportedError(
        'Direct installation is available only on Windows',
      );
    }
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || !_isTrustedWindowsInstaller(uri)) {
      throw ArgumentError.value(
        downloadUrl,
        'downloadUrl',
        'Untrusted installer',
      );
    }
    await installer.downloadAndInstall(uri, onProgress: onProgress);
  }

  static bool _isTrustedWindowsInstaller(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == 'github.com' &&
      uri.path.startsWith('/saber-notes/saber/releases/download/') &&
      uri.path.toLowerCase().endsWith('.exe');

  static Future<String?> getChangelog({
    String localeCode = 'en-US',
    @visibleForTesting int? newestVersion,
  }) async {
    newestVersion ??= UpdateManager.newestVersion;
    assert(newestVersion != null);

    final url =
        'https://raw.githubusercontent.com/saber-notes/saber/main/'
        'metadata/$localeCode/changelogs/$newestVersion.txt';
    log.info('Downloading changelog from $url');

    final http.Response response;
    try {
      response = await http.get(Uri.parse(url));
    } catch (e, st) {
      log.severe('Failed to download changelog: $e', e, st);
      return null;
    }
    if (response.statusCode >= 400) return null;

    if (response.body.isEmpty) return null;
    return response.body;
  }
}

enum UpdateStatus {
  /// The app is up to date, or we failed to check for an update.
  upToDate,

  /// An update is available, but the user doesn't need to be notified
  updateOptional,

  /// An update is available and the user should be notified
  updateRecommended,
}
