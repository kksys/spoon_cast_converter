// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:spoon_cast_converter/lib/version-check-lib.dart';

void main() {
  group('Version', () {
    group('operator <', () {
      test('should return true when a < b', () {
        Version a = Version('1.0.0');
        Version b = Version('1.0.1');

        expect(a < b, isTrue);
      });

      test('should return false when a > b', () {
        Version a = Version('1.0.1');
        Version b = Version('1.0.0');

        expect(a < b, isFalse);
      });
    });
    group('operator >', () {
      test('should return false when a < b', () {
        Version a = Version('1.0.0');
        Version b = Version('1.0.1');

        expect(a > b, isFalse);
      });

      test('should return true when a > b', () {
        Version a = Version('1.0.1');
        Version b = Version('1.0.0');

        expect(a > b, isTrue);
      });
    });
  });
}
