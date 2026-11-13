import 'time.dart';
import 'weekday.dart';

/// A calendar date (year, month, day), without any time of day or time zone.
///
/// Instances are immutable and always represent a date that exists
/// (e.g. February 30th is rejected). Years from 1 to 9999 are supported: any
/// operation whose result would fall out of this range (e.g. `Date(9999, 12, 31).addDays(1)`)
/// throws an [ArgumentError].
///
/// All calendar computations rely on [DateTime.utc], so they never suffer from
/// daylight saving time changes.
final class Date implements Comparable<Date> {
  /// Creates a date from its [year], [month] (1-12) and [day] (1-31).
  ///
  /// Throws an [ArgumentError] if the date does not exist, or if [year] is out of
  /// the supported range (years 1 to 9999). Use [tryCreate] to get `null` instead, or
  /// [rollover] to let out-of-range values overflow into the next/previous
  /// month or year.
  factory Date(int year, int month, int day) {
    final date = tryCreate(year, month, day);
    if (date == null) throw ArgumentError('Invalid date: year $year, month $month, day $day');
    return date;
  }

  /// Creates a date without any validation: the caller must pass a date that exists.
  const Date._(this.year, this.month, this.day);

  /// Creates a date, or returns `null` if the date does not exist or if [year] is
  /// out of the supported range (years 1 to 9999).
  static Date? tryCreate(int year, int month, int day) {
    if (year < _minYear || year > _maxYear || month < 1 || month > 12 || day < 1 || day > 31) return null;

    // DateTime normalizes days that do not exist in the month, so the date exists if nothing moved.
    if (DateTime.utc(year, month, day).month != month) return null;

    return Date._(year, month, day);
  }

  /// Creates a date by letting [month] and [day] overflow, like [DateTime] does.
  ///
  /// Examples:
  /// - `Date.rollover(2026, 12, 32)` is 2027-01-01.
  /// - `Date.rollover(2026, 3, 0)` is 2026-02-28 (last day of the previous month).
  /// - `Date.rollover(2026, 14, 1)` is 2027-02-01.
  ///
  /// Throws an [ArgumentError] if the resulting year is out of the supported range (years 1 to 9999).
  factory Date.rollover(int year, int month, int day) {
    // DateTime silently wraps around when given values far beyond its supported range, so reject them upfront.
    RangeError.checkValueInInterval(year, -_maxRolloverYear, _maxRolloverYear, 'year');
    RangeError.checkValueInInterval(month, -_maxRolloverMonth, _maxRolloverMonth, 'month');
    RangeError.checkValueInInterval(day, -_maxRolloverDay, _maxRolloverDay, 'day');
    return Date.fromDateTime(DateTime.utc(year, month, day));
  }

  /// Creates a date from the year, month and day of [dateTime], as they are.
  ///
  /// No time zone conversion is made: if [dateTime] is in UTC, the UTC date is
  /// used, and if it is local, the local date is used. Call [DateTime.toLocal]
  /// or [DateTime.toUtc] first to pick another one.
  ///
  /// Throws an [ArgumentError] if the year is out of the supported range (years 1 to 9999).
  factory Date.fromDateTime(DateTime dateTime) => Date(dateTime.year, dateTime.month, dateTime.day);

  /// Creates the current date in the local time zone.
  factory Date.today() => Date.fromDateTime(DateTime.now());

  /// Creates the current date in UTC.
  factory Date.todayUtc() => Date.fromDateTime(DateTime.now().toUtc());

  /// Creates a date from its [epochDay]: the number of days since 1970-01-01 (negative before that).
  ///
  /// Throws an [ArgumentError] if the resulting year is out of the supported range (years 1 to 9999).
  factory Date.fromEpochDay(int epochDay) => const Date._(1970, 1, 1).addDays(epochDay);

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

  static const _minYear = 1;
  static const _maxYear = 9999;

  // Limits for [rollover] inputs, keeping the sum of all its parts well below the ~275000 years DateTime supports.
  static const _maxRolloverYear = 100000;
  static const _maxRolloverMonth = 1000000;
  static const _maxRolloverDay = 4000000; // Above the 3.65 million days between years 1 and 9999.

  static final _isoFormat = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static Date? _fromMatch(RegExpMatch match) => tryCreate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );

  /// The year, from 1 to 9999.
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
  int get dayOfYear => daysSince(Date._(year, 1, 1)) + 1;

  /// The number of days since 1970-01-01 (negative before that).
  int get epochDay => _utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  /// Whether this date is today, in the local time zone.
  bool get isToday => this == Date.today();

  /// Whether this date is yesterday, in the local time zone.
  bool get isYesterday => Date.today().daysSince(this) == 1;

  /// Whether this date is tomorrow, in the local time zone.
  bool get isTomorrow => daysSince(Date.today()) == 1;

  /// Returns this date plus [days] days (minus if negative).
  ///
  /// Throws an [ArgumentError] if the resulting year is out of the supported range (years 1 to 9999).
  Date addDays(int days) {
    if (days == 0) return this;

    // Checked before the addition, which could overflow.
    RangeError.checkValueInInterval(days, -_maxRolloverDay, _maxRolloverDay, 'days');
    return Date.rollover(year, month, day + days);
  }

  /// Returns this date plus [months] months (minus if negative).
  ///
  /// If the resulting month is shorter than this date's day, the day is clamped to the
  /// last day of the month. For example, `Date(2026, 1, 31).addMonths(1)` is 2026-02-28.
  ///
  /// Throws an [ArgumentError] if the resulting year is out of the supported range (years 1 to 9999).
  Date addMonths(int months) {
    if (months == 0) return this;

    // Checked before the addition, which could overflow.
    RangeError.checkValueInInterval(months, -_maxRolloverMonth, _maxRolloverMonth, 'months');
    final firstDay = Date.rollover(year, month + months, 1);
    final lastDay = firstDay.daysInMonth;
    return Date._(firstDay.year, firstDay.month, day > lastDay ? lastDay : day);
  }

  /// Returns this date plus [years] years (minus if negative).
  ///
  /// The day is clamped like [addMonths]: `Date(2024, 2, 29).addYears(1)` is 2025-02-28.
  ///
  /// Throws an [ArgumentError] if the resulting year is out of the supported range (years 1 to 9999).
  Date addYears(int years) {
    // Checked before the multiplication, which could overflow.
    const maxYears = _maxRolloverMonth ~/ DateTime.monthsPerYear;
    RangeError.checkValueInInterval(years, -maxYears, maxYears, 'years');
    return addMonths(years * DateTime.monthsPerYear);
  }

  /// The number of days from [other] to this date: positive if this date is after [other].
  int daysSince(Date other) => epochDay - other.epochDay;

  /// The number of days from this date to [other]: positive if [other] is after this date.
  int daysUntil(Date other) => other.epochDay - epochDay;

  /// Whether [other] is in the same year as this.
  bool isAtSameYearAs(Date other) => year == other.year;

  /// Whether [other] is in the same month as this, i.e. the same month of the same year.
  bool isAtSameMonthAs(Date other) => isAtSameYearAs(other) && month == other.month;

  /// The first day of this date's month.
  Date get firstDayOfMonth => Date._(year, month, 1);

  /// The last day of this date's month.
  Date get lastDayOfMonth => Date._(year, month, daysInMonth);

  /// The first day of the month following this date's month.
  Date get firstDayOfNextMonth => firstDayOfMonth.addMonths(1);

  /// The first day of the month preceding this date's month.
  Date get firstDayOfPreviousMonth => firstDayOfMonth.addMonths(-1);

  /// This date at [time] (midnight by default), as a [DateTime] in the local time zone, or in UTC if [utc] is true.
  ///
  /// In the local time zone, a [time] skipped by a daylight saving time change (e.g. 02:30 on the day clocks
  /// go forward) is shifted forward by [DateTime], as it does for any local [DateTime].
  DateTime toDateTime({Time time = Time.midnight, bool utc = false}) =>
      utc ? DateTime.utc(year, month, day, time.hour, time.minute, time.second) : DateTime(year, month, day, time.hour, time.minute, time.second);

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

  /// Same as [isBefore].
  bool operator <(Date other) => isBefore(other);

  /// Same as [isBeforeOrSame].
  bool operator <=(Date other) => isBeforeOrSame(other);

  /// Same as [isAfter].
  bool operator >(Date other) => isAfter(other);

  /// Same as [isAfterOrSame].
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
