// Release builds read the production ad unit ids from assets/.env, and both release checks read the same file.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _source = 'lib/admob_banner.dart';
const _androidKeys = ['ANDROID_BANNER_UNIT_ID'];
const _iosKeys = ['IOS_BANNER_UNIT_ID'];

RegExp _dotenvGet(String key) =>
    RegExp('dotenv\\.get\\(\\s*[\'"]$key[\'"]\\s*\\)');

void main() {
  test(
    '$_source reads the ad unit ids from assets/.env in release builds only',
    () {
      final source = File(_source).readAsStringSync();
      expect(
        RegExp(r'''String\.fromEnvironment\(\s*['"][A-Z0-9_]*_UNIT_ID['"]''')
            .hasMatch(source),
        isFalse,
      );
      expect(source.contains('!kDebugMode'), isFalse);
      expect(source.contains('kReleaseMode'), isTrue);
      for (final key in [..._androidKeys, ..._iosKeys]) {
        expect(_dotenvGet(key).hasMatch(source), isTrue, reason: key);
      }
    },
  );

  test('assets/.env_example lists every ad unit key the release reads', () {
    final example = File('assets/.env_example').readAsStringSync();
    for (final key in [..._androidKeys, ..._iosKeys]) {
      expect(
        RegExp('^$key=\$', multiLine: true).hasMatch(example),
        isTrue,
        reason: key,
      );
    }
  });

  test('the release checks read assets/.env and reject Google demo units', () {
    final gradle = File('android/app/build.gradle').readAsStringSync();
    expect(gradle.contains("rootProject.file('../assets/.env')"), isTrue);
    expect(
      gradle.contains(
        'requiredReleaseEnvKeys = [${_androidKeys.map((k) => "'$k'").join(', ')}]',
      ),
      isTrue,
    );
    expect(gradle.contains('ca-app-pub-3940256099942544/'), isTrue);
    expect(gradle.contains('requiredReleaseDefines'), isFalse);
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbx.contains('/../assets/.env'), isTrue);
    expect(pbx.contains('ca-app-pub-3940256099942544/'), isTrue);
    expect(pbx.contains('--dart-define-from-file gave no'), isFalse);
    expect(pbx.contains('for key in ${_iosKeys.join(' ')}; do'), isTrue);
  });

  test('README sends release builds to assets/.env, not to a separate ad unit file', () {
    expect(
      File('README.md').readAsStringSync().contains('<ad-unit-file>'),
      isFalse,
    );
  });
}
