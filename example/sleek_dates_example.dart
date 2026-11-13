import 'package:sleek_dates/sleek_dates.dart';

void main() {
  // Dates are validated: this date exists.
  final date = Date(2026, 3, 21);
  print('$date is a ${date.weekday.name}');

  // Invalid dates are rejected instead of silently rolling over...
  print(Date.tryCreate(2026, 2, 30)); // null
  print(Date.tryParse('2026-02-30')); // null

  // ...unless you ask for it explicitly, like DateTime does.
  print(Date.rollover(2026, 12, 32)); // 2027-01-01

  // Comparisons, also usable with null-aware calls.
  final Date? deadline = Date.tryParse('2026-04-01');
  print(deadline?.isAfterOrSame(date) ?? true);

  // Interoperability with DateTime.
  print(DateTime(2026, 3, 21, 18, 30).toDate() == date); // true
}
