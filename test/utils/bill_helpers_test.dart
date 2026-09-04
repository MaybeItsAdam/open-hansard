import 'package:flutter_test/flutter_test.dart';
import 'package:open_parliament/utils/bill_helpers.dart';

void main() {
  group('bill_helpers', () {
    test('detectBillTitle extracts qualified bill titles', () {
      expect(
        detectBillTitle('Renters (Reform) Bill: Second Reading'),
        'Renters (Reform) Bill',
      );
      expect(
        detectBillTitle('Crown Estate Bill [Lords]: Second Reading'),
        'Crown Estate Bill',
      );
      expect(
        detectBillTitle('High Speed Rail (Crewe - Manchester) Bill'),
        'High Speed Rail (Crewe - Manchester) Bill',
      );
      expect(detectBillTitle('Bill of Rights'), null);
      expect(detectBillTitle('Oral Answers to Questions'), null);
    });

    test('detectBillStage identifies parliamentary bill stages', () {
      expect(
        detectBillStage('Crime and Policing Bill: First Reading'),
        '1st Reading',
      );
      expect(
        detectBillStage('Finance Bill: Second Reading'),
        '2nd Reading',
      );
      expect(
        detectBillStage('Data Protection Bill: Public Bill Committee'),
        'Committee',
      );
      expect(
        detectBillStage('Tobacco and Vapes Bill: Report Stage'),
        'Report Stage',
      );
      expect(
        detectBillStage('Renters Reform Bill: Read the Third time'),
        '3rd Reading',
      );
      expect(
        detectBillStage('Crown Estate Bill: Consideration of Lords Amendments'),
        'Lords Amendments',
      );
      expect(
        detectBillStage('High Speed Rail Bill: Royal Assent'),
        'Royal Assent',
      );
      expect(
        detectBillStage('Oral Answers to Questions'),
        null,
      );
    });

    test('isCompactDebateItem correctly classifies short/procedural items', () {
      expect(
        isCompactDebateItem(
          durationMinutes: 1,
          contributionCount: 1,
          title: 'Private Members’ Bills: First Reading',
        ),
        true,
      );
      expect(
        isCompactDebateItem(
          durationMinutes: 0,
          contributionCount: 0,
          title: 'Royal Assent',
        ),
        true,
      );
      expect(
        isCompactDebateItem(
          durationMinutes: 1,
          contributionCount: 1,
          title: 'Petitions',
        ),
        true,
      );
      expect(
        isCompactDebateItem(
          durationMinutes: 90,
          contributionCount: 45,
          title: 'Renters (Reform) Bill: Second Reading',
        ),
        false,
      );
    });
  });
}
