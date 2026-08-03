import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/parliamentary_data_service.dart';
import '../utils/house_colors.dart';
import '../viewmodels/bills_timeline_viewmodel.dart';
import 'app_drawer.dart';
import 'bill_view.dart';

/// Interactive timeline screen displaying UK bills and laws chronologically
/// from past to today.
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      unawaited(_vm.loadMore());
    }
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
            Icon(Icons.timeline_outlined),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Bills & Laws Timeline",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _vm.ascending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: _vm.ascending ? "Past → Today" : "Today → Past",
            onPressed: () => setState(() => _vm.toggleOrder()),
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
                          : RefreshIndicator(
                              onRefresh: vm.load,
                              child: _buildTimelineList(context, vm, theme),
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
              hintText: "Search timeline bills or laws…",
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
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Direction indicator chip
                FilterChip(
                  avatar: Icon(
                    vm.ascending
                        ? Icons.south_outlined
                        : Icons.north_outlined,
                    size: 16,
                  ),
                  label: Text(
                    vm.ascending ? "Past → Today" : "Today → Past",
                  ),
                  selected: true,
                  onSelected: (_) => setState(() => vm.toggleOrder()),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                // Acts Only chip
                FilterChip(
                  avatar: const Icon(Icons.gavel_outlined, size: 16),
                  label: const Text("Acts only (Laws)"),
                  selected: vm.actsOnly,
                  onSelected: (val) => vm.setActsOnly(val),
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

  Widget _buildTimelineList(
    BuildContext context,
    BillsTimelineViewModel vm,
    ThemeData theme,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: vm.bills.length + (vm.hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == vm.bills.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final bill = vm.bills[i];
        final prevBill = i > 0 ? vm.bills[i - 1] : null;

        final currentYear = bill.lastUpdate?.year;
        final prevYear = prevBill?.lastUpdate?.year;
        final showYearHeader = currentYear != null && currentYear != prevYear;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showYearHeader) _buildYearHeader(context, currentYear, theme),
            _buildTimelineItemCard(context, bill, theme, isLast: i == vm.bills.length - 1),
          ],
        );
      },
    );
  }

  Widget _buildYearHeader(BuildContext context, int year, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "$year",
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItemCard(
    BuildContext context,
    BillTimelineItem bill,
    ThemeData theme, {
    required bool isLast,
  }) {
    final hColor = _houseColor(bill.house);
    final isAct = bill.isAct;

    // Node icon & colors
    final nodeColor = isAct
        ? Colors.amber.shade700
        : (bill.isDefeated || bill.isWithdrawn
            ? theme.colorScheme.error
            : hColor);

    final nodeIcon = isAct
        ? Icons.gavel
        : (bill.isDefeated || bill.isWithdrawn
            ? Icons.cancel_outlined
            : Icons.article_outlined);

    final dateStr = bill.lastUpdate != null ? _formatDate(bill.lastUpdate!) : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Axis (Line + Node Dot)
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Connecting Vertical Line
                Positioned(
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                // Node Dot/Icon
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: nodeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                  ),
                  child: Icon(nodeIcon, size: 12, color: nodeColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isAct
                        ? Colors.amber.shade600.withValues(alpha: 0.4)
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BillView(billTitle: bill.title, billId: bill.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header tags & Date
                        Row(
                          children: [
                            if (isAct) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: Colors.amber.shade900,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "ACT OF PARLIAMENT",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (bill.house.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: hColor.withValues(alpha: 0.12),
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
                              const SizedBox(width: 6),
                            ],
                            const Spacer(),
                            if (dateStr != null)
                              Text(
                                dateStr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          bill.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (bill.stageDescription != null &&
                            bill.stageDescription!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  bill.stageDescription!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
            const Icon(Icons.timeline_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              vm.error ?? 'No bills found for the selected criteria.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => unawaited(vm.load()),
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
