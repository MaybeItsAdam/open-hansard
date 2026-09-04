import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'control_split_bar.dart';

/// An animated donut pie chart for party splits, constituency election results,
/// and council seat breakdowns.
///
/// Sweeps in on load using an [AnimationController] and displays a central
/// summary count alongside an optional interactive legend.
class AnimatedPieChart extends StatefulWidget {
  final List<ControlSegment> segments;
  final String? centerTitle;
  final double chartRadius;
  final double strokeWidth;
  final bool showLegend;

  const AnimatedPieChart({
    super.key,
    required this.segments,
    this.centerTitle,
    this.chartRadius = 54.0,
    this.strokeWidth = 18.0,
    this.showLegend = true,
  });

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments != widget.segments) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _total => widget.segments.fold(0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleSegments =
        widget.segments.where((s) => s.value > 0).toList();
    if (visibleSegments.isEmpty || _total == 0) {
      return const SizedBox.shrink();
    }

    final activeSegment =
        _hoveredIndex != null && _hoveredIndex! < visibleSegments.length
            ? visibleSegments[_hoveredIndex!]
            : null;

    final centerVal =
        activeSegment != null ? '${activeSegment.value}' : '$_total';
    final centerSub = activeSegment != null
        ? activeSegment.label
        : (widget.centerTitle ?? 'Total');

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: (widget.chartRadius + widget.strokeWidth) * 2,
                  height: (widget.chartRadius + widget.strokeWidth) * 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(
                          (widget.chartRadius + widget.strokeWidth) * 2,
                          (widget.chartRadius + widget.strokeWidth) * 2,
                        ),
                        painter: _PieChartPainter(
                          segments: visibleSegments,
                          total: _total,
                          progress: _animation.value,
                          chartRadius: widget.chartRadius,
                          strokeWidth: widget.strokeWidth,
                          hoveredIndex: _hoveredIndex,
                          backgroundColor: theme.colorScheme.surface,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              centerVal,
                              key: ValueKey(centerVal),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              centerSub,
                              key: ValueKey(centerSub),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.showLegend) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < visibleSegments.length; i++) ...[
                          _buildLegendRow(
                            theme,
                            visibleSegments[i],
                            i,
                            visibleSegments.length,
                          ),
                          if (i < visibleSegments.length - 1)
                            const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendRow(
    ThemeData theme,
    ControlSegment segment,
    int index,
    int totalItems,
  ) {
    final color = controlSegmentColor(segment.label);
    final pct = (_total > 0 ? (segment.value / _total * 100) : 0)
        .toStringAsFixed(1);
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _hoveredIndex = _hoveredIndex == index ? null : index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isHovered
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${segment.value}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($pct%)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<ControlSegment> segments;
  final int total;
  final double progress;
  final double chartRadius;
  final double strokeWidth;
  final int? hoveredIndex;
  final Color backgroundColor;

  _PieChartPainter({
    required this.segments,
    required this.total,
    required this.progress,
    required this.chartRadius,
    required this.strokeWidth,
    required this.hoveredIndex,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0 || progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: chartRadius);
    final totalAngle = 2 * math.pi * progress;
    double startAngle = -math.pi / 2;

    const gapAngle = 0.03; // Slight gap between slices for a neat look

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepAngle = (segment.value / total) * totalAngle;
      final isHovered = hoveredIndex == i;
      final currentStroke = isHovered ? strokeWidth + 4 : strokeWidth;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..color = controlSegmentColor(segment.label)
        ..strokeCap = StrokeCap.butt;

      final drawSweep = math.max(0.0, sweepAngle - (segments.length > 1 ? gapAngle : 0.0));

      canvas.drawArc(
        rect,
        startAngle + (segments.length > 1 ? gapAngle / 2 : 0.0),
        drawSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.segments != segments ||
        oldDelegate.total != total;
  }
}
