import 'package:sleek_dates/sleek_dates.dart';
import 'package:test/test.dart';

void main() {
  group('toDate', () {
    test('drops the time of day', () {
      expect(DateTime(2026, 3, 21, 23, 59, 59).toDate(), Date(2026, 3, 21));
      expect(DateTime.utc(2026, 3, 21, 0, 0, 1).toDate(), Date(2026, 3, 21));
    });

    test('does not convert time zones', () {
      // 2026-03-21 23:30 UTC is already the 22nd in many local time zones, but fields are kept as they are.
      expect(DateTime.utc(2026, 3, 21, 23, 30).toDate(), Date(2026, 3, 21));
      expect(DateTime.utc(2026, 3, 21, 23, 30).toLocal().toDate(), Date.fromDateTime(DateTime.utc(2026, 3, 21, 23, 30).toLocal()));
    });
  });

  group('same year / month / day', () {
    final morning = DateTime(2026, 3, 21, 8);
    final evening = DateTime(2026, 3, 21, 22, 30);

    test('isAtSameDayAs ignores the time of day', () {
      expect(morning.isAtSameDayAs(evening), isTrue);
      expect(morning.isAtSameDayAs(DateTime(2026, 3, 22, 8)), isFalse);
      expect(morning.isAtSameDayAs(DateTime(2026, 4, 21, 8)), isFalse);
      expect(morning.isAtSameDayAs(DateTime(2025, 3, 21, 8)), isFalse);
    });

    test('isAtSameMonthAs includes the year', () {
      expect(morning.isAtSameMonthAs(DateTime(2026, 3, 1)), isTrue);
      expect(morning.isAtSameMonthAs(DateTime(2026, 4, 21)), isFalse);
      expect(morning.isAtSameMonthAs(DateTime(2025, 3, 21)), isFalse);
    });

    test('isAtSameYearAs', () {
      expect(morning.isAtSameYearAs(DateTime(2026, 12, 31)), isTrue);
      expect(morning.isAtSameYearAs(DateTime(2027, 3, 21)), isFalse);
    });
  });

  group('isBeforeOrSame / isAfterOrSame', () {
    final instant = DateTime(2026, 3, 21, 12);
    final sameInstant = DateTime(2026, 3, 21, 12);
    final later = DateTime(2026, 3, 21, 12, 0, 1);

    test('isAfterOrSame', () {
      expect(instant.isAfterOrSame(sameInstant), isTrue);
      expect(later.isAfterOrSame(instant), isTrue);
      expect(instant.isAfterOrSame(later), isFalse);
    });

    test('isBeforeOrSame', () {
      expect(instant.isBeforeOrSame(sameInstant), isTrue);
      expect(instant.isBeforeOrSame(later), isTrue);
      expect(later.isBeforeOrSame(instant), isFalse);
    });

    test('compares moments, whatever the time zone', () {
      final utc = DateTime.utc(2026, 3, 21, 12);
      final sameMomentLocal = utc.toLocal();
      expect(utc == sameMomentLocal, isFalse);
      expect(utc.isAfterOrSame(sameMomentLocal), isTrue);
      expect(utc.isBeforeOrSame(sameMomentLocal), isTrue);
    });

    test('works in null-aware calls', () {
      final DateTime? missing = DateTime.tryParse('invalid');
      expect(missing?.isAfterOrSame(instant) == true, isFalse);
    });
  });
}
