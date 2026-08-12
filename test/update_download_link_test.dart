/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/settings/update_manager.dart';
import 'package:saber/data/flavor_config.dart';

void main() {
  group('getLatestDownloadUrl', () {
    late final String apiResponse;
    setUpAll(() async {
      FlavorConfig.setup();
      final file = File('test/samples/github_releases_api.json');
      apiResponse = await file.readAsString();
    });

    test('on iOS', () async {
      final url = await UpdateManager.getLatestDownloadUrl(apiResponse, .iOS);
      expect(url, isNull);
    });

    test('on macOS', () async {
      final url = await UpdateManager.getLatestDownloadUrl(apiResponse, .macOS);
      expect(url, isNull);
    });

    test('on Windows', () async {
      final url = await UpdateManager.getLatestDownloadUrl(
        apiResponse,
        .windows,
      );
      expect(url, isNotNull);
      expect(url, startsWith('http'));
      expect(url, endsWith('.exe'));
    });

    test('on Linux', () async {
      final url = await UpdateManager.getLatestDownloadUrl(apiResponse, .linux);
      expect(url, isNull);
    });

    test('on Android', () async {
      final url = await UpdateManager.getLatestDownloadUrl(
        apiResponse,
        .android,
      );
      expect(url, isNull);
    });

    test('malicious Android response cannot enable an installer', () async {
      const maliciousResponse = '''
        {"assets":[{"name":"Saber.exe","browser_download_url":"https://evil.example/Saber.exe"}]}
      ''';
      final url = await UpdateManager.getLatestDownloadUrl(
        maliciousResponse,
        .android,
      );
      expect(url, isNull);
      expect(UpdateManager.supportsDirectInstaller(.android), isFalse);
    });

    test('malicious Linux response cannot enable an installer', () async {
      const maliciousResponse = '''
        {"assets":[{"name":"Saber.exe","browser_download_url":"https://evil.example/Saber.exe"}]}
      ''';
      final url = await UpdateManager.getLatestDownloadUrl(
        maliciousResponse,
        .linux,
      );
      expect(url, isNull);
      expect(UpdateManager.supportsDirectInstaller(.linux), isFalse);
    });

    test(
      'Windows rejects an executable hosted outside trusted releases',
      () async {
        const maliciousResponse = '''
        {"assets":[{"name":"Saber.exe","browser_download_url":"https://evil.example/Saber.exe"}]}
      ''';
        final url = await UpdateManager.getLatestDownloadUrl(
          maliciousResponse,
          .windows,
        );
        expect(url, isNull);
      },
    );
  });

  test(
    'direct installation is unavailable on this Linux test process',
    () async {
      expect(Platform.isLinux, isTrue);
      expect(UpdateManager.canDirectlyInstall, isFalse);
      await expectLater(
        UpdateManager.directlyDownloadUpdate(
          'https://github.com/saber-notes/saber/releases/download/v1/Saber.exe',
        ),
        throwsUnsupportedError,
      );
    },
  );

  test('Android redirects cannot resolve to executable downloads', () {
    for (final store in ['', 'Google Play', 'F-Droid']) {
      final uri = UpdateManager.externalUpdateUriFor(
        .android,
        appStore: store,
      );
      expect(uri.scheme, 'https');
      expect(uri.path.toLowerCase(), isNot(endsWith('.exe')));
      expect(uri.path.toLowerCase(), isNot(endsWith('.apk')));
    }
  });

  test('Linux redirect resolves only to its distribution channel', () {
    final uri = UpdateManager.externalUpdateUriFor(.linux);
    expect(uri.host, 'flathub.org');
    expect(uri.path.toLowerCase(), isNot(endsWith('.exe')));
    expect(uri.path.toLowerCase(), isNot(endsWith('.appimage')));
  });
}
