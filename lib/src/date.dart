import 'weekday.dart';

/// A calendar date (year, month, day), without any time of day or time zone.
///
/// Instances are immutable and always represent a date that exists
/// (e.g. February 30th is rejected), unless created with [Date.unchecked].
///
/// All calendar computations rely on [DateTime.utc], so they never suffer from
/// daylight saving time changes.
final class Date implements Comparable<Date> {
  /// Creates a date from its [year], [month] (1-12) and [day] (1-31).
  ///
  /// Throws an [ArgumentError] if the date does not exist, or if [year] is out of
  /// the [minYear]..[maxYear] range. Use [tryCreate] to get `null` instead, or
  /// [rollover] to let out-of-range values overflow into the next/previous
  /// month or year.
  factory Date(int year, int month, int day) {
    final date = tryCreate(year, month, day);
    if (date == null) throw ArgumentError('Invalid date: year $year, month $month, day $day');
    return date;
  }

  /// Creates a date without any validation.
  ///
  /// Meant for constants, as it is the only `const` constructor. The caller is
  /// responsible for passing a date that exists, otherwise the resulting [Date]
  /// is invalid and its behavior is undefined.
  const Date.unchecked(this.year, this.month, this.day);

  /// Creates a date, or returns `null` if the date does not exist or if [year] is
  /// out of the [minYear]..[maxYear] range.
  static Date? tryCreate(int year, int month, int day) {
    if (year < minYear || year > maxYear) return null;

    // DateTime normalizes out-of-range values, so the date exists if nothing moved.
    final dateTime = DateTime.utc(year, month, day);
    if (dateTime.year != year || dateTime.month != month || dateTime.day != day) return null;

    return Date.unchecked(year, month, day);
  }

  /// Creates a date by letting [month] and [day] overflow, like [DateTime] does.
  ///
  /// Examples:
  /// - `Date.rollover(2026, 12, 32)` is 2027-01-01.
  /// - `Date.rollover(2026, 3, 0)` is 2026-02-28 (last day of the previous month).
  /// - `Date.rollover(2026, 14, 1)` is 2027-02-01.
  ///
  /// Throws an [ArgumentError] if the resulting year is out of the [minYear]..[maxYear] range.
  factory Date.rollover(int year, int month, int day) => Date.fromDateTime(DateTime.utc(year, month, day));

  /// Creates a date from the year, month and day of [dateTime], as they are.
  ///
  /// No time zone conversion is made: if [dateTime] is in UTC, the UTC date is
  /// used, and if it is local, the local date is used. Call [DateTime.toLocal]
  /// or [DateTime.toUtc] first to pick another one.
  ///
  /// Throws an [ArgumentError] if the year is out of the [minYear]..[maxYear] range.
  factory Date.fromDateTime(DateTime dateTime) => Date(dateTime.year, dateTime.month, dateTime.day);

  /// Creates the current date in the local time zone.
  factory Date.today() => Date.fromDateTime(DateTime.now());

  /// Creates the current date in UTC.
  factory Date.todayUtc() => Date.fromDateTime(DateTime.now().toUtc());

  /// Parses a date in the strict ISO 8601 format `yyyy-MM-dd` (e.g. `2026-03-21`).
  ///
  /// Throws a [FormatException] if [source] is not in this format, or if the
  /// date does not exist. See [tryParse] for a variant returning `null`.
  static Date parse(String source) {
    final match = _isoFormat.firstMatch(source);
    if (match == null) throw FormatException('Expected format yyyy-MM-dd', source);

    final date = _fromMatch(match);
    if (date == null) throw FormatException('Date does not exist', source);
    return date;
  }

  /// Same as [parse], but returns `null` instead of throwing.
  static Date? tryParse(String source) {
    final match = _isoFormat.firstMatch(source);
    return match == null ? null : _fromMatch(match);
  }

  /// Creates a date from its [toJson] representation (`yyyy-MM-dd`).
  ///
  /// Throws a [FormatException] if [json] is not a valid date.
  factory Date.fromJson(String json) => Date.parse(json);

  /// Smallest supported year.
  static const minYear = 1;

  /// Largest supported year.
  static const maxYear = 9999;

  static final _isoFormat = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static Date? _fromMatch(RegExpMatch match) => tryCreate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );

  /// The year, between [minYear] and [maxYear].
  final int year;

  /// The month of the year, from 1 (January) to 12 (December).
  final int month;

  /// The day of the month, from 1 to 31.
  final int day;

  /// This date at midnight, in UTC. All calendar computations rely on it, as UTC has no daylight saving time.
  DateTime get _utc => DateTime.utc(year, month, day);

  static int _daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

  /// The day of the week.
  Weekday get weekday => Weekday.fromNumber(_utc.weekday);

  /// The number of days in this date's month, from 28 to 31.
  int get daysInMonth => _daysInMonth(year, month);

  /// Whether this date's year is a leap year.
  bool get isLeapYear => _daysInMonth(year, 2) == 29;

  /// The day of the year, from 1 (January 1st) to 365 (366 on leap years).
  int get dayOfYear => daysSince(Date.unchecked(year, 1, 1)) + 1;

  /// The number of days since 1970-01-01 (negative before that).
  int get epochDay => _utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  /// Whether this date is today, in the local time zone.
  bool get isToday => this == Date.today();

  /// Whether this date is yesterday, in the local time zone.
  bool get isYesterday => Date.today().daysSince(this) == 1;

  /// Returns this date plus [days] days (minus if negative).
  ///
  /// Throws an [ArgumentError] if the resulting year is out of the [minYear]..[maxYear] range.
  Date addDays(int days) => days == 0 ? this : Date.rollover(year, month, day + days);

  /// Returns this date plus [months] months (minus if negative).
  ///
  /// If the resulting month is shorter than this date's day, the day is clamped to the
  /// last day of the month. For example, `Date(2026, 1, 31).addMonths(1)` is 2026-02-28.
  ///
  /// Throws an [ArgumentError] if the resulting year is out of the [minYear]..[maxYear] range.
  Date addMonths(int months) {
    if (months == 0) return this;

    final monthIndex = year * 12 + (month - 1) + months;
    final newYear = (monthIndex - monthIndex % 12) ~/ 12;
    final newMonth = monthIndex % 12 + 1;
    if (newYear < minYear || newYear > maxYear) throw ArgumentError('Resulting year $newYear is out of range');

    final lastDay = _daysInMonth(newYear, newMonth);
    return Date(newYear, newMonth, day > lastDay ? lastDay : day);
  }

  /// Returns this date plus [years] years (minus if negative).
  ///
  /// The day is clamped like [addMonths]: `Date(2024, 2, 29).addYears(1)` is 2025-02-28.
  Date addYears(int years) => addMonths(years * 12);

  /// The number of days from [other] to this date: positive if this date is after [other].
  int daysSince(Date other) => epochDay - other.epochDay;

  /// The number of days from this date to [other]: positive if [other] is after this date.
  int daysUntil(Date other) => other.epochDay - epochDay;

  /// Whether [other] is in the same year as this.
  bool isAtSameYearAs(Date other) => year == other.year;

  /// Whether [other] is in the same month as this, i.e. the same month of the same year.
  bool isAtSameMonthAs(Date other) => isAtSameYearAs(other) && month == other.month;

  /// The first day of this date's month.
  Date get firstDayOfMonth => Date.unchecked(year, month, 1);

  /// The last day of this date's month.
  Date get lastDayOfMonth => Date.unchecked(year, month, daysInMonth);

  /// The first day of the month following this date's month.
  Date get firstDayOfNextMonth => firstDayOfMonth.addMonths(1);

  /// The first day of the month preceding this date's month.
  Date get firstDayOfPreviousMonth => firstDayOfMonth.addMonths(-1);

  /// The first day of this date's week, which starts on [start] (Monday by default).
  ///
  /// Returns this date if it is already a [start] day.
  Date firstDayOfWeek({Weekday start = Weekday.monday}) => previous(start, orSame: true);

  /// The last day of this date's week, which starts on [start] (Monday by default).
  Date lastDayOfWeek({Weekday start = Weekday.monday}) => firstDayOfWeek(start: start).addDays(DateTime.daysPerWeek - 1);

  /// The first [day] after this date.
  ///
  /// If this date is already a [day], it is skipped and the next week's one is returned, unless
  /// [orSame] is true, in which case this date is returned.
  Date next(Weekday day, {bool orSame = false}) {
    var delta = (day.number - weekday.number) % DateTime.daysPerWeek;
    if (delta == 0 && !orSame) delta = DateTime.daysPerWeek;
    return addDays(delta);
  }

  /// The last [day] before this date.
  ///
  /// If this date is already a [day], it is skipped and the previous week's one is returned, unless
  /// [orSame] is true, in which case this date is returned.
  Date previous(Weekday day, {bool orSame = false}) {
    var delta = (weekday.number - day.number) % DateTime.daysPerWeek;
    if (delta == 0 && !orSame) delta = DateTime.daysPerWeek;
    return addDays(-delta);
  }

  /// Whether this date is strictly before [other].
  bool isBefore(Date other) => compareTo(other) < 0;

  /// Whether this date is strictly after [other].
  bool isAfter(Date other) => compareTo(other) > 0;

  /// Whether this date is before or the same day as [other].
  bool isBeforeOrSame(Date other) => compareTo(other) <= 0;

  /// Whether this date is after or the same day as [other].
  bool isAfterOrSame(Date other) => compareTo(other) >= 0;

  bool operator <(Date other) => isBefore(other);

  bool operator <=(Date other) => isBeforeOrSame(other);

  bool operator >(Date other) => isAfter(other);

  bool operator >=(Date other) => isAfterOrSame(other);

  @override
  int compareTo(Date other) {
    final byYear = year.compareTo(other.year);
    if (byYear != 0) return byYear;
    final byMonth = month.compareTo(other.month);
    if (byMonth != 0) return byMonth;
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) => other is Date && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// The date in the ISO 8601 format `yyyy-MM-dd` (e.g. `2026-03-21`).
  @override
  String toString() => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// The JSON representation of this date: the same string as [toString].
  String toJson() => toString();
}
