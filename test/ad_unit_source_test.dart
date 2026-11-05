// Production ad unit ids must come only from build-time defines.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admob_banner.dart reads ad unit ids only from build-time defines', () {
    final source = File('lib/admob_banner.dart').readAsStringSync();

    expect(source.contains('flutter_dotenv'), isFalse);
    expect(source.contains('dotenv.'), isFalse);
    expect(
      source.contains("String.fromEnvironment('IOS_BANNER_UNIT_ID')"),
      isTrue,
    );
    expect(
      source.contains("String.fromEnvironment('ANDROID_BANNER_UNIT_ID')"),
      isTrue,
    );
  });

  test('assets/.env_example does not define banner unit ids', () {
    final example = File('assets/.env_example').readAsStringSync();

    expect(example.contains('BANNER_UNIT_ID='), isFalse);
  });
}
