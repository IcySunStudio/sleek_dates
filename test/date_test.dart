import 'dart:collection';

import 'package:sleek_dates/sleek_dates.dart';
import 'package:test/test.dart';

void main() {
  group('Date()', () {
    test('creates valid dates', () {
      final date = Date(2026, 3, 21);
      expect(date.year, 2026);
      expect(date.month, 3);
      expect(date.day, 21);
    });

    test('accepts leap days only on leap years', () {
      expect(Date(2024, 2, 29).day, 29);
      expect(Date(2000, 2, 29).day, 29);
      expect(() => Date(2023, 2, 29), throwsArgumentError);
      expect(() => Date(1900, 2, 29), throwsArgumentError);
    });

    test('rejects days that do not exist', () {
      expect(() => Date(2026, 2, 30), throwsArgumentError);
      expect(() => Date(2026, 4, 31), throwsArgumentError);
      expect(() => Date(2026, 12, 32), throwsArgumentError);
      expect(() => Date(2026, 1, 0), throwsArgumentError);
    });

    test('rejects months that do not exist', () {
      expect(() => Date(2026, 0, 1), throwsArgumentError);
      expect(() => Date(2026, 13, 1), throwsArgumentError);
    });

    test('rejects years out of range', () {
      expect(Date(1, 1, 1).year, 1);
      expect(Date(9999, 12, 31).year, 9999);
      expect(() => Date(0, 1, 1), throwsArgumentError);
      expect(() => Date(10000, 1, 1), throwsArgumentError);
      expect(() => Date(-5, 1, 1), throwsArgumentError);
    });
  });

  group('Date.tryCreate', () {
    test('returns a date when valid', () {
      expect(Date.tryCreate(2026, 3, 21), Date(2026, 3, 21));
    });

    test('returns null when invalid', () {
      expect(Date.tryCreate(2026, 2, 30), isNull);
      expect(Date.tryCreate(2026, 13, 1), isNull);
      expect(Date.tryCreate(0, 1, 1), isNull);
      expect(Date.tryCreate(2026, 1, 1000000000), isNull);
      expect(Date.tryCreate(2026, 1000000000, 1), isNull);
    });
  });

  group('Date.rollover', () {
    test('behaves like Date() for valid dates', () {
      expect(Date.rollover(2026, 3, 21), Date(2026, 3, 21));
    });

    test('overflows days', () {
      expect(Date.rollover(2026, 12, 32), Date(2027, 1, 1));
      expect(Date.rollover(2026, 2, 30), Date(2026, 3, 2));
      expect(Date.rollover(2024, 2, 30), Date(2024, 3, 1));
    });

    test('underflows days', () {
      expect(Date.rollover(2026, 3, 0), Date(2026, 2, 28));
      expect(Date.rollover(2026, 1, 0), Date(2025, 12, 31));
    });

    test('overflows and underflows months', () {
      expect(Date.rollover(2026, 14, 1), Date(2027, 2, 1));
      expect(Date.rollover(2026, 0, 1), Date(2025, 12, 1));
      expect(Date.rollover(2026, -1, 1), Date(2025, 11, 1));
    });

    test('rejects a resulting year out of range', () {
      expect(() => Date.rollover(9999, 12, 32), throwsArgumentError);
      expect(() => Date.rollover(1, 1, 0), throwsArgumentError);
    });

    test('rejects absurdly large values instead of wrapping around', () {
      expect(() => Date.rollover(2026, 1000000000, 1), throwsArgumentError);
      expect(() => Date.rollover(2026, 1, 1000000000000), throwsArgumentError);
      expect(() => Date.rollover(1000000, 1, 1), throwsArgumentError);
      expect(() => Date.rollover(2026, -1000000000, 1), throwsArgumentError);
    });
  });

  group('Date.fromDateTime', () {
    test('keeps the fields as they are, ignoring the time', () {
      expect(Date.fromDateTime(DateTime(2026, 3, 21, 23, 59, 59)), Date(2026, 3, 21));
      expect(Date.fromDateTime(DateTime.utc(2026, 3, 21, 23, 59, 59)), Date(2026, 3, 21));
      expect(Date.fromDateTime(DateTime(2026, 3, 21, 0, 0, 1)), Date(2026, 3, 21));
    });
  });

  group('Date.today', () {
    test('matches the local date', () {
      final before = DateTime.now();
      final today = Date.today();
      final after = DateTime.now();
      expect(today, anyOf(Date.fromDateTime(before), Date.fromDateTime(after)));
    });

    test('todayUtc matches the UTC date', () {
      final before = DateTime.now().toUtc();
      final today = Date.todayUtc();
      final after = DateTime.now().toUtc();
      expect(today, anyOf(Date.fromDateTime(before), Date.fromDateTime(after)));
    });

    test('isToday', () {
      expect(Date.today().isToday, isTrue);
      expect(Date.tryCreate(2000, 1, 1)!.isToday, isFalse);
    });
  });

  group('parse', () {
    test('parses strict ISO dates', () {
      expect(Date.parse('2026-03-21'), Date(2026, 3, 21));
      expect(Date.parse('2024-02-29'), Date(2024, 2, 29));
      expect(Date.tryParse('2026-03-21'), Date(2026, 3, 21));
    });

    test('rejects other formats', () {
      const invalid = [
        '',
        '2026-3-21',
        '2026-03-2',
        '26-03-21',
        '2026/03/21',
        '20260321',
        '21-03-2026',
        ' 2026-03-21',
        '2026-03-21 ',
        '2026-03-21\n',
        '2026-03-21T00:00:00',
        '2026-03-21T00:00:00Z',
        '+026-03-21',
        'abcd-ef-gh',
      ];
      for (final source in invalid) {
        expect(() => Date.parse(source), throwsFormatException, reason: source);
        expect(Date.tryParse(source), isNull, reason: source);
      }
    });

    test('rejects dates that do not exist', () {
      const invalid = ['2026-02-30', '2023-02-29', '2026-13-01', '2026-00-10', '2026-01-00', '2026-04-31', '0000-01-01'];
      for (final source in invalid) {
        expect(() => Date.parse(source), throwsFormatException, reason: source);
        expect(Date.tryParse(source), isNull, reason: source);
      }
    });

    test('supports years with leading zeros', () {
      expect(Date.parse('0001-01-01'), Date(1, 1, 1));
      expect(Date(1, 1, 1).toString(), '0001-01-01');
    });
  });

  group('serialization', () {
    test('toString is the ISO format', () {
      expect(Date(2026, 3, 21).toString(), '2026-03-21');
      expect(Date(2026, 12, 5).toString(), '2026-12-05');
      expect(Date(999, 1, 9).toString(), '0999-01-09');
    });

    test('toJson and fromJson round-trip', () {
      final date = Date(2026, 3, 21);
      expect(date.toJson(), '2026-03-21');
      expect(Date.fromJson(date.toJson()), date);
    });

    test('fromJson rejects invalid values', () {
      expect(() => Date.fromJson('nope'), throwsFormatException);
    });
  });

  group('weekday', () {
    test('is correct on known dates', () {
      expect(Date(2026, 3, 21).weekday, Weekday.saturday);
      expect(Date(2024, 2, 29).weekday, Weekday.thursday);
      expect(Date(2000, 1, 1).weekday, Weekday.saturday);
      expect(Date(2026, 3, 23).weekday, Weekday.monday);
      expect(Date(2026, 3, 22).weekday, Weekday.sunday);
    });

    test('Weekday numbers follow ISO 8601', () {
      expect(Weekday.monday.number, 1);
      expect(Weekday.sunday.number, 7);
      for (final day in Weekday.values) {
        expect(Weekday.fromNumber(day.number), day);
      }
      expect(Weekday.fromNumber(DateTime.wednesday), Weekday.wednesday);
      expect(() => Weekday.fromNumber(0), throwsRangeError);
      expect(() => Weekday.fromNumber(8), throwsRangeError);
    });
  });

  group('comparison', () {
    final a = Date(2026, 3, 21);
    final sameAsA = Date(2026, 3, 21);
    final nextDay = Date(2026, 3, 22);
    final nextMonth = Date(2026, 4, 1);
    final nextYear = Date(2027, 1, 1);

    test('equality and hashCode', () {
      expect(a, sameAsA);
      expect(a.hashCode, sameAsA.hashCode);
      expect(a == nextDay, isFalse);
      expect(a == Object(), isFalse);
    });

    test('works as Set and Map key', () {
      final set = {a, sameAsA, nextDay};
      expect(set, hasLength(2));
      final map = {a: 1};
      expect(map[sameAsA], 1);
    });

    test('isBefore and isAfter', () {
      expect(a.isBefore(nextDay), isTrue);
      expect(a.isBefore(nextMonth), isTrue);
      expect(a.isBefore(nextYear), isTrue);
      expect(a.isBefore(sameAsA), isFalse);
      expect(nextDay.isBefore(a), isFalse);

      expect(nextDay.isAfter(a), isTrue);
      expect(nextYear.isAfter(nextMonth), isTrue);
      expect(a.isAfter(sameAsA), isFalse);
      expect(a.isAfter(nextDay), isFalse);
    });

    test('isBeforeOrSame and isAfterOrSame', () {
      expect(a.isBeforeOrSame(sameAsA), isTrue);
      expect(a.isBeforeOrSame(nextDay), isTrue);
      expect(nextDay.isBeforeOrSame(a), isFalse);

      expect(a.isAfterOrSame(sameAsA), isTrue);
      expect(nextDay.isAfterOrSame(a), isTrue);
      expect(a.isAfterOrSame(nextDay), isFalse);
    });

    test('operators', () {
      expect(a < nextDay, isTrue);
      expect(a <= sameAsA, isTrue);
      expect(nextDay > a, isTrue);
      expect(a >= sameAsA, isTrue);
      expect(a > nextDay, isFalse);
      expect(a < sameAsA, isFalse);
    });

    test('null-aware calls', () {
      final Date? missing = Date.tryParse('invalid');
      expect(missing?.isAfterOrSame(a) == true, isFalse);
      expect(missing?.isAfterOrSame(a) ?? true, isTrue);
    });

    test('compareTo orders by year, then month, then day', () {
      final sorted = SplayTreeSet<Date>.of([nextYear, nextMonth, nextDay, a]);
      expect(sorted.toList(), [a, nextDay, nextMonth, nextYear]);
      expect(a.compareTo(sameAsA), 0);
      expect(Date(2026, 12, 1).compareTo(Date(2027, 1, 1)), isNegative);
      expect(Date(2026, 2, 28).compareTo(Date(2026, 3, 1)), isNegative);
    });
  });
}
