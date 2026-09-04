import 'package:flutter_test/flutter_test.dart';
import 'package:open_parliament/models/recess_period.dart';

void main() {
  group('RecessPeriod.fromApiJson', () {
    test('parses a PascalCase What\'s On event', () {
      final period = RecessPeriod.fromApiJson({
        'Description': 'Summer recess',
        'StartDate': '2024-07-30T00:00:00',
        'EndDate': '2024-09-02T00:00:00',
        'House': 'Commons',
      });

      expect(period, isNotNull);
      expect(period!.description, 'Summer recess');
      expect(period.startDate, DateTime(2024, 7, 30));
      expect(period.endDate, DateTime(2024, 9, 2));
      expect(period.house, 'Commons');
    });

    test('accepts camelCase keys', () {
      final period = RecessPeriod.fromApiJson({
        'description': 'Whitsun recess',
        'startDate': '2024-05-23',
        'endDate': '2024-06-03',
        'house': 'Lords',
      });

      expect(period, isNotNull);
      expect(period!.description, 'Whitsun recess');
      expect(period.startDate, DateTime(2024, 5, 23));
      expect(period.endDate, DateTime(2024, 6, 3));
      expect(period.house, 'Lords');
    });

    test('normalises time components to midnight', () {
      final period = RecessPeriod.fromApiJson({
        'StartDate': '2024-07-30T09:30:00',
        'EndDate': '2024-09-02T17:00:00',
      });

      expect(period!.startDate, DateTime(2024, 7, 30));
      expect(period.endDate, DateTime(2024, 9, 2));
    });

    test('falls back to "Recess" and the queried house when omitted', () {
      final period = RecessPeriod.fromApiJson(
        {'StartDate': '2024-07-30T00:00:00'},
        fallbackHouse: 'Commons',
      );

      expect(period!.description, 'Recess');
      expect(period.house, 'Commons');
      // Missing end date yields a single-day period.
      expect(period.endDate, period.startDate);
    });

    group('infers a name when the API omits Description', () {
      void expectInferred(String start, String end, String name) {
        final period = RecessPeriod.fromApiJson({
          'StartDate': start,
          'EndDate': end,
        });
        expect(period!.description, name, reason: '$start - $end');
      }

      test('matches each named recess in the published annual pattern', () {
        // Real 2025/2026 Commons non-sitting-day ranges (whatson-api),
        // cross-checked against parliament.uk/.../recess-dates and
        // lordswhips.org.uk/recess-dates.
        expectInferred('2024-12-20', '2025-01-05', 'Christmas recess');
        expectInferred('2025-02-14', '2025-02-23', 'February recess');
        expectInferred('2025-04-09', '2025-04-21', 'Easter recess');
        expectInferred('2025-05-02', '2025-05-05', 'Early May recess');
        expectInferred('2025-05-23', '2025-06-01', 'Whitsun recess');
        expectInferred('2025-07-23', '2025-08-31', 'Summer recess');
        expectInferred('2025-09-17', '2025-10-12', 'Conference recess');
        expectInferred('2025-11-06', '2025-11-10', 'November recess');
        expectInferred('2026-03-27', '2026-04-12', 'Easter recess');
      });

      test('falls back to "Recess" for a shape that matches no pattern', () {
        expectInferred('2025-04-09', '2025-04-09', 'Recess');
      });
    });

    test('returns null without a parsable start date', () {
      expect(RecessPeriod.fromApiJson({'Description': 'X'}), isNull);
      expect(
        RecessPeriod.fromApiJson({'StartDate': 'not-a-date'}),
        isNull,
      );
    });

    test('clamps an inverted range to a single-day period', () {
      final period = RecessPeriod.fromApiJson({
        'StartDate': '2024-09-02T00:00:00',
        'EndDate': '2024-07-30T00:00:00',
      });

      expect(period!.startDate, DateTime(2024, 9, 2));
      expect(period.endDate, DateTime(2024, 9, 2));
    });
  });

  group('RecessPeriod.contains', () {
    final period = RecessPeriod(
      description: 'Summer recess',
      startDate: DateTime(2024, 7, 30),
      endDate: DateTime(2024, 9, 2),
    );

    test('is inclusive of both endpoints', () {
      expect(period.contains(DateTime(2024, 7, 29)), isFalse);
      expect(period.contains(DateTime(2024, 7, 30)), isTrue);
      expect(period.contains(DateTime(2024, 8, 15)), isTrue);
      expect(period.contains(DateTime(2024, 9, 2)), isTrue);
      expect(period.contains(DateTime(2024, 9, 3)), isFalse);
    });

    test('ignores any time component on the queried day', () {
      expect(period.contains(DateTime(2024, 9, 2, 23, 59)), isTrue);
    });
  });
}
