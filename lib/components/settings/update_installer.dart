/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'update_installer_stub.dart'
    if (dart.library.io) 'update_installer_windows.dart' as implementation;

/// Progress callbacks used while a Windows installer is downloaded.
typedef InstallerProgressCallback = void Function(double progress);

/// Whether this build can download and execute a Windows installer.
bool get isWindowsInstallerAvailable => implementation.isAvailable;

/// Downloads and executes a trusted Saber Windows installer.
Future<void> downloadAndInstall(
  Uri downloadUri, {
  InstallerProgressCallback? onProgress,
}) => implementation.downloadAndInstall(downloadUri, onProgress: onProgress);
