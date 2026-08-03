import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/parliamentary_data_service.dart';
import '../utils/house_colors.dart';
import '../viewmodels/bills_timeline_viewmodel.dart';
import 'app_drawer.dart';
import 'bill_view.dart';

/// Interactive timeline screen displaying UK Acts of Parliament (Royal Assent).
/// Starts at the bottom with the latest Acts, allowing the user to scroll UP
/// indefinitely into historical legislation.
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
  bool _hasScrolledToBottomInitially = false;

  @override
  void initState() {
    super.initState();
    _vm = BillsTimelineViewModel(context.read<ParliamentaryDataService>());
    _scrollController.addListener(_onScroll);
    unawaited(_loadInitialData());
  }

  Future<void> _loadInitialData() async {
    await _vm.load();
    if (mounted && _vm.bills.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _hasScrolledToBottomInitially = true;
    }
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
    // Trigger loadMore (fetching older past Acts) when user scrolls UP near top
    if (_scrollController.position.pixels <= 250 &&
        !_vm.isLoadingMore &&
        _vm.hasMore) {
      _fetchOlderActs();
    }
  }

  Future<void> _fetchOlderActs() async {
    if (!_scrollController.hasClients) return;
    final oldMaxScroll = _scrollController.position.maxScrollExtent;
    final oldPixels = _scrollController.position.pixels;

    final added = await _vm.loadMore();

    if (added && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newMaxScroll = _scrollController.position.maxScrollExtent;
          final delta = newMaxScroll - oldMaxScroll;
          if (delta > 0) {
            _scrollController.jumpTo(oldPixels + delta);
          }
        }
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _hasScrolledToBottomInitially = false;
      _vm.setSearchQuery(value);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
            icon: const Icon(Icons.vertical_align_bottom),
            tooltip: "Jump to Latest Acts (Bottom)",
            onPressed: _scrollToBottom,
          ),
        ],
      ),
      drawer: const AppDrawer(current: AppDestination.billsTimeline),
      body: ChangeNotifierProvider.value(
        value: _vm,
        child: Consumer<BillsTimelineViewModel>(
          builder: (context, vm, _) {
            if (!vm.isLoading &&
                vm.bills.isNotEmpty &&
                !_hasScrolledToBottomInitially) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }

            return Column(
              children: [
                _buildHeaderControls(context, vm, theme),
                Expanded(
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : vm.bills.isEmpty
                          ? _buildEmpty(context, vm)
                          : RefreshIndicator(
                              onRefresh: () async {
                                _hasScrolledToBottomInitially = false;
                                await vm.load();
                                _scrollToBottom();
                              },
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
              hintText: "Search Royal Assent Acts…",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _hasScrolledToBottomInitially = false;
                        vm.setSearchQuery('');
                        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
                // Royal Assent Only Chip
                FilterChip(
                  avatar: const Icon(Icons.gavel, size: 16, color: Colors.amber),
                  label: const Text("Royal Assent (Acts of Parliament)"),
                  selected: vm.actsOnly,
                  onSelected: (val) {
                    _hasScrolledToBottomInitially = false;
                    vm.setActsOnly(val);
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  },
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
                        if (sel) {
                          _hasScrolledToBottomInitially = false;
                          vm.setHouseFilter(h);
                          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                        }
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
        // Top spinner when loading older Acts up top
        if (vm.hasMore && i == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final billIndex = vm.hasMore ? i - 1 : i;
        final bill = vm.bills[billIndex];
        final prevBill = billIndex > 0 ? vm.bills[billIndex - 1] : null;

        final currentYear = bill.lastUpdate?.year;
        final prevYear = prevBill?.lastUpdate?.year;
        final showYearHeader = currentYear != null && currentYear != prevYear;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showYearHeader) _buildYearHeader(context, currentYear, theme),
            _buildTimelineItemCard(
              context,
              bill,
              theme,
              isLast: billIndex == vm.bills.length - 1,
            ),
          ],
        );
      },
    );
  }

  Widget _buildYearHeader(BuildContext context, int year, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  "$year",
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Colors.amber.shade700.withValues(alpha: 0.4),
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

    // Royal Assent Node styling
    const nodeIcon = Icons.gavel;

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
                    color: Colors.amber.shade700.withValues(alpha: 0.5),
                  ),
                ),
                // Node Dot/Icon
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade300, width: 2),
                  ),
                  child: const Icon(nodeIcon, size: 12, color: Colors.white),
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.amber.shade600.withValues(alpha: 0.5),
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
                                    "ROYAL ASSENT",
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
                                Icons.verified_outlined,
                                size: 14,
                                color: Colors.amber.shade800,
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
            const Icon(Icons.history_edu, size: 48),
            const SizedBox(height: 12),
            Text(
              vm.error ?? 'No Royal Assent acts found.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                _hasScrolledToBottomInitially = false;
                await vm.load();
                _scrollToBottom();
              },
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
