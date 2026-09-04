import 'package:flutter_test/flutter_test.dart';

import 'package:open_parliament/utils/standing_order_helpers.dart';
import 'package:open_parliament/utils/standing_orders_data.dart';

void main() {
  group('StandingOrdersData', () {
    test('contains Commons and Lords Standing Orders', () {
      expect(StandingOrdersData.allOrders, isNotEmpty);
      final commons =
          StandingOrdersData.allOrders.where((o) => o.house == 'Commons');
      final lords =
          StandingOrdersData.allOrders.where((o) => o.house == 'Lords');

      expect(commons.isNotEmpty, isTrue);
      expect(lords.isNotEmpty, isTrue);
    });

    test('finds standing order by number or alias', () {
      final so24 = StandingOrdersData.find('24');
      expect(so24, isNotNull);
      expect(so24!.title, contains('Emergency debates'));

      final so14 = StandingOrdersData.find('SO 14');
      expect(so14, isNotNull);
      expect(so14!.number, equals('14'));
    });
  });

    group('StandingOrderHelpers', () {
    test('detects Standing Order references in text', () {
      const text1 =
          'I move that the House do now adjourn under Standing Order No. 24.';
      final matches1 = StandingOrderHelpers.detectStandingOrders(text1);
      expect(matches1.length, equals(1));
      expect(matches1.first.number, equals('24'));

      const text2 = 'Pursuant to S.O. No. 163, I spy strangers.';
      final matches2 = StandingOrderHelpers.detectStandingOrders(text2);
      expect(matches2.length, equals(1));
      expect(matches2.first.number, equals('163'));

      const text3 =
          'Debate under Standing Order No. 14 and Standing Order No. 47.';
      final matches3 = StandingOrderHelpers.detectStandingOrders(text3);
      expect(matches3.length, equals(2));
    });

    test('returns empty list for text with no Standing Orders', () {
      const text = 'Ordinary speech with no procedural rules mentioned.';
      final matches = StandingOrderHelpers.detectStandingOrders(text);
      expect(matches, isEmpty);
    });
  });
}
