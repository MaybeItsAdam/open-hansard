/// Model representing a UK Parliamentary Standing Order (House of Commons or House of Lords).
class StandingOrder {
  final String id;
  final String house; // 'Commons' or 'Lords'
  final String number; // e.g. '24', '14', '47', '163'
  final String title;
  final String category; // e.g. 'Sittings & Adjournment', 'Debate & Order', 'Public Business'
  final String summary;
  final String? officialUrl;

  const StandingOrder({
    required this.id,
    required this.house,
    required this.number,
    required this.title,
    required this.category,
    required this.summary,
    this.officialUrl,
  });

  /// Display label, e.g. "Standing Order No. 24"
  String get displayLabel => 'Standing Order No. $number';

  /// Short code, e.g. "SO 24"
  String get shortCode => 'SO $number';
}
