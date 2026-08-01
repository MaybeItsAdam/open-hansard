/// A named period during which a house of Parliament does not sit — a recess
/// (e.g. *"Summer recess"*), a holiday adjournment, or a dissolution — as
/// returned by the What's On API's non-sitting-days endpoint.
class RecessPeriod {
  /// Human-readable name, e.g. `"Summer recess"`. Never empty: when the API
  /// omits a description, falls back to a name inferred from the period's
  /// position/length in the year (see [_inferName]), or `"Recess"` if even
  /// that doesn't confidently match a known recess.
  final String description;

  /// First non-sitting day of the period, normalised to midnight.
  final DateTime startDate;

  /// Last non-sitting day of the period (inclusive), normalised to midnight.
  final DateTime endDate;

  /// The house the period applies to (`Commons` or `Lords`); may be empty.
  final String house;

  const RecessPeriod({
    required this.description,
    required this.startDate,
    required this.endDate,
    this.house = '',
  });

  /// Whether [day] falls within the period (any time component is ignored).
  bool contains(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(startDate) && !d.isAfter(endDate);
  }

  /// Parses one event object from `/calendar/events/nonsitting.json`.
  ///
  /// Tolerates both PascalCase and camelCase keys (the What's On API uses
  /// PascalCase, but be liberal in what we accept). Returns `null` when no
  /// start date can be parsed; a missing end date yields a single-day period.
  /// [fallbackHouse] is used when the payload carries no house of its own
  /// (the caller knows which house it queried for).
  static RecessPeriod? fromApiJson(
    Map<String, dynamic> json, {
    String fallbackHouse = '',
  }) {
    final start = _parseDate(json['StartDate'] ?? json['startDate']);
    if (start == null) return null;
    final end = _parseDate(json['EndDate'] ?? json['endDate']) ?? start;

    final description =
        ((json['Description'] ?? json['description']) as String?)?.trim() ??
            '';
    final house = ((json['House'] ?? json['house']) as String?)?.trim() ?? '';
    // Guard against a malformed payload where the range is inverted.
    final clampedEnd = end.isBefore(start) ? start : end;

    return RecessPeriod(
      description: description.isEmpty
          ? _inferName(start, clampedEnd) ?? 'Recess'
          : description,
      startDate: start,
      endDate: clampedEnd,
      house: house.isEmpty ? fallbackHouse : house,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Best-effort name for a recess the What's On API left undescribed,
  /// inferred from where in the year it falls and how long it runs — the
  /// same fixed annual pattern published on the Commons
  /// ("parliament.uk/.../recess-dates") and Lords ("lordswhips.org.uk/
  /// recess-dates") recess-dates pages. Returns `null` (rather than guessing)
  /// when the shape doesn't confidently match one of those known recesses,
  /// e.g. a single stray non-sitting day with no end date.
  static String? _inferName(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;

    if (start.month == 12 && days >= 10) return 'Christmas recess';
    if (start.month == 2 && days >= 5 && days <= 15) return 'February recess';
    if ((start.month == 3 || start.month == 4) &&
        (end.month == 3 || end.month == 4) &&
        days >= 8) {
      return 'Easter recess';
    }
    if (start.month == 5 && start.day <= 10 && days <= 6) {
      return 'Early May recess';
    }
    if ((start.month == 5 && start.day >= 15 || start.month == 6) &&
        days >= 5 &&
        days <= 12) {
      return 'Whitsun recess';
    }
    if ((start.month == 7 || start.month == 8) && days >= 20) {
      return 'Summer recess';
    }
    if ((start.month == 9 || start.month == 10) && days >= 15) {
      return 'Conference recess';
    }
    if (start.month == 11 && days <= 10) return 'November recess';

    return null;
  }
}
