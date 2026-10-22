// ponytail: CustomPainter-based curved tachometer avoiding heavy external chart libs.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/hypercar_theme.dart';
import '../../../core/utils/opportunity_calculator.dart';

class RpmTaxGauge extends StatefulWidget {
  final int scrollMinutes;
  final int dailyLimitMinutes;

  const RpmTaxGauge({
    super.key,
    required this.scrollMinutes,
    this.dailyLimitMinutes = 60,
  });

  @override
  State<RpmTaxGauge> createState() => _RpmTaxGaugeState();
}

class _RpmTaxGaugeState extends State<RpmTaxGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _displayedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _displayedMinutes = widget.scrollMinutes.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = Tween<double>(begin: 0, end: widget.scrollMinutes.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic))
      ..addListener(() {
        setState(() {
          _displayedMinutes = _animation.value;
        });
      });
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RpmTaxGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollMinutes != widget.scrollMinutes) {
      _animation = Tween<double>(
        begin: _displayedMinutes,
        end: widget.scrollMinutes.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final severity = OpportunityCalculator.getSeverityTier(widget.scrollMinutes);
    final limit = widget.dailyLimitMinutes;
    final isOverLimit = widget.scrollMinutes > limit;

    return Semantics(
      label: 'Tax Tachometer: ${widget.scrollMinutes} minutes burned today. Daily limit is $limit minutes. Severity is ${severity.shortLabel}.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 280,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(280, 180),
                  painter: _TachometerPainter(
                    currentMinutes: _displayedMinutes,
                    dailyLimitMinutes: limit.toDouble(),
                    activeColor: severity.color,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_displayedMinutes.round()}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: severity.color,
                          letterSpacing: -1,
                          height: 1.0,
                          fontFamily: 'Space Grotesk',
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MINUTES BURNED',
                            style: HypercarTheme.monoStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: HypercarColors.textMuted,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: severity.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: severity.color.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Text(
                              severity.shortLabel,
                              style: HypercarTheme.monoStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: severity.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Target limit comparison tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOverLimit
                  ? HypercarColors.laserRed.withValues(alpha: 0.12)
                  : HypercarColors.matrixGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isOverLimit
                    ? HypercarColors.laserRed.withValues(alpha: 0.4)
                    : HypercarColors.matrixGreen.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOverLimit ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  size: 14,
                  color: isOverLimit ? HypercarColors.laserRed : HypercarColors.matrixGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  isOverLimit
                      ? '+${widget.scrollMinutes - limit}m OVER DAILY BUDGET ($limit m)'
                      : '${limit - widget.scrollMinutes}m REMAINING OF $limit m BUDGET',
                  style: HypercarTheme.monoStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOverLimit ? HypercarColors.laserRed : HypercarColors.matrixGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TachometerPainter extends CustomPainter {
  final double currentMinutes;
  final double dailyLimitMinutes;
  final Color activeColor;

  _TachometerPainter({
    required this.currentMinutes,
    required this.dailyLimitMinutes,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = size.width * 0.42;

    const startAngle = math.pi * 0.82;
    const sweepTotalAngle = math.pi * 1.36; // Spans ~245 degrees
    const maxScaleMinutes = 240.0;

    // Background track arc
    final bgPaint = Paint()
      ..color = HypercarColors.carbonBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotalAngle,
      false,
      bgPaint,
    );

    // Color zone markers on arc (Green: 0-30m, Amber: 30-90m, Orange: 90-180m, Red: 180-240m+)
    final zones = [
      (0.0, 30.0, HypercarColors.matrixGreen),
      (30.0, 90.0, HypercarColors.amberWarning),
      (90.0, 180.0, HypercarColors.solarOrange),
      (180.0, 240.0, HypercarColors.laserRed),
    ];

    for (final zone in zones) {
      final zStartRatio = (zone.$1 / maxScaleMinutes).clamp(0.0, 1.0);
      final zEndRatio = (zone.$2 / maxScaleMinutes).clamp(0.0, 1.0);
      final zStartAngle = startAngle + (sweepTotalAngle * zStartRatio);
      final zSweepAngle = sweepTotalAngle * (zEndRatio - zStartRatio);

      final zonePaint = Paint()
        ..color = zone.$3.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        zStartAngle,
        zSweepAngle,
        false,
        zonePaint,
      );
    }

    // Active progress arc
    final activeRatio = (currentMinutes / maxScaleMinutes).clamp(0.0, 1.0);
    if (activeRatio > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotalAngle * activeRatio,
        false,
        activePaint,
      );
    }

    // Tick marks and scale labels
    const tickCount = 8;
    for (int i = 0; i <= tickCount; i++) {
      final ratio = i / tickCount;
      final angle = startAngle + (sweepTotalAngle * ratio);
      final tickMin = (ratio * maxScaleMinutes).round();

      final outerRadius = radius + 11;
      final innerRadius = (i % 2 == 0) ? radius + 18 : radius + 14;

      final p1 = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = (currentMinutes >= tickMin) ? activeColor : HypercarColors.textMuted
        ..strokeWidth = (i % 2 == 0) ? 2.0 : 1.0;

      canvas.drawLine(p1, p2, tickPaint);
    }

    // Daily budget marker pin
    final limitRatio = (dailyLimitMinutes / maxScaleMinutes).clamp(0.0, 1.0);
    final limitAngle = startAngle + (sweepTotalAngle * limitRatio);
    final limitPinStart = Offset(
      center.dx + (radius - 12) * math.cos(limitAngle),
      center.dy + (radius - 12) * math.sin(limitAngle),
    );
    final limitPinEnd = Offset(
      center.dx + (radius + 12) * math.cos(limitAngle),
      center.dy + (radius + 12) * math.sin(limitAngle),
    );

    final limitPaint = Paint()
      ..color = HypercarColors.cyberCyan
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(limitPinStart, limitPinEnd, limitPaint);
  }

  @override
  bool shouldRepaint(covariant _TachometerPainter oldDelegate) {
    return oldDelegate.currentMinutes != currentMinutes ||
        oldDelegate.dailyLimitMinutes != dailyLimitMinutes ||
        oldDelegate.activeColor != activeColor;
  }
}
