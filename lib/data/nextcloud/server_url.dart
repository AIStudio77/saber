/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

/// Thrown when a Nextcloud server URL is missing or unsafe to use.
class NextcloudConfigurationException implements Exception {
  /// Creates an error for the rejected [url].
  const NextcloudConfigurationException(this.url);

  /// The URL that could not be used as a Nextcloud server.
  final String url;

  @override
  String toString() => 'NextcloudConfigurationException: Invalid server URL';
}

/// Parses a configured Nextcloud server URL.
///
/// Only absolute HTTPS URLs without credentials or fragments are accepted.
Uri parseNextcloudServerUrl(String value) {
  final Uri uri;
  try {
    uri = Uri.parse(value);
  } on FormatException {
    throw NextcloudConfigurationException(value);
  }

  if (value.isEmpty ||
      !uri.isAbsolute ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    throw NextcloudConfigurationException(value);
  }

  return uri;
}

/// Whether [value] is a safe, configured Nextcloud server URL.
bool isValidNextcloudServerUrl(String value) {
  try {
    parseNextcloudServerUrl(value);
    return true;
  } on NextcloudConfigurationException {
    return false;
  }
}
