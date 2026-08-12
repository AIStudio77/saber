/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'dart:io';

/// Installer execution is available only when running on Windows.
bool get isAvailable => Platform.isWindows;

/// Downloads and executes a trusted Saber Windows installer.
Future<void> downloadAndInstall(
  Uri downloadUri, {
  void Function(double)? onProgress,
}) async {
  if (!Platform.isWindows) {
    throw UnsupportedError('Windows installer updates are unavailable');
  }
  if (!_isTrustedInstaller(downloadUri)) {
    throw ArgumentError.value(
      downloadUri,
      'downloadUri',
      'Untrusted installer',
    );
  }

  final client = HttpClient();
  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}'
    '${downloadUri.pathSegments.last}',
  );
  try {
    final request = await client.getUrl(downloadUri);
    final response = await request.close();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw HttpException(
        'Installer download failed with HTTP ${response.statusCode}',
        uri: downloadUri,
      );
    }

    final sink = file.openWrite();
    var receivedBytes = 0;
    await for (final bytes in response) {
      sink.add(bytes);
      receivedBytes += bytes.length;
      if (response.contentLength > 0) {
        onProgress?.call(receivedBytes / response.contentLength);
      }
    }
    await sink.close();
    await Process.start(file.path, const []);
  } finally {
    client.close();
  }
}

bool _isTrustedInstaller(Uri uri) =>
    uri.scheme == 'https' &&
    uri.host == 'github.com' &&
    uri.path.startsWith('/saber-notes/saber/releases/download/') &&
    uri.path.toLowerCase().endsWith('.exe');
