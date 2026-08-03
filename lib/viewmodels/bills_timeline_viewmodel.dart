import 'package:flutter/foundation.dart';

import '../services/parliamentary_data_service.dart';

/// Represents a single bill or law entry on the timeline.
class BillTimelineItem {
  final int id;
  final String title;
  final String house;
  final String? originatingHouse;
  final String? stageDescription;
  final DateTime? lastUpdate;
  final bool isAct;
  final bool isDefeated;
  final bool isWithdrawn;

  const BillTimelineItem({
    required this.id,
    required this.title,
    required this.house,
    this.originatingHouse,
    this.stageDescription,
    this.lastUpdate,
    this.isAct = false,
    this.isDefeated = false,
    this.isWithdrawn = false,
  });

  factory BillTimelineItem.fromJson(Map<String, dynamic> json) {
    final currentStage = json['currentStage'] as Map<String, dynamic>?;
    final lastRaw = json['lastUpdate'] as String?;
    final stageDesc = currentStage?['description'] as String?;
    final isActFlag = (json['isAct'] == true) ||
        (stageDesc != null && stageDesc.toLowerCase().contains('royal assent'));

    return BillTimelineItem(
      id: (json['billId'] as num?)?.toInt() ?? 0,
      title: (json['shortTitle'] as String?) ?? '',
      house: (json['currentHouse'] as String?) ?? '',
      originatingHouse: (json['originatingHouse'] as String?),
      stageDescription: stageDesc,
      lastUpdate: lastRaw != null ? DateTime.tryParse(lastRaw) : null,
      isAct: isActFlag,
      isDefeated: json['isDefeated'] == true,
      isWithdrawn: json['billWithdrawn'] != null,
    );
  }
}

/// ViewModel for the Bills Timeline screen.
/// Manages loading, pagination, sorting (past -> today vs today -> past), house/acts filtering, and search.
class BillsTimelineViewModel extends ChangeNotifier {
  final ParliamentaryDataService _service;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _disposed = false;
  String? _error;

  bool _ascending = true; // Default: past at top -> going down to today
  String _houseFilter = 'All'; // 'All', 'Commons', 'Lords'
  bool _actsOnly = false;
  String _searchQuery = '';

  List<BillTimelineItem> _bills = [];

  BillsTimelineViewModel(this._service);

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get ascending => _ascending;
  String get houseFilter => _houseFilter;
  bool get actsOnly => _actsOnly;
  String get searchQuery => _searchQuery;
  List<BillTimelineItem> get bills => _bills;

  void toggleOrder() {
    _ascending = !_ascending;
    load();
  }

  void setHouseFilter(String house) {
    if (_houseFilter == house) return;
    _houseFilter = house;
    load();
  }

  void setActsOnly(bool value) {
    if (_actsOnly == value) return;
    _actsOnly = value;
    load();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    _hasMore = true;
    _error = null;
    _safeNotify();

    try {
      final raw = await _service.fetchBillsTimeline(
        skip: 0,
        take: 40,
        ascending: _ascending,
        house: _houseFilter,
        actsOnly: _actsOnly,
        searchTerm: _searchQuery,
      );
      _bills = raw
          .map((json) {
            try {
              return BillTimelineItem.fromJson(json);
            } catch (_) {
              return null;
            }
          })
          .whereType<BillTimelineItem>()
          .where((b) => b.id != 0 && b.title.isNotEmpty)
          .toList();
      _hasMore = raw.length >= 40;
      if (_bills.isEmpty) {
        _error = "No bills found matching your criteria.";
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _safeNotify();

    try {
      final skip = _bills.length;
      final raw = await _service.fetchBillsTimeline(
        skip: skip,
        take: 40,
        ascending: _ascending,
        house: _houseFilter,
        actsOnly: _actsOnly,
        searchTerm: _searchQuery,
      );

      final more = raw
          .map((json) {
            try {
              return BillTimelineItem.fromJson(json);
            } catch (_) {
              return null;
            }
          })
          .whereType<BillTimelineItem>()
          .where((b) => b.id != 0 && b.title.isNotEmpty)
          .toList();

      _bills.addAll(more);
      _hasMore = raw.length >= 40;
    } catch (e) {
      // Fail silently on loadMore
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
