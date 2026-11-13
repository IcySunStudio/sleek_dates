/// A time of day (hour, minute, second), without any date or time zone.
///
/// Instances are immutable and always represent a valid time of day, from
/// 00:00:00 to 23:59:59.
final class Time implements Comparable<Time> {
  /// Creates a time from its [hour] (0-23), [minute] (0-59) and [second] (0-59).
  ///
  /// Throws an [ArgumentError] if one of the values is out of range. Use
  /// [tryCreate] to get `null` instead.
  factory Time(int hour, int minute, [int second = 0]) {
    final time = tryCreate(hour, minute, second);
    if (time == null) throw ArgumentError('Invalid time: hour $hour, minute $minute, second $second');
    return time;
  }

  /// Creates a time without any validation: the caller must pass valid values.
  const Time._(this.hour, this.minute, this.second);

  /// Creates a time, or returns `null` if one of the values is out of range.
  static Time? tryCreate(int hour, int minute, [int second = 0]) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) return null;
    return Time._(hour, minute, second);
  }

  /// Creates a time from the hour, minute and second of [dateTime], as they are.
  ///
  /// No time zone conversion is made: if [dateTime] is in UTC, the UTC time is
  /// used, and if it is local, the local time is used. Call [DateTime.toLocal]
  /// or [DateTime.toUtc] first to pick another one.
  factory Time.fromDateTime(DateTime dateTime) => Time._(dateTime.hour, dateTime.minute, dateTime.second);

  /// Creates the current time of day in the local time zone.
  factory Time.now() => Time.fromDateTime(DateTime.now());

  /// Creates a time from the number of seconds elapsed since midnight.
  ///
  /// Throws a [RangeError] if [seconds] is not between 0 and 86399 (23:59:59).
  factory Time.fromSecondsSinceMidnight(int seconds) {
    RangeError.checkValueInInterval(seconds, 0, _secondsPerDay - 1, 'seconds');
    return Time._(seconds ~/ Duration.secondsPerHour, seconds ~/ Duration.secondsPerMinute % Duration.minutesPerHour, seconds % Duration.secondsPerMinute);
  }

  /// Parses a time in the strict ISO 8601 format `HH:mm` or `HH:mm:ss` (e.g. `07:05` or `07:05:30`).
  ///
  /// Throws a [FormatException] if [source] is not in this format, or if the
  /// time is not valid (e.g. `24:00`). See [tryParse] for a variant returning `null`.
  static Time parse(String source) {
    final match = _isoFormat.firstMatch(source);
    if (match == null) throw FormatException('Expected format HH:mm or HH:mm:ss', source);

    final time = _fromMatch(match);
    if (time == null) throw FormatException('Time is out of range', source);
    return time;
  }

  /// Same as [parse], but returns `null` instead of throwing.
  static Time? tryParse(String source) {
    final match = _isoFormat.firstMatch(source);
    return match == null ? null : _fromMatch(match);
  }

  /// Creates a time from its [toJson] representation (`HH:mm` or `HH:mm:ss`).
  ///
  /// Throws a [FormatException] if [json] is not a valid time.
  factory Time.fromJson(String json) => Time.parse(json);

  /// 00:00:00.
  static const midnight = Time._(0, 0, 0);

  /// 12:00:00.
  static const noon = Time._(12, 0, 0);

  static const _secondsPerDay = Duration.secondsPerDay;

  static final _isoFormat = RegExp(r'^(\d{2}):(\d{2})(?::(\d{2}))?$');

  static Time? _fromMatch(RegExpMatch match) => tryCreate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3) ?? '0'),
      );

  /// The hour of the day, from 0 to 23.
  final int hour;

  /// The minute of the hour, from 0 to 59.
  final int minute;

  /// The second of the minute, from 0 to 59.
  final int second;

  /// The number of seconds elapsed since midnight.
  int get secondsSinceMidnight => hour * Duration.secondsPerHour + minute * Duration.secondsPerMinute + second;

  /// The number of whole minutes elapsed since midnight.
  int get minutesSinceMidnight => hour * Duration.minutesPerHour + minute;

  /// Whether this time is strictly before [other].
  bool isBefore(Time other) => compareTo(other) < 0;

  /// Whether this time is strictly after [other].
  bool isAfter(Time other) => compareTo(other) > 0;

  /// Whether this time is before or the same as [other].
  bool isBeforeOrSame(Time other) => compareTo(other) <= 0;

  /// Whether this time is after or the same as [other].
  bool isAfterOrSame(Time other) => compareTo(other) >= 0;

  bool operator <(Time other) => isBefore(other);

  bool operator <=(Time other) => isBeforeOrSame(other);

  bool operator >(Time other) => isAfter(other);

  bool operator >=(Time other) => isAfterOrSame(other);

  @override
  int compareTo(Time other) => secondsSinceMidnight.compareTo(other.secondsSinceMidnight);

  @override
  bool operator ==(Object other) => other is Time && other.hour == hour && other.minute == minute && other.second == second;

  @override
  int get hashCode => Object.hash(hour, minute, second);

  /// The time in the ISO 8601 format `HH:mm`, or `HH:mm:ss` if [second] is not 0 (e.g. `07:05` or `07:05:30`).
  @override
  String toString() {
    final hourAndMinute = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return second == 0 ? hourAndMinute : '$hourAndMinute:${second.toString().padLeft(2, '0')}';
  }

  /// The JSON representation of this time: the same string as [toString].
  String toJson() => toString();
}
