/// 🤖 Generated wholly or partially with GPT-5.6 Sol; OpenAI
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/nextcloud/server_url.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/pages/user/login.dart';

void main() {
  group('parseNextcloudServerUrl', () {
    test('rejects missing and empty configuration', () {
      expect(
        () => parseNextcloudServerUrl(''),
        throwsA(isA<NextcloudConfigurationException>()),
      );
      expect(isValidNextcloudServerUrl(''), isFalse);
    });

    test('accepts absolute HTTPS URLs', () {
      expect(
        parseNextcloudServerUrl('https://cloud.example.com').host,
        'cloud.example.com',
      );
      expect(
        parseNextcloudServerUrl('https://cloud.example.com:8443').port,
        8443,
      );
      expect(
        parseNextcloudServerUrl('https://[2001:db8::1]:9443').host,
        '2001:db8::1',
      );
    });

    test('rejects insecure and malformed URLs', () {
      for (final value in [
        'http://cloud.example.com',
        'cloud.example.com',
        'ftp://cloud.example.com',
        'https://',
        'https://cloud.example.com:not-a-port',
        'https://user:password@cloud.example.com',
        'https://cloud.example.com/#fragment',
        'https://[2001:db8::1',
      ]) {
        expect(isValidNextcloudServerUrl(value), isFalse, reason: value);
      }
    });

    test('rejects an HTTP login-flow redirect target', () {
      expect(
        isValidNextcloudServerUrl('http://redirected.example.com'),
        isFalse,
      );
    });
  });

  group('saved configuration', () {
    setUp(() {
      stows.url.value = '';
      stows.username.value = 'user';
      stows.ncPassword.value = 'password';
      stows.encPassword.value = 'encryption-password';
      stows.key.value = 'key';
      stows.iv.value = 'iv';
    });

    test('previously saved empty URL is not logged in', () {
      expect(stows.loggedIn, isFalse);
      expect(NcLoginPage.getCurrentStep(), LoginStep.nc);
      expect(
        NextcloudClientExtension.withSavedDetails,
        throwsA(isA<NextcloudConfigurationException>()),
      );
    });

    test('configured HTTPS URL is logged in and creates a client', () {
      stows.url.value = 'https://cloud.example.com:8443';
      expect(stows.loggedIn, isTrue);
      expect(NextcloudClientExtension.withSavedDetails(), isNotNull);
    });
  });
}
