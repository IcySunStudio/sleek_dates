import 'date.dart';
import 'time.dart';

/// Date-related helpers for [DateTime].
///
/// The "same year / month / day" checks compare the fields of both values as
/// they are, without any time zone conversion. Call [DateTime.toLocal] or
/// [DateTime.toUtc] on both values first if they are not in the same time zone.
extension SleekDateTime on DateTime {
  /// The date part of this [DateTime], without time of day.
  ///
  /// No time zone conversion is made, see [Date.fromDateTime].
  Date toDate() => Date.fromDateTime(this);

  /// The time of day of this [DateTime], without date.
  ///
  /// No time zone conversion is made, see [Time.fromDateTime].
  Time toTime() => Time.fromDateTime(this);

  /// Whether [other] is in the same year as this.
  bool isAtSameYearAs(DateTime other) => year == other.year;

  /// Whether [other] is in the same month as this, i.e. the same month of the same year.
  bool isAtSameMonthAs(DateTime other) => isAtSameYearAs(other) && month == other.month;

  /// Whether [other] is on the same day as this, i.e. the same day of the same month and year.
  bool isAtSameDayAs(DateTime other) => isAtSameMonthAs(other) && day == other.day;

  /// Whether this is before or at the same moment as [other].
  bool isBeforeOrSame(DateTime other) => !isAfter(other);

  /// Whether this is after or at the same moment as [other].
  bool isAfterOrSame(DateTime other) => !isBefore(other);
}
