# sleek_dates

A sleek, pure-Dart `Date` and `Time` type: a calendar day and a time of day, without time zone or daylight saving time pitfalls.

## Features

| Feature | Details |
|---|---|
| **Pure Dart** | No dependency, no Flutter — works on mobile, desktop, web and server |
| **`Date`** | A day in the calendar (year, month, day), without time of day |
| **`Time`** | A time of day (hour, minute, second), without date |
| **Always valid** | February 30th or 24:00 can't exist: invalid values are rejected, never silently shifted |
| **Reliable calendar math** | Days, months and years arithmetic computed in UTC: exact across daylight saving time changes |
| **Month-end aware** | `addMonths` clamps to the end of the month: January 31st + 1 month = February 28th |
| **Weeks and months** | First/last day of month or week, next/previous weekday, day of year, days between two dates |
| **JSON ready** | `toJson` / `fromJson` as strict ISO 8601 strings (`2026-03-21`, `18:30`) |
| **`DateTime` interop** | `toDate()`, `toTime()` and `Date.toDateTime(...)`, plus handy comparison helpers on `DateTime` |
| **Null-aware friendly** | Named comparison methods (`isAfterOrSame`, ...) work with `?.`, unlike operators |

## Getting started

```yaml
dependencies:
  sleek_dates: ^0.0.1
```

## Usage

```dart
import 'package:sleek_dates/sleek_dates.dart';
```

### Date

```dart
final date = Date(2026, 3, 21);      // throws ArgumentError if the date doesn't exist
Date.tryCreate(2026, 2, 30);         // null
Date.today();                        // local date (Date.todayUtc() for UTC)

date.weekday;                        // Weekday.saturday
date.dayOfYear;                      // 80
date.daysInMonth;                    // 31
date.isLeapYear;                     // false
date.isToday;

// Arithmetic
date.addDays(10);                    // 2026-03-31
date.addMonths(1);                   // 2026-04-21
Date(2026, 1, 31).addMonths(1);      // 2026-02-28 (clamped to the end of the month)
Date(2024, 2, 29).addYears(1);       // 2025-02-28
date.daysUntil(Date(2026, 4, 1));    // 11
date.daysSince(Date(2026, 3, 1));    // 20

// Months and weeks
date.firstDayOfMonth;                // 2026-03-01
date.lastDayOfMonth;                 // 2026-03-31
date.firstDayOfNextMonth;            // 2026-04-01
date.firstDayOfWeek();               // 2026-03-16 (weeks start on Monday by default)
date.lastDayOfWeek(start: Weekday.sunday);  // 2026-03-21 (a week starting on Sunday ends on Saturday)
date.next(Weekday.wednesday);        // 2026-03-25 (strictly after; `orSame: true` to include the date itself)
date.previous(Weekday.monday);       // 2026-03-16

// Comparison
date < Date(2026, 4, 1);             // true (also <=, >, >=)
date.isAtSameMonthAs(Date(2026, 3, 1));  // true
final Date? deadline = Date.tryParse('2026-04-01');
deadline?.isAfterOrSame(date) ?? true;   // operators can't be used with `?.`, named methods can
```

Dates are immutable, comparable, and can be used as `Map` keys or in a `Set`.

### Time

```dart
final time = Time(18, 30);           // seconds are optional: Time(18, 30, 15)
Time.tryCreate(24, 0);               // null
Time.now();
Time.midnight;                       // Time.noon

time.minutesSinceMidnight;           // 1110
time < Time(20, 0);                  // true
time.toString();                     // '18:30' ('18:30:15' when seconds are not 0)
```

### Parsing and JSON

Both types parse and print strict ISO 8601 strings, and expose `toJson()` / `fromJson(String)`.

```dart
Date.parse('2026-03-21');            // throws FormatException on any other format
Date.tryParse('21/03/2026');         // null
Date.tryParse('2026-02-30');         // null (the date doesn't exist)
Time.parse('18:30');                 // also accepts 'HH:mm:ss'

Date(2026, 3, 21).toJson();          // '2026-03-21'
Date.fromJson('2026-03-21');
```

### DateTime interop

```dart
final dateTime = DateTime(2026, 3, 21, 18, 30);

dateTime.toDate();                   // 2026-03-21
dateTime.toTime();                   // 18:30

date.toDateTime();                   // 2026-03-21 00:00, local
date.toDateTime(time: time);         // 2026-03-21 18:30, local
date.toDateTime(time: time, utc: true);
```

`DateTime` also gets comparison helpers, handy on timestamps:

```dart
a.isAtSameDayAs(b);                  // also isAtSameMonthAs, isAtSameYearAs
a.isAfterOrSame(b);                  // also isBeforeOrSame
```

> **No time zone conversion.** `toDate()` and `toTime()` read the fields of the `DateTime` as they are: a UTC
> `DateTime` gives its UTC date, a local one its local date. The `isAtSame...As` helpers do the same. If your values
> are not in the same time zone, call `toLocal()` or `toUtc()` on them first.

## Design notes

- **Strict by default.** `Date(2026, 12, 32)` throws instead of returning January 1st, 2027, because an invalid date coming from a
  form or an API is a bug you want to see. When you do want `DateTime`'s overflow behavior (e.g. "day 0 of next month"), ask for it
  explicitly with `Date.rollover(2026, 12, 32)`.
- **Exact day counts.** Calendar computations go through `DateTime.utc`, which has no daylight saving time. With plain local
  `DateTime`s, `DateTime(2026, 4, 1).difference(DateTime(2026, 3, 25)).inDays` is 6 in Europe, because of the lost hour of
  the March change. `Date(2026, 3, 25).daysUntil(Date(2026, 4, 1))` is always 7.
- **Supported years: 1 to 9999**, so that every date prints as `yyyy-MM-dd` and parses back.
- **Unusable values never leak.** There is no way to build an invalid `Date` or `Time`.

## Not included

- Localized formatting (`dd/MM/yyyy`, day names): use [`intl`](https://pub.dev/packages/intl) with `date.toDateTime()`.
- Durations: use Dart's `Duration`.
- Time zones: `Date` and `Time` are deliberately zone-less.

## License

BSD 3-Clause, see [LICENSE](LICENSE).
