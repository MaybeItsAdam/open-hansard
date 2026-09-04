import '../viewmodels/date_selector_viewmodel.dart';

/// Pure helper functions for detecting bills, bill stages, and classifying
/// debate items for UI presentation.

/// Detects the canonical bill stage (e.g. '1st Reading', '2nd Reading') from a
/// debate [title], or returns `null` if the title does not specify a stage.
String? detectBillStage(String title) {
  final t = title.toLowerCase();
  if (t.contains('first reading') || t.contains('read the first time')) {
    return '1st Reading';
  }
  if (t.contains('second reading') || t.contains('read a second time')) {
    return '2nd Reading';
  }
  if (t.contains('committee stage') ||
      t.contains('public bill committee') ||
      t.contains('committee of the whole house')) {
    return 'Committee';
  }
  if (t.contains('report stage') || t.contains('as amended')) {
    return 'Report Stage';
  }
  if (t.contains('third reading') || t.contains('read the third time')) {
    return '3rd Reading';
  }
  if (t.contains('lords amendment') ||
      t.contains('consideration of lords amendment')) {
    return 'Lords Amendments';
  }
  if (t.contains('royal assent')) {
    return 'Royal Assent';
  }
  if (t.contains('allocation of time') || t.contains('programme motion')) {
    return 'Programme';
  }
  return null;
}

/// Returns true if [title] matches common procedural business titles.
bool isProceduralTitle(String title) {
  final t = title.trim().toLowerCase();
  return t == 'royal assent' ||
      t == 'petitions' ||
      t.startsWith('written statement') ||
      t.startsWith('written ministerial statement') ||
      t.contains('laying of papers') ||
      t.contains('business statement') ||
      t.contains('business of the house') ||
      t.contains('speaker’s statement') ||
      t.contains('speaker\'s statement') ||
      t.contains('points of order');
}

/// Returns true if a debate feed item should be rendered in a compact layout
/// rather than a full height-scaled debate card.
bool isCompactDebateItem({
  required int durationMinutes,
  required int contributionCount,
  required String title,
}) {
  final stage = detectBillStage(title);
  if (stage == '1st Reading' || stage == 'Royal Assent') {
    return true;
  }
  if (isProceduralTitle(title)) {
    return true;
  }
  if (durationMinutes <= 2 &&
      contributionCount <= 2 &&
      detectBillTitle(title) == null &&
      !title.toLowerCase().contains('motion')) {
    return true;
  }
  return false;
}

/// Extracts a qualified bill title from [title] (delegates to
/// [DateSelectorViewModel.detectBillTitle]).
String? detectBillTitle(String title) {
  return DateSelectorViewModel.detectBillTitle(title);
}
