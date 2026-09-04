import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/standing_order.dart';
import 'standing_orders_data.dart';

/// Helper utilities for detecting and presenting Standing Orders in Hansard text.
abstract class StandingOrderHelpers {
  static final RegExp _regex = RegExp(
    r'(?:Standing\s+Orders?\s+(?:Nos?\.\s*)?|S\.O\.\s*(?:Nos?\.\s*)?)\s*(\d+[A-Z]?)',
    caseSensitive: false,
  );

  /// Scans [text] for Standing Order mentions and returns matching [StandingOrder] items.
  static List<StandingOrder> detectStandingOrders(String text) {
    if (text.isEmpty) return const [];
    final matches = _regex.allMatches(text);
    final results = <StandingOrder>[];
    final seenIds = <String>{};

    for (final match in matches) {
      final numberStr = match.group(1);
      if (numberStr == null) continue;
      final order = StandingOrdersData.find(numberStr);
      if (order != null && !seenIds.contains(order.id)) {
        seenIds.add(order.id);
        results.add(order);
      }
    }
    return results;
  }

  /// Shows a modal bottom sheet displaying full detail for [order].
  static void showStandingOrderSheet(
    BuildContext context,
    StandingOrder order,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.gavel_outlined,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.displayLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Chip(
                      label: Text('House of ${order.house}'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      label: Text(order.category),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Full Text of Standing Order',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                if (order.officialUrl != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => unawaited(
                        launchUrl(
                          Uri.parse(order.officialUrl!),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View in Erskine May'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
