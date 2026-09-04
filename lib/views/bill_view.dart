import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../models/member.dart';
import '../services/parliamentary_data_service.dart';
import '../utils/house_colors.dart';
import '../utils/party_colors.dart' as party_util;
import '../viewmodels/bill_viewmodel.dart';
import 'member_view.dart';

/// Detail page for a single bill.
class BillView extends StatelessWidget {
  final String billTitle;
  final int? billId;

  const BillView({super.key, required this.billTitle, this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.article_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                billTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: BillDetailPane(billTitle: billTitle, billId: billId),
    );
  }
}

/// Reusable scrollable pane displaying full details for a single bill (status,
/// sponsors, progress timeline, latest updates, external link).
///
/// Used directly as the body of [BillView] and embedded as the swipable secondary
/// page in the transcript view when viewing a debate about a bill.
class BillDetailPane extends StatefulWidget {
  final String billTitle;
  final int? billId;

  const BillDetailPane({super.key, required this.billTitle, this.billId});

  @override
  State<BillDetailPane> createState() => _BillDetailPaneState();
}

class _BillDetailPaneState extends State<BillDetailPane> {
  late BillViewModel _vm;
  final ScrollController _scrollController = ScrollController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _vm = BillViewModel(
      context.read<ParliamentaryDataService>(),
      billTitle: widget.billTitle,
      billId: widget.billId,
    );
    unawaited(_vm.load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  Color _houseColor(String? house) {
    return switch (house?.toLowerCase()) {
      'lords' => HouseColors.lords,
      'commons' => HouseColors.commons,
      _ => HouseColors.mixed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<BillViewModel>(
        builder: (context, vm, _) {
          final hColor = _houseColor(vm.bill?.currentHouse);

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.error != null && vm.bill == null) {
            return _buildError(vm);
          }

          return ListView(
            controller: _scrollController,
            children: [
              _buildInfoSection(context, vm),
              if (vm.publications.isNotEmpty)
                _buildPrimaryBillReaderCard(context, vm),
              if (vm.bill?.sponsors.isNotEmpty == true)
                _buildSponsors(context, vm),
              const SizedBox(height: 12),
              _buildTabBar(context, vm),
              if (_selectedTabIndex == 0) ...[
                if (vm.news.isNotEmpty) ...[
                  _sectionHeader(context, 'Latest Updates'),
                  ...vm.news.map((n) => _buildNewsTile(context, n)),
                ],
                if (vm.stages.isNotEmpty) ...[
                  _sectionHeader(context, 'Progress'),
                  ...vm.stages.asMap().entries.map(
                        (e) => _buildStageTile(
                          context,
                          e.value,
                          hColor,
                          isLast: e.key == vm.stages.length - 1,
                        ),
                      ),
                ],
              ] else ...[
                if (vm.publications.isNotEmpty)
                  _buildPublicationsSection(context, vm)
                else
                  _buildEmptyPublicationsState(context),
              ],
              if (vm.billPageUrl != null)
                _buildExternalLink(context, vm),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, BillViewModel vm) {
    final theme = Theme.of(context);
    final pubCount = vm.publications.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SegmentedButton<int>(
        segments: [
          const ButtonSegment<int>(
            value: 0,
            label: Text('Progress & Updates'),
            icon: Icon(Icons.timeline_outlined, size: 16),
          ),
          ButtonSegment<int>(
            value: 1,
            label: Text(
              pubCount > 0
                  ? 'Full Bill & Publications ($pubCount)'
                  : 'Full Bill & Publications',
            ),
            icon: const Icon(Icons.article_outlined, size: 16),
          ),
        ],
        selected: {_selectedTabIndex},
        onSelectionChanged: (newSelection) {
          setState(() => _selectedTabIndex = newSelection.first);
        },
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          selectedBackgroundColor: theme.colorScheme.primaryContainer,
          selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildEmptyPublicationsState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No official publications recorded yet for this Bill.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, BillViewModel vm) {
    final theme = Theme.of(context);
    final bill = vm.bill;
    final title = (bill?.shortTitle.isNotEmpty == true)
        ? bill!.shortTitle
        : widget.billTitle;
    final summary = bill?.summary?.trim() ?? '';
    final longTitle = bill?.longTitle.trim() ?? '';
    final detailRows = <Widget>[];

    if (bill?.originatingHouse.isNotEmpty == true) {
      detailRows.add(
        _detailRow(
          context,
          Icons.flag_outlined,
          'Originating house',
          bill!.originatingHouse,
        ),
      );
    }

    final billType = vm.billType;
    if (billType != null) {
      final value = [
        if (billType.category.isNotEmpty) billType.category,
        if (billType.name.isNotEmpty) billType.name,
      ].join(' · ');
      if (value.isNotEmpty) {
        detailRows.add(
          _detailRow(
            context,
            Icons.local_offer_outlined,
            'Bill type',
            value,
          ),
        );
      }
    }

    if (bill?.formerShortTitle?.trim().isNotEmpty == true) {
      detailRows.add(
        _detailRow(
          context,
          Icons.history,
          'Former title',
          bill!.formerShortTitle!.trim(),
        ),
      );
    }

    final (statusLabel, statusColor) = switch (bill?.status) {
      BillStatus.act => ('Royal Assent — now an Act', HouseColors.commons),
      BillStatus.defeated => ('Defeated', HouseColors.lords),
      BillStatus.withdrawn => ('Withdrawn', theme.colorScheme.outline),
      _ => ('In progress', theme.colorScheme.primary),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(context, statusLabel, statusColor, filled: true),
              if (bill?.currentHouse.isNotEmpty == true)
                _chip(context, bill!.currentHouse, _houseColor(bill.currentHouse)),
              if (bill?.currentStageDescription?.isNotEmpty == true)
                _chip(
                  context,
                  bill!.currentStageDescription!,
                  theme.colorScheme.outline,
                ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
          if (longTitle.isNotEmpty &&
              longTitle.toLowerCase() != summary.toLowerCase() &&
              longTitle.toLowerCase() != title.toLowerCase()) ...[
            const SizedBox(height: 14),
            Text(
              'Full Title',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              longTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          if (detailRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < detailRows.length; i++) ...[
              detailRows[i],
              if (i != detailRows.length - 1) const SizedBox(height: 6),
            ],
          ],
          if (vm.bill?.lastUpdate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.update,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Last updated ${_formatDate(vm.bill!.lastUpdate!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    Color color, {
    bool filled = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSponsors(BuildContext context, BillViewModel vm) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vm.bill!.sponsors.length > 1 ? 'Sponsors' : 'Sponsor',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...vm.bill!.sponsors.map((s) => _buildSponsorRow(context, s)),
        ],
      ),
    );
  }

  Widget _buildSponsorRow(BuildContext context, BillSponsor sponsor) {
    final theme = Theme.of(context);
    final pColor = party_util.partyColor(sponsor.party ?? '');
    final subtitle = [
      if (sponsor.party?.isNotEmpty == true) sponsor.party!,
      if (sponsor.constituency?.isNotEmpty == true) sponsor.constituency!,
    ].join(' · ');

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: pColor.withValues(alpha: 0.2),
            backgroundImage:
                (sponsor.photoUrl != null && sponsor.photoUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(sponsor.photoUrl!)
                    : null,
            child: (sponsor.photoUrl == null || sponsor.photoUrl!.isEmpty)
                ? Icon(Icons.person, color: pColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sponsor.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (sponsor.memberId != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (sponsor.memberId == null) return row;
    return InkWell(
      onTap: () => _openMember(context, sponsor),
      child: row,
    );
  }

  Widget _buildNewsTile(BuildContext context, BillNews news) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.date != null)
            Text(
              _formatDate(news.date!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (news.title.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              news.title,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          if (news.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(news.content, style: theme.textTheme.bodySmall),
          ],
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildStageTile(
    BuildContext context,
    BillStage stage,
    Color hColor, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final dotColor =
        stage.isCurrent ? hColor : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: stage.isCurrent
                        ? Border.all(color: hColor.withValues(alpha: 0.3), width: 4)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: stage.isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (stage.house.isNotEmpty) stage.house,
                        if (stage.date != null) _formatDate(stage.date!),
                        if (stage.isCurrent) 'current stage',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: stage.isCurrent
                            ? hColor
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            stage.isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalLink(BuildContext context, BillViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: OutlinedButton.icon(
        onPressed: () => unawaited(
          launchUrl(vm.billPageUrl!, mode: LaunchMode.externalApplication),
        ),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('View on bills.parliament.uk'),
      ),
    );
  }

  Widget _buildError(BillViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(vm.error ?? 'Could not load bill details.'),
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

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPrimaryBillReaderCard(BuildContext context, BillViewModel vm) {
    final primary = vm.primaryBillPublication;
    if (primary == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final hColor = _houseColor(
      primary.house.isNotEmpty ? primary.house : vm.bill?.currentHouse,
    );

    final htmlFile = primary.htmlFile;
    final htmlLink = primary.htmlLink;
    final pdfFile = primary.pdfFile;
    final pdfLink = primary.pdfLink;

    final readerUrl = htmlFile != null
        ? Uri.parse(htmlFile.getDownloadUrl(primary.id))
        : (htmlLink != null ? Uri.parse(htmlLink.url) : null);

    final pdfUrl = pdfFile != null
        ? Uri.parse(pdfFile.getDownloadUrl(primary.id))
        : (pdfLink != null ? Uri.parse(pdfLink.url) : null);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book, color: hColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Read Full Bill Document',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: hColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (primary.title.isNotEmpty)
                      Text(
                        primary.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Access the official text, clauses, schedules, and full contents of this legislation.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (readerUrl != null)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _openDocumentReader(
                      context,
                      primary.title.isNotEmpty ? primary.title : vm.billTitle,
                      readerUrl,
                    ),
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text(
                      'Read Full Text',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (readerUrl != null && pdfUrl != null)
                const SizedBox(width: 10),
              if (pdfUrl != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hColor,
                    side: BorderSide(color: hColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => unawaited(
                    launchUrl(pdfUrl, mode: LaunchMode.externalApplication),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublicationsSection(BuildContext context, BillViewModel vm) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Full Bill & Publications'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Official text versions, explanatory notes, and committee reports published for this Bill.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...vm.publications.map((pub) => _buildPublicationTile(context, pub)),
      ],
    );
  }

  Widget _buildPublicationTile(BuildContext context, BillPublication pub) {
    final theme = Theme.of(context);
    final pubType = pub.publicationType?.name ?? 'Publication';
    final hColor = _houseColor(pub.house);

    final htmlFile = pub.htmlFile;
    final htmlLink = pub.htmlLink;
    final pdfFile = pub.pdfFile;
    final pdfLink = pub.pdfLink;

    final readerUrl = htmlFile != null
        ? Uri.parse(htmlFile.getDownloadUrl(pub.id))
        : (htmlLink != null ? Uri.parse(htmlLink.url) : null);

    final pdfUrl = pdfFile != null
        ? Uri.parse(pdfFile.getDownloadUrl(pub.id))
        : (pdfLink != null ? Uri.parse(pdfLink.url) : null);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip(context, pubType, hColor, filled: true),
              if (pub.house.isNotEmpty) ...[
                const SizedBox(width: 6),
                _chip(context, pub.house, _houseColor(pub.house)),
              ],
              const Spacer(),
              if (pub.displayDate != null)
                Text(
                  _formatDate(pub.displayDate!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pub.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (readerUrl != null)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _openDocumentReader(
                    context,
                    pub.title,
                    readerUrl,
                  ),
                  icon: const Icon(Icons.auto_stories, size: 16),
                  label: const Text('Read in App'),
                ),
              if (pdfUrl != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => unawaited(
                    launchUrl(pdfUrl, mode: LaunchMode.externalApplication),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('PDF'),
                ),
              for (final link in pub.links)
                if (!link.isHtml && !link.isPdf && link.url.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => unawaited(
                      launchUrl(
                        Uri.parse(link.url),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: Text(
                      link.title.isNotEmpty ? link.title : 'Web Link',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDocumentReader(BuildContext context, String title, Uri url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillDocumentReaderView(
          title: title,
          url: url,
        ),
      ),
    );
  }

  void _openMember(BuildContext context, BillSponsor sponsor) {
    final member = Member(
      id: sponsor.memberId!,
      name: sponsor.name,
      party: sponsor.party ?? '',
      partyAbbreviation: '',
      thumbnailUrl: sponsor.photoUrl,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MemberView(member: member)),
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

/// Full-screen viewer for reading official bill documents and publications in-app.
class BillDocumentReaderView extends StatefulWidget {
  final String title;
  final Uri url;

  const BillDocumentReaderView({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<BillDocumentReaderView> createState() => _BillDocumentReaderViewState();
}

class _BillDocumentReaderViewState extends State<BillDocumentReaderView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(widget.url);
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.url.host,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in external browser',
            onPressed: () => unawaited(
              launchUrl(widget.url, mode: LaunchMode.externalApplication),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
        ],
      ),
    );
  }
}
