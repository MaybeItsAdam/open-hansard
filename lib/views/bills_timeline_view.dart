import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/parliamentary_data_service.dart';
import '../utils/house_colors.dart';
import '../viewmodels/bills_timeline_viewmodel.dart';
import 'app_drawer.dart';
import 'bill_view.dart';

/// Timeline-first screen displaying UK Acts of Parliament (Royal Assent).
/// Anchored at the bottom with the latest 2026 Acts, allowing the user to scroll UP
/// into historical legislation and PINCH TO SCALE the timeline vertically.
class BillsTimelineView extends StatefulWidget {
  const BillsTimelineView({super.key});

  @override
  State<BillsTimelineView> createState() => _BillsTimelineViewState();
}

class _BillsTimelineViewState extends State<BillsTimelineView> {
  late BillsTimelineViewModel _vm;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Vertical scale state for pinch-to-scale gesture
  double _verticalScale = 1.0;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _vm = BillsTimelineViewModel(context.read<ParliamentaryDataService>());
    _scrollController.addListener(_onScroll);
    unawaited(_vm.load());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    _vm.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Trigger loadMore (fetching older past Acts up top) when scrolling UP near maxScrollExtent
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        !_vm.isLoadingMore &&
        _vm.hasMore) {
      unawaited(_vm.loadMore());
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _verticalScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Determine scaling factor from vertical pinch or general scale
    final factor = details.verticalScale != 1.0 ? details.verticalScale : details.scale;
    final newScale = (_baseScale * factor).clamp(0.4, 2.5);
    if ((newScale - _verticalScale).abs() > 0.01) {
      setState(() {
        _verticalScale = newScale;
      });
    }
  }

  void _zoomIn() {
    setState(() {
      _verticalScale = (_verticalScale + 0.25).clamp(0.4, 2.5);
    });
  }

  void _zoomOut() {
    setState(() {
      _verticalScale = (_verticalScale - 0.25).clamp(0.4, 2.5);
    });
  }

  void _resetZoom() {
    setState(() {
      _verticalScale = 1.0;
    });
  }

  Future<void> _confirmClearDownloads(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Law Downloads?'),
        content: const Text(
          'Downloaded bills, acts and law details will be deleted from this device and re-fetched fresh from the API.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _vm.clearCache();
    messenger.showSnackBar(
      const SnackBar(content: Text('Cleared cached bills & laws data.')),
    );
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _vm.setSearchQuery(value);
    });
  }

  Color _houseColor(String house) => switch (house.toLowerCase()) {
        'lords' => HouseColors.lords,
        'commons' => HouseColors.commons,
        _ => HouseColors.mixed,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.history_edu),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Acts of Parliament Timeline",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Delete Downloaded Law Data",
            onPressed: () => _confirmClearDownloads(context),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: "Zoom Out Timeline Scale",
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: "Zoom In Timeline Scale",
            onPressed: _zoomIn,
          ),
          if (_verticalScale != 1.0)
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: "Reset Scale",
              onPressed: _resetZoom,
            ),
        ],
      ),
      drawer: const AppDrawer(current: AppDestination.billsTimeline),
      body: ChangeNotifierProvider.value(
        value: _vm,
        child: Consumer<BillsTimelineViewModel>(
          builder: (context, vm, _) {
            return Column(
              children: [
                _buildHeaderControls(context, vm, theme),
                Expanded(
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : vm.bills.isEmpty
                          ? _buildEmpty(context, vm)
                          : GestureDetector(
                              onScaleStart: _onScaleStart,
                              onScaleUpdate: _onScaleUpdate,
                              behavior: HitTestBehavior.translucent,
                              child: RefreshIndicator(
                                onRefresh: vm.load,
                                child: _buildTimelineList(context, vm, theme),
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderControls(
    BuildContext context,
    BillsTimelineViewModel vm,
    ThemeData theme,
  ) {
    final scalePercent = (_verticalScale * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search Royal Assent Acts…",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        vm.setSearchQuery('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: 8),
          // Filter Chips & Scale Indicator Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Scale indicator chip
                ActionChip(
                  avatar: const Icon(Icons.unfold_more, size: 14, color: Colors.amber),
                  label: Text(
                    "Pinch to Scale: $scalePercent%",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _resetZoom,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                // Direction Indicator Chip
                const Chip(
                  avatar: Icon(Icons.south, size: 14, color: Colors.amber),
                  label: Text(
                    "Latest (2026) at Bottom · Scroll UP for History",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                // House Filter Chips
                ...['All', 'Commons', 'Lords'].map((h) {
                  final isSelected = vm.houseFilter == h;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(h),
                      selected: isSelected,
                      onSelected: (sel) {
                        if (sel) vm.setHouseFilter(h);
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the timeline-first list anchored at the bottom using [reverse: true]
  /// with dynamic vertical scaling.
  Widget _buildTimelineList(
    BuildContext context,
    BillsTimelineViewModel vm,
    ThemeData theme,
  ) {
    final totalCount = vm.bills.length + (vm.hasMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Index 0 is at bottom (2026 Acts), higher index at top (older Acts)
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: totalCount,
      itemBuilder: (context, i) {
        // Top loading indicator when scrolling UP towards maxScrollExtent
        if (vm.hasMore && i == vm.bills.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Loading older historical Acts…",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final bill = vm.bills[i];
        final nextBillInHistory = (i + 1 < vm.bills.length) ? vm.bills[i + 1] : null;

        final currentYear = bill.lastUpdate?.year;
        final nextYear = nextBillInHistory?.lastUpdate?.year;
        final showYearDividerAbove = currentYear != null &&
            nextYear != null &&
            currentYear != nextYear;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Act Card popping up on timeline
            _buildTimelineItem(context, bill, theme),
            // Year Divider on timeline spine as we move into an older year higher up
            if (showYearDividerAbove)
              _buildYearDivider(context, nextYear, theme),
          ],
        );
      },
    );
  }

  Widget _buildYearDivider(BuildContext context, int year, ThemeData theme) {
    final verticalPadding = (16.0 * _verticalScale).clamp(6.0, 36.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade800,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade900.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  "$year",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade800,
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single timeline node & bill pop-up card along the timeline spine,
  /// vertically scaled according to [_verticalScale].
  Widget _buildTimelineItem(
    BuildContext context,
    BillTimelineItem bill,
    ThemeData theme,
  ) {
    final hColor = _houseColor(bill.house);
    final dateStr = bill.lastUpdate != null ? _formatDate(bill.lastUpdate!) : null;

    final bottomPadding = (16.0 * _verticalScale).clamp(4.0, 40.0);
    final cardPaddingVertical = (12.0 * _verticalScale).clamp(4.0, 24.0);
    final nodeSize = (28.0 * (_verticalScale.clamp(0.8, 1.2))).clamp(20.0, 34.0);
    final isCompact = _verticalScale < 0.65;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Vertical Timeline Spine & Date Node ─────────────────────────
          SizedBox(
            width: 48,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Continuous Vertical Timeline Line
                Positioned(
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.amber.shade700,
                          Colors.amber.shade600,
                        ],
                      ),
                    ),
                  ),
                ),
                // Timeline Date Node Icon
                Container(
                  margin: EdgeInsets.only(top: isCompact ? 6 : 14),
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade800,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade900.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.gavel, size: nodeSize * 0.5, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ─── Bill Pop-Up Card Branching off Timeline ──────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Card(
                elevation: 2,
                shadowColor: Colors.amber.shade900.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.amber.shade700.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BillView(billTitle: bill.title, billId: bill.id),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: cardPaddingVertical,
                    ),
                    child: isCompact
                        ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bill.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (dateStr != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  dateStr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline Pop-Up Header: Royal Assent Tag + Date
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.amber.shade600,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 13,
                                          color: Colors.amber.shade900,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "ROYAL ASSENT",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (bill.house.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        bill.house.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: hColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (dateStr != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 12,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateStr,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Act Title
                              Text(
                                bill.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Status Footer
                              Row(
                                children: [
                                  Text(
                                    "Enacted Law of the UK",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: theme.colorScheme.outline,
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, BillsTimelineViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_edu, size: 48),
            const SizedBox(height: 12),
            Text(
              vm.error ?? 'No Royal Assent acts found.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: vm.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
