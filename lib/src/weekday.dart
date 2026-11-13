/// A day of the week, starting on Monday (ISO 8601).
enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  /// The ISO 8601 number of this day: 1 for Monday, up to 7 for Sunday.
  ///
  /// Same numbering as [DateTime.weekday].
  int get number => index + 1;

  /// Returns the [Weekday] for an ISO 8601 [number] (1 for Monday, up to 7 for Sunday).
  ///
  /// Throws a [RangeError] if [number] is not between 1 and 7.
  static Weekday fromNumber(int number) {
    RangeError.checkValueInInterval(number, 1, DateTime.daysPerWeek, 'number');
    return values[number - 1];
  }
}
