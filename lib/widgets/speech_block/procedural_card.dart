import 'package:flutter/material.dart';

import '../../models/member.dart';
import '../../models/speech.dart';
import '../../utils/standing_order_helpers.dart';
import 'highlighted_text.dart';
import 'in_chair_banner.dart';

/// A structured container for procedural entries, bill amendments, new clauses,
/// and parliamentary notices.
///
/// Substantial clauses (New Clauses, Amendments, Schedules, multi-line motions)
/// render in a structured card with explicit clause labels, stage preamble,
/// and clear formatting for statutory targets.
class ProceduralCard extends StatefulWidget {
  final Speech speech;
  final String searchQuery;
  final Member? member;
  final VoidCallback? onMemberTap;

  const ProceduralCard({
    super.key,
    required this.speech,
    this.searchQuery = '',
    this.member,
    this.onMemberTap,
  });

  @override
  State<ProceduralCard> createState() => _ProceduralCardState();
}

class _ProceduralCardState extends State<ProceduralCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final chairName = widget.speech.inChairName;
    if (chairName != null) {
      return InChairBanner(
        chairName: chairName,
        member: widget.member,
        onMemberTap: widget.onMemberTap,
      );
    }

    final rawText = widget.speech.speechText.trim();
    final formattedText = _formatProceduralContent(rawText);
    final badgeInfo = _detectBadgeInfo(rawText);
    final standingOrders =
        StandingOrderHelpers.detectStandingOrders(rawText);

    final lower = rawText.toLowerCase();
    final isSubstantialClause = rawText.length > 160 ||
        lower.contains('new clause') ||
        lower.contains('amendment') ||
        lower.contains('schedule') ||
        formattedText.contains('\n\n');

    // ─── Lightweight inline layout for short notices ────────────────────────
    if (!isSubstantialClause) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 8),
              child: Icon(
                badgeInfo.icon,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightedText(
                    rawText,
                    query: widget.searchQuery,
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  if (standingOrders.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final order in standingOrders)
                          ActionChip(
                            avatar: const Icon(Icons.gavel_outlined, size: 14),
                            label: Text(
                              order.shortCode,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            tooltip: order.title,
                            onPressed: () =>
                                StandingOrderHelpers.showStandingOrderSheet(
                              context,
                              order,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ─── Structured Card layout for substantial clauses & amendments ────────
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header bar with badge & stage metadata
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    badgeInfo.icon,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    badgeInfo.label,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (badgeInfo.stagePreamble != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeInfo.stagePreamble!,
                        style: textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Body text with formatted paragraphs & sub-clauses
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedBody(formattedText, textTheme, theme),
                  if (standingOrders.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final order in standingOrders)
                          ActionChip(
                            avatar: const Icon(Icons.gavel_outlined, size: 14),
                            label: Text(
                              order.shortCode,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            tooltip: order.title,
                            onPressed: () =>
                                StandingOrderHelpers.showStandingOrderSheet(
                              context,
                              order,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedBody(
    String formattedText,
    TextTheme textTheme,
    ThemeData theme,
  ) {
    final lines = formattedText.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          _buildTextParagraph(lines[i].trim(), textTheme, theme),
          if (i < lines.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildTextParagraph(
    String paragraph,
    TextTheme textTheme,
    ThemeData theme,
  ) {
    if (paragraph.isEmpty) return const SizedBox.shrink();

    final isHeading = _isClauseOrHeading(paragraph);

    final style = isHeading
        ? textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          )
        : textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: theme.colorScheme.onSurfaceVariant,
          );

    return HighlightedText(
      paragraph,
      query: widget.searchQuery,
      style: style,
      textAlign: TextAlign.start,
    );
  }

  bool _isClauseOrHeading(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('New Clause') ||
        trimmed.startsWith('Clause ') ||
        trimmed.startsWith('Amendment ') ||
        trimmed.startsWith('Schedule ') ||
        trimmed.startsWith('Consideration of Bill')) {
      return true;
    }
    return trimmed.length < 60 && !trimmed.contains('(');
  }

  ({String label, IconData icon, String? stagePreamble}) _detectBadgeInfo(
    String text,
  ) {
    final lower = text.toLowerCase();

    final newClauseMatch =
        RegExp(r'New Clause\s+(\d+[A-Z]?)', caseSensitive: false)
            .firstMatch(text);
    final clauseNumber =
        newClauseMatch != null ? 'NEW CLAUSE ${newClauseMatch.group(1)}' : null;

    final amendmentMatch =
        RegExp(r'Amendment\s+(\d+)', caseSensitive: false).firstMatch(text);
    final amdNumber =
        amendmentMatch != null ? 'AMENDMENT ${amendmentMatch.group(1)}' : null;

    String? stagePreamble;
    if (lower.contains('consideration of bill')) {
      stagePreamble = 'Report Stage';
    } else if (lower.contains('committee')) {
      stagePreamble = 'Committee Stage';
    }

    if (clauseNumber != null) {
      return (
        label: clauseNumber,
        icon: Icons.post_add_outlined,
        stagePreamble: stagePreamble,
      );
    }
    if (amdNumber != null) {
      return (
        label: amdNumber,
        icon: Icons.edit_note_outlined,
        stagePreamble: stagePreamble,
      );
    }
    if (lower.contains('new clause')) {
      return (
        label: 'NEW CLAUSE',
        icon: Icons.post_add_outlined,
        stagePreamble: stagePreamble,
      );
    }
    if (lower.contains('amendment')) {
      return (
        label: 'BILL AMENDMENT',
        icon: Icons.edit_note_outlined,
        stagePreamble: stagePreamble,
      );
    }
    if (lower.contains('consideration of bill')) {
      return (
        label: 'BILL CONSIDERATION',
        icon: Icons.article_outlined,
        stagePreamble: stagePreamble,
      );
    }
    if (lower.contains('schedule')) {
      return (
        label: 'BILL SCHEDULE',
        icon: Icons.table_chart_outlined,
        stagePreamble: stagePreamble,
      );
    }
    if (lower.contains('ordered,') || lower.contains('resolved,')) {
      return (
        label: 'PARLIAMENTARY ORDER',
        icon: Icons.gavel_outlined,
        stagePreamble: stagePreamble,
      );
    }
    return (
      label: 'PROCEDURAL NOTICE',
      icon: Icons.info_outline,
      stagePreamble: stagePreamble,
    );
  }

  String _formatProceduralContent(String raw) {
    String text = raw.trim();

    // 1. Un-jam concatenated headers like "CommitteeNew Clause 72" -> "Committee\n\nNew Clause 72"
    text = text.replaceAllMapped(
      RegExp(r'([a-z0-9])(New Clause|Clause\s+\d+|Amendment\s+\d+|Schedule\s+\d+)\b',
          caseSensitive: false),
      (m) => '${m[1]}\n\n${m[2]}',
    );

    // 2. Un-jam title strings concatenated directly with clause numbers like "cryptoassets“(1)" -> "cryptoassets\n\n“(1)"
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9.,!?])(“?\(\d+\))'),
      (m) => '${m[1]}\n\n${m[2]}',
    );

    // 3. Insert line breaks before subsection numbers like "(1)", "(2)", "(3)"
    text = text.replaceAllMapped(
      RegExp(r'(\)\.)\s*(“?\(\d+\))'),
      (m) => '${m[1]}\n\n${m[2]}',
    );

    return text;
  }
}
