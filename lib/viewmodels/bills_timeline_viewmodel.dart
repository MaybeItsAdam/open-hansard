import 'package:flutter/foundation.dart';

import '../services/parliamentary_data_service.dart';

/// Represents a single bill or law entry on the timeline.
class BillTimelineItem {
  final int id;
  final String title;
  final String house;
  final String? originatingHouse;
  final String? stageDescription;
  final DateTime? lastUpdate; // Exact Royal Assent date
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
    this.isAct = true,
    this.isDefeated = false,
    this.isWithdrawn = false,
  });

  factory BillTimelineItem.fromJson(Map<String, dynamic> json) {
    final currentStage = json['currentStage'] as Map<String, dynamic>?;
    final stageSittings = currentStage?['stageSittings'] as List?;
    String? dateRaw;
    if (stageSittings != null && stageSittings.isNotEmpty) {
      final firstSitting = stageSittings.first as Map<String, dynamic>?;
      dateRaw = firstSitting?['date'] as String?;
    }
    dateRaw ??= json['lastUpdate'] as String?;

    final stageDesc = currentStage?['description'] as String?;
    final isActFlag = (json['isAct'] == true) ||
        (stageDesc != null && stageDesc.toLowerCase().contains('royal assent')) ||
        ((json['shortTitle'] as String?)?.contains('Act') ?? false);

    return BillTimelineItem(
      id: (json['billId'] as num?)?.toInt() ?? 0,
      title: (json['shortTitle'] as String?) ?? '',
      house: (json['currentHouse'] as String?) ?? '',
      originatingHouse: (json['originatingHouse'] as String?),
      stageDescription: stageDesc ?? 'Royal Assent',
      lastUpdate: dateRaw != null ? DateTime.tryParse(dateRaw) : null,
      isAct: isActFlag,
      isDefeated: json['isDefeated'] == true,
      isWithdrawn: json['billWithdrawn'] != null,
    );
  }
}

/// ViewModel for the Bills & Laws Timeline screen.
/// Loads UK Acts of Parliament ordered strictly by actual Royal Assent date (newest 2026 at bottom,
/// scrolling UP into history).
class BillsTimelineViewModel extends ChangeNotifier {
  final ParliamentaryDataService _service;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _disposed = false;
  String? _error;

  int _totalFetched = 0;
  final bool _ascending = false; // False = DateUpdatedDescending
  String _houseFilter = 'All'; // 'All', 'Commons', 'Lords'
  bool _actsOnly = true; // Royal Assent only
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
    _totalFetched = 0;
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
      _totalFetched = raw.length;

      final parsed = raw
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

      // Sort strictly by actual Royal Assent date (newest first at index 0 for reverse ListView)
      parsed.sort((a, b) {
        final da = a.lastUpdate ?? DateTime(1900);
        final db = b.lastUpdate ?? DateTime(1900);
        return db.compareTo(da);
      });

      _bills = parsed;
      _hasMore = raw.length >= 40;
      if (_bills.isEmpty) {
        _error = "No Royal Assent acts found matching your criteria.";
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    _safeNotify();
  }

  /// Appends older Acts to the list when scrolling UP near maxScrollExtent.
  Future<bool> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return false;

    _isLoadingMore = true;
    _safeNotify();

    bool added = false;
    try {
      final raw = await _service.fetchBillsTimeline(
        skip: _totalFetched,
        take: 40,
        ascending: _ascending,
        house: _houseFilter,
        actsOnly: _actsOnly,
        searchTerm: _searchQuery,
      );
      _totalFetched += raw.length;

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

      more.sort((a, b) {
        final da = a.lastUpdate ?? DateTime(1900);
        final db = b.lastUpdate ?? DateTime(1900);
        return db.compareTo(da);
      });

      if (more.isNotEmpty) {
        _bills.addAll(more);
        added = true;
      }
      _hasMore = raw.length >= 40;
    } catch (e) {
      // Fail silently on loadMore
    }

    _isLoadingMore = false;
    _safeNotify();
    return added;
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
