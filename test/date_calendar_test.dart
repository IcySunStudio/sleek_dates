import 'package:sleek_dates/sleek_dates.dart';
import 'package:test/test.dart';

// The int bounds on native platforms, whose abs(), additions and multiplications overflow. Written as expressions, as
// they can't be integer literals on the web, where they become doubles that are just as out of range.
const minInt = -0x8000000000000000;
const maxInt = -(minInt + 1);

void main() {
  group('addDays', () {
    test('adds and subtracts days', () {
      expect(Date(2026, 3, 21).addDays(0), Date(2026, 3, 21));
      expect(Date(2026, 3, 21).addDays(1), Date(2026, 3, 22));
      expect(Date(2026, 3, 21).addDays(-1), Date(2026, 3, 20));
      expect(Date(2026, 3, 21).addDays(10), Date(2026, 3, 31));
    });

    test('crosses month and year boundaries', () {
      expect(Date(2026, 1, 31).addDays(1), Date(2026, 2, 1));
      expect(Date(2026, 12, 31).addDays(1), Date(2027, 1, 1));
      expect(Date(2026, 1, 1).addDays(-1), Date(2025, 12, 31));
      expect(Date(2026, 3, 1).addDays(-1), Date(2026, 2, 28));
      expect(Date(2024, 3, 1).addDays(-1), Date(2024, 2, 29));
    });

    test('handles large amounts', () {
      expect(Date(2026, 1, 1).addDays(365), Date(2027, 1, 1));
      expect(Date(2024, 1, 1).addDays(366), Date(2025, 1, 1));
      expect(Date(2026, 3, 21).addDays(-10000).addDays(10000), Date(2026, 3, 21));
    });

    test('rejects a resulting year out of range', () {
      expect(() => Date(9999, 12, 31).addDays(1), throwsArgumentError);
      expect(() => Date(1, 1, 1).addDays(-1), throwsArgumentError);
      expect(() => Date(2026, 1, 1).addDays(1000000000000), throwsArgumentError);
    });

    test('rejects the int bounds instead of overflowing', () {
      expect(() => Date(2026, 1, 1).addDays(maxInt), throwsArgumentError);
      expect(() => Date(2026, 1, 1).addDays(minInt), throwsArgumentError);
    });

    test('spans the whole supported range', () {
      expect(Date(1, 1, 1).addDays(3652058), Date(9999, 12, 31));
      expect(Date(9999, 12, 31).addDays(-3652058), Date(1, 1, 1));
    });
  });

  group('addMonths', () {
    test('adds and subtracts months', () {
      expect(Date(2026, 3, 21).addMonths(0), Date(2026, 3, 21));
      expect(Date(2026, 3, 21).addMonths(1), Date(2026, 4, 21));
      expect(Date(2026, 3, 21).addMonths(-1), Date(2026, 2, 21));
      expect(Date(2026, 3, 21).addMonths(12), Date(2027, 3, 21));
      expect(Date(2026, 3, 21).addMonths(-13), Date(2025, 2, 21));
    });

    test('crosses year boundaries', () {
      expect(Date(2026, 12, 15).addMonths(1), Date(2027, 1, 15));
      expect(Date(2026, 1, 15).addMonths(-1), Date(2025, 12, 15));
      expect(Date(2026, 1, 15).addMonths(-12), Date(2025, 1, 15));
      expect(Date(2026, 1, 15).addMonths(-24), Date(2024, 1, 15));
    });

    test('clamps the day to the end of the month', () {
      expect(Date(2026, 1, 31).addMonths(1), Date(2026, 2, 28));
      expect(Date(2026, 1, 30).addMonths(1), Date(2026, 2, 28));
      expect(Date(2024, 1, 31).addMonths(1), Date(2024, 2, 29));
      expect(Date(2026, 3, 31).addMonths(-1), Date(2026, 2, 28));
      expect(Date(2026, 3, 31).addMonths(1), Date(2026, 4, 30));
      expect(Date(2026, 8, 31).addMonths(1), Date(2026, 9, 30));
    });

    test('does not drift when chained from the original date', () {
      final date = Date(2026, 1, 31);
      expect(date.addMonths(1), Date(2026, 2, 28));
      expect(date.addMonths(2), Date(2026, 3, 31));
    });

    test('rejects a resulting year out of range', () {
      expect(() => Date(9999, 12, 1).addMonths(1), throwsArgumentError);
      expect(() => Date(1, 1, 1).addMonths(-1), throwsArgumentError);
      expect(() => Date(2026, 1, 1).addMonths(1000000000), throwsArgumentError);
      expect(() => Date(2026, 1, 1).addMonths(-1000000000), throwsArgumentError);
    });

    test('rejects the int bounds instead of overflowing', () {
      expect(() => Date(2026, 12, 1).addMonths(maxInt), throwsArgumentError);
      expect(() => Date(2026, 1, 1).addMonths(minInt), throwsArgumentError);
    });

    test('spans the whole supported range', () {
      expect(Date(1, 1, 1).addMonths(119987), Date(9999, 12, 1));
      expect(Date(9999, 12, 1).addMonths(-119987), Date(1, 1, 1));
    });
  });

  group('addYears', () {
    test('adds and subtracts years', () {
      expect(Date(2026, 3, 21).addYears(1), Date(2027, 3, 21));
      expect(Date(2026, 3, 21).addYears(-26), Date(2000, 3, 21));
    });

    test('clamps February 29th on non leap years', () {
      expect(Date(2024, 2, 29).addYears(1), Date(2025, 2, 28));
      expect(Date(2024, 2, 29).addYears(4), Date(2028, 2, 29));
      expect(Date(2024, 2, 29).addYears(-1), Date(2023, 2, 28));
    });

    test('rejects a resulting year out of range', () {
      expect(() => Date(9999, 1, 1).addYears(1), throwsArgumentError);
      expect(() => Date(1, 12, 31).addYears(-1), throwsArgumentError);
      expect(() => Date(2026, 1, 1).addYears(1000000000), throwsArgumentError);
    });

    test('rejects the int bounds instead of overflowing', () {
      expect(() => Date(2026, 1, 1).addYears(maxInt), throwsArgumentError);
      expect(() => Date(2026, 1, 1).addYears(minInt), throwsArgumentError);
      // Multiplied by 12, it wraps around to 0 on native platforms.
      expect(() => Date(2026, 1, 1).addYears(0x4000000000000000), throwsArgumentError);
    });
  });

  group('daysSince / daysUntil', () {
    test('count days between dates', () {
      final a = Date(2026, 3, 21);
      expect(a.daysSince(a), 0);
      expect(a.daysSince(Date(2026, 3, 20)), 1);
      expect(a.daysSince(Date(2026, 3, 22)), -1);
      expect(a.daysUntil(Date(2026, 3, 22)), 1);
      expect(a.daysUntil(Date(2026, 3, 20)), -1);
      expect(Date(2027, 1, 1).daysSince(Date(2026, 1, 1)), 365);
      expect(Date(2025, 1, 1).daysSince(Date(2024, 1, 1)), 366);
    });

    test('are the opposite of each other', () {
      final a = Date(2026, 3, 21);
      final b = Date(2030, 11, 2);
      expect(a.daysUntil(b), b.daysSince(a));
      expect(a.daysUntil(b), -b.daysUntil(a));
    });
  });

  // These dates surround daylight saving time changes in Europe (2026-03-29 and 2026-10-25), where a naive
  // computation on local DateTime gives wrong results. They only catch a regression on a machine whose
  // time zone observes DST (e.g. Europe/Paris), but they pass anywhere with a correct implementation.
  group('daylight saving time', () {
    test('daysUntil counts whole days across the spring change', () {
      expect(Date(2026, 3, 25).daysUntil(Date(2026, 4, 1)), 7);
      expect(Date(2026, 3, 28).daysUntil(Date(2026, 3, 30)), 2);
    });

    test('daysUntil counts whole days across the autumn change', () {
      expect(Date(2026, 10, 24).daysUntil(Date(2026, 10, 26)), 2);
      expect(Date(2026, 10, 20).daysUntil(Date(2026, 10, 27)), 7);
    });

    test('addDays steps one day at a time across both changes', () {
      expect(Date(2026, 3, 28).addDays(1), Date(2026, 3, 29));
      expect(Date(2026, 3, 29).addDays(1), Date(2026, 3, 30));
      expect(Date(2026, 10, 25).addDays(1), Date(2026, 10, 26));
      expect(Date(2026, 10, 24).addDays(2), Date(2026, 10, 26));
    });

    test('dayOfYear is exact after the spring change', () {
      expect(Date(2026, 7, 1).dayOfYear, 182);
    });
  });

  group('epochDay', () {
    test('is relative to 1970-01-01', () {
      expect(Date(1970, 1, 1).epochDay, 0);
      expect(Date(1970, 1, 2).epochDay, 1);
      expect(Date(1969, 12, 31).epochDay, -1);
      expect(Date(2000, 1, 1).epochDay, 10957);
    });

    test('increments by one, day after day, matching DateTime', () {
      var date = Date(1950, 1, 1);
      var dateTime = DateTime.utc(1950, 1, 1);
      var epochDay = date.epochDay;
      final end = Date(2100, 12, 31);

      while (date != end) {
        date = date.addDays(1);
        dateTime = dateTime.add(const Duration(days: 1));
        epochDay++;

        expect(date.epochDay, epochDay, reason: '$date');
        expect(Date.fromEpochDay(epochDay), date, reason: '$date');
        expect(date.year, dateTime.year, reason: '$date');
        expect(date.month, dateTime.month, reason: '$date');
        expect(date.day, dateTime.day, reason: '$date');
        expect(date.weekday.number, dateTime.weekday, reason: '$date');
      }
    });
  });

  group('Date.fromEpochDay', () {
    test('is relative to 1970-01-01', () {
      expect(Date.fromEpochDay(0), Date(1970, 1, 1));
      expect(Date.fromEpochDay(-1), Date(1969, 12, 31));
      expect(Date.fromEpochDay(10957), Date(2000, 1, 1));
    });

    test('spans the whole supported range', () {
      expect(Date.fromEpochDay(Date(1, 1, 1).epochDay), Date(1, 1, 1));
      expect(Date.fromEpochDay(Date(9999, 12, 31).epochDay), Date(9999, 12, 31));
    });

    test('rejects a resulting year out of range', () {
      expect(() => Date.fromEpochDay(Date(1, 1, 1).epochDay - 1), throwsArgumentError);
      expect(() => Date.fromEpochDay(Date(9999, 12, 31).epochDay + 1), throwsArgumentError);
      expect(() => Date.fromEpochDay(maxInt), throwsArgumentError);
      expect(() => Date.fromEpochDay(minInt), throwsArgumentError);
    });
  });

  group('month and year info', () {
    test('daysInMonth', () {
      expect(Date(2026, 1, 15).daysInMonth, 31);
      expect(Date(2026, 2, 15).daysInMonth, 28);
      expect(Date(2024, 2, 15).daysInMonth, 29);
      expect(Date(2026, 4, 15).daysInMonth, 30);
      expect(Date(2026, 12, 31).daysInMonth, 31);
      expect(Date(9999, 12, 31).daysInMonth, 31);
    });

    test('isLeapYear', () {
      expect(Date(2024, 6, 1).isLeapYear, isTrue);
      expect(Date(2000, 6, 1).isLeapYear, isTrue);
      expect(Date(2026, 6, 1).isLeapYear, isFalse);
      expect(Date(1900, 6, 1).isLeapYear, isFalse);
    });

    test('dayOfYear', () {
      expect(Date(2026, 1, 1).dayOfYear, 1);
      expect(Date(2026, 12, 31).dayOfYear, 365);
      expect(Date(2024, 12, 31).dayOfYear, 366);
      expect(Date(2024, 3, 1).dayOfYear, 61);
      expect(Date(2026, 3, 1).dayOfYear, 60);
    });
  });

  group('same month / year', () {
    final date = Date(2026, 3, 21);

    test('isAtSameMonthAs includes the year', () {
      expect(date.isAtSameMonthAs(Date(2026, 3, 1)), isTrue);
      expect(date.isAtSameMonthAs(Date(2026, 4, 21)), isFalse);
      expect(date.isAtSameMonthAs(Date(2025, 3, 21)), isFalse);
    });

    test('isAtSameYearAs', () {
      expect(date.isAtSameYearAs(Date(2026, 12, 31)), isTrue);
      expect(date.isAtSameYearAs(Date(2027, 3, 21)), isFalse);
    });
  });

  group('first / last day of month', () {
    test('firstDayOfMonth and lastDayOfMonth', () {
      expect(Date(2026, 3, 21).firstDayOfMonth, Date(2026, 3, 1));
      expect(Date(2026, 3, 21).lastDayOfMonth, Date(2026, 3, 31));
      expect(Date(2026, 2, 10).lastDayOfMonth, Date(2026, 2, 28));
      expect(Date(2024, 2, 10).lastDayOfMonth, Date(2024, 2, 29));
      expect(Date(2026, 4, 1).lastDayOfMonth, Date(2026, 4, 30));
    });

    test('firstDayOfNextMonth and firstDayOfPreviousMonth', () {
      expect(Date(2026, 3, 21).firstDayOfNextMonth, Date(2026, 4, 1));
      expect(Date(2026, 12, 31).firstDayOfNextMonth, Date(2027, 1, 1));
      expect(Date(2026, 3, 21).firstDayOfPreviousMonth, Date(2026, 2, 1));
      expect(Date(2026, 1, 31).firstDayOfPreviousMonth, Date(2025, 12, 1));
      expect(Date(2026, 3, 31).firstDayOfPreviousMonth, Date(2026, 2, 1));
    });
  });

  group('weekdays', () {
    // 2026-03-23 is a Monday.
    final monday = Date(2026, 3, 23);
    final wednesday = Date(2026, 3, 25);
    final sunday = Date(2026, 3, 29);

    test('next skips the current day by default', () {
      expect(wednesday.next(Weekday.thursday), Date(2026, 3, 26));
      expect(wednesday.next(Weekday.tuesday), Date(2026, 3, 31));
      expect(wednesday.next(Weekday.wednesday), Date(2026, 4, 1));
      expect(sunday.next(Weekday.monday), Date(2026, 3, 30));
    });

    test('next with orSame returns the current day', () {
      expect(wednesday.next(Weekday.wednesday, orSame: true), wednesday);
      expect(wednesday.next(Weekday.thursday, orSame: true), Date(2026, 3, 26));
    });

    test('previous skips the current day by default', () {
      expect(wednesday.previous(Weekday.tuesday), Date(2026, 3, 24));
      expect(wednesday.previous(Weekday.thursday), Date(2026, 3, 19));
      expect(wednesday.previous(Weekday.wednesday), Date(2026, 3, 18));
      expect(monday.previous(Weekday.sunday), Date(2026, 3, 22));
    });

    test('previous with orSame returns the current day', () {
      expect(wednesday.previous(Weekday.wednesday, orSame: true), wednesday);
      expect(wednesday.previous(Weekday.monday, orSame: true), monday);
    });

    test('next and previous always land on the requested weekday', () {
      for (var i = 0; i < 14; i++) {
        final date = monday.addDays(i);
        for (final day in Weekday.values) {
          final next = date.next(day);
          expect(next.weekday, day);
          expect(date.daysUntil(next), inInclusiveRange(1, 7));

          final previous = date.previous(day);
          expect(previous.weekday, day);
          expect(previous.daysUntil(date), inInclusiveRange(1, 7));
        }
      }
    });

    test('firstDayOfWeek and lastDayOfWeek start on Monday by default', () {
      expect(monday.firstDayOfWeek(), monday);
      expect(wednesday.firstDayOfWeek(), monday);
      expect(sunday.firstDayOfWeek(), monday);
      expect(monday.lastDayOfWeek(), sunday);
      expect(wednesday.lastDayOfWeek(), sunday);
      expect(sunday.lastDayOfWeek(), sunday);
      expect(Date(2026, 3, 30).firstDayOfWeek(), Date(2026, 3, 30));
    });

    test('firstDayOfWeek and lastDayOfWeek support another first day', () {
      expect(wednesday.firstDayOfWeek(start: Weekday.sunday), Date(2026, 3, 22));
      expect(wednesday.lastDayOfWeek(start: Weekday.sunday), Date(2026, 3, 28));
      expect(sunday.firstDayOfWeek(start: Weekday.sunday), sunday);
      expect(sunday.lastDayOfWeek(start: Weekday.sunday), Date(2026, 4, 4));
    });
  });

  group('toDateTime', () {
    test('defaults to local midnight', () {
      final dateTime = Date(2026, 3, 21).toDateTime();
      expect(dateTime, DateTime(2026, 3, 21));
      expect(dateTime.isUtc, isFalse);
    });

    test('applies the time', () {
      expect(Date(2026, 3, 21).toDateTime(time: Time(18, 30)), DateTime(2026, 3, 21, 18, 30));
      expect(Date(2026, 3, 21).toDateTime(time: Time(7, 5, 30)), DateTime(2026, 3, 21, 7, 5, 30));
    });

    test('can be in UTC', () {
      final dateTime = Date(2026, 3, 21).toDateTime(time: Time(18, 30), utc: true);
      expect(dateTime, DateTime.utc(2026, 3, 21, 18, 30));
      expect(dateTime.isUtc, isTrue);
    });

    test('round-trips with toDate and toTime', () {
      final date = Date(2026, 3, 21);
      final time = Time(18, 30, 15);
      final dateTime = date.toDateTime(time: time);
      expect(dateTime.toDate(), date);
      expect(dateTime.toTime(), time);
    });
  });

  group('isYesterday', () {
    test('is true only for the day before today', () {
      final today = Date.today();
      expect(today.addDays(-1).isYesterday, isTrue);
      expect(today.isYesterday, isFalse);
      expect(today.addDays(1).isYesterday, isFalse);
      expect(today.addDays(-2).isYesterday, isFalse);
    });
  });

  group('isTomorrow', () {
    test('is true only for the day after today', () {
      final today = Date.today();
      expect(today.addDays(1).isTomorrow, isTrue);
      expect(today.isTomorrow, isFalse);
      expect(today.addDays(-1).isTomorrow, isFalse);
      expect(today.addDays(2).isTomorrow, isFalse);
    });
  });
}
