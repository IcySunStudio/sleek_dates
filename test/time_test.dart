import 'dart:collection';

import 'package:sleek_dates/sleek_dates.dart';
import 'package:test/test.dart';

void main() {
  group('Time()', () {
    test('creates valid times', () {
      final time = Time(7, 5, 30);
      expect(time.hour, 7);
      expect(time.minute, 5);
      expect(time.second, 30);
    });

    test('seconds default to 0', () {
      expect(Time(7, 5).second, 0);
    });

    test('accepts the bounds of the day', () {
      expect(Time(0, 0, 0), Time.midnight);
      expect(Time(23, 59, 59).secondsSinceMidnight, 86399);
    });

    test('rejects out of range values', () {
      expect(() => Time(24, 0), throwsArgumentError);
      expect(() => Time(-1, 0), throwsArgumentError);
      expect(() => Time(0, 60), throwsArgumentError);
      expect(() => Time(0, -1), throwsArgumentError);
      expect(() => Time(0, 0, 60), throwsArgumentError);
      expect(() => Time(0, 0, -1), throwsArgumentError);
    });
  });

  group('Time.tryCreate', () {
    test('returns a time when valid', () {
      expect(Time.tryCreate(7, 5), Time(7, 5));
      expect(Time.tryCreate(23, 59, 59), Time(23, 59, 59));
    });

    test('returns null when invalid', () {
      expect(Time.tryCreate(24, 0), isNull);
      expect(Time.tryCreate(0, 60), isNull);
      expect(Time.tryCreate(0, 0, 60), isNull);
    });
  });

  group('constants', () {
    test('midnight and noon', () {
      expect(Time.midnight, Time(0, 0));
      expect(Time.noon, Time(12, 0));
      const time = Time.noon;
      expect(time.hour, 12);
    });
  });

  group('Time.fromDateTime', () {
    test('keeps the fields as they are, ignoring the date and milliseconds', () {
      expect(Time.fromDateTime(DateTime(2026, 3, 21, 7, 5, 30, 999)), Time(7, 5, 30));
      expect(Time.fromDateTime(DateTime.utc(2026, 3, 21, 23, 59, 59)), Time(23, 59, 59));
    });

    test('now matches the local time', () {
      final before = DateTime.now();
      final now = Time.now();
      final after = DateTime.now();
      expect(now, anyOf(Time.fromDateTime(before), Time.fromDateTime(after)));
    });
  });

  group('since midnight', () {
    test('secondsSinceMidnight and minutesSinceMidnight', () {
      expect(Time.midnight.secondsSinceMidnight, 0);
      expect(Time(1, 0).secondsSinceMidnight, 3600);
      expect(Time(7, 5, 30).secondsSinceMidnight, 7 * 3600 + 5 * 60 + 30);
      expect(Time(7, 5, 59).minutesSinceMidnight, 7 * 60 + 5);
      expect(Time(23, 59, 59).minutesSinceMidnight, 1439);
    });

    test('fromSecondsSinceMidnight round-trips every second of the day', () {
      for (var seconds = 0; seconds < Duration.secondsPerDay; seconds++) {
        expect(Time.fromSecondsSinceMidnight(seconds).secondsSinceMidnight, seconds);
      }
    });

    test('fromSecondsSinceMidnight splits hours, minutes and seconds', () {
      expect(Time.fromSecondsSinceMidnight(0), Time.midnight);
      expect(Time.fromSecondsSinceMidnight(3661), Time(1, 1, 1));
      expect(Time.fromSecondsSinceMidnight(86399), Time(23, 59, 59));
    });

    test('fromSecondsSinceMidnight rejects values out of the day', () {
      expect(() => Time.fromSecondsSinceMidnight(-1), throwsRangeError);
      expect(() => Time.fromSecondsSinceMidnight(86400), throwsRangeError);
    });
  });

  group('parse', () {
    test('parses HH:mm and HH:mm:ss', () {
      expect(Time.parse('07:05'), Time(7, 5));
      expect(Time.parse('07:05:30'), Time(7, 5, 30));
      expect(Time.parse('00:00'), Time.midnight);
      expect(Time.parse('23:59:59'), Time(23, 59, 59));
      expect(Time.tryParse('18:30'), Time(18, 30));
    });

    test('rejects other formats', () {
      const invalid = [
        '',
        '7:05',
        '07:5',
        '07',
        '0705',
        '07:05:3',
        '07-05',
        ' 07:05',
        '07:05 ',
        '07:05\n',
        '07:05:00.000',
        '07:05:00Z',
        'T07:05',
        'ab:cd',
      ];
      for (final source in invalid) {
        expect(() => Time.parse(source), throwsFormatException, reason: source);
        expect(Time.tryParse(source), isNull, reason: source);
      }
    });

    test('rejects values out of range', () {
      const invalid = ['24:00', '23:60', '23:59:60', '99:99'];
      for (final source in invalid) {
        expect(() => Time.parse(source), throwsFormatException, reason: source);
        expect(Time.tryParse(source), isNull, reason: source);
      }
    });
  });

  group('serialization', () {
    test('toString omits seconds when they are 0', () {
      expect(Time(7, 5).toString(), '07:05');
      expect(Time(0, 0).toString(), '00:00');
      expect(Time(18, 30).toString(), '18:30');
    });

    test('toString includes seconds when they are not 0', () {
      expect(Time(7, 5, 30).toString(), '07:05:30');
      expect(Time(0, 0, 1).toString(), '00:00:01');
    });

    test('toJson and fromJson round-trip every minute of the day', () {
      for (var minutes = 0; minutes < Duration.minutesPerDay; minutes++) {
        final time = Time(minutes ~/ 60, minutes % 60);
        expect(Time.fromJson(time.toJson()), time);
      }
      final withSeconds = Time(7, 5, 30);
      expect(Time.fromJson(withSeconds.toJson()), withSeconds);
    });

    test('fromJson rejects invalid values', () {
      expect(() => Time.fromJson('nope'), throwsFormatException);
    });
  });

  group('comparison', () {
    final a = Time(7, 5, 30);
    final sameAsA = Time(7, 5, 30);
    final nextSecond = Time(7, 5, 31);
    final nextMinute = Time(7, 6);
    final nextHour = Time(8, 0);

    test('equality and hashCode', () {
      expect(a, sameAsA);
      expect(a.hashCode, sameAsA.hashCode);
      expect(a == nextSecond, isFalse);
      expect(a == Object(), isFalse);
      expect(Time(7, 5), isNot(Time(7, 5, 1)));
    });

    test('works as Set and Map key', () {
      expect({a, sameAsA, nextSecond}, hasLength(2));
      expect({a: 1}[sameAsA], 1);
    });

    test('isBefore and isAfter', () {
      expect(a.isBefore(nextSecond), isTrue);
      expect(a.isBefore(nextMinute), isTrue);
      expect(a.isBefore(nextHour), isTrue);
      expect(a.isBefore(sameAsA), isFalse);
      expect(nextHour.isBefore(a), isFalse);

      expect(nextHour.isAfter(a), isTrue);
      expect(a.isAfter(sameAsA), isFalse);
      expect(a.isAfter(nextSecond), isFalse);
    });

    test('isBeforeOrSame and isAfterOrSame', () {
      expect(a.isBeforeOrSame(sameAsA), isTrue);
      expect(a.isBeforeOrSame(nextSecond), isTrue);
      expect(nextSecond.isBeforeOrSame(a), isFalse);

      expect(a.isAfterOrSame(sameAsA), isTrue);
      expect(nextSecond.isAfterOrSame(a), isTrue);
      expect(a.isAfterOrSame(nextSecond), isFalse);
    });

    test('operators', () {
      expect(a < nextSecond, isTrue);
      expect(a <= sameAsA, isTrue);
      expect(nextHour > a, isTrue);
      expect(a >= sameAsA, isTrue);
      expect(a > nextSecond, isFalse);
      expect(a < sameAsA, isFalse);
    });

    test('null-aware calls', () {
      final Time? missing = Time.tryParse('invalid');
      expect(missing?.isAfterOrSame(a) == true, isFalse);
      expect(missing?.isAfterOrSame(a) ?? true, isTrue);
    });

    test('compareTo orders by hour, then minute, then second', () {
      final sorted = SplayTreeSet<Time>.of([nextHour, nextMinute, nextSecond, a]);
      expect(sorted.toList(), [a, nextSecond, nextMinute, nextHour]);
      expect(a.compareTo(sameAsA), 0);
      expect(Time(9, 59).compareTo(Time(10, 0)), isNegative);
    });
  });
}
