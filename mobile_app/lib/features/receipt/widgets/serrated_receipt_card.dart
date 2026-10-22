// ponytail: CustomClipper produces realistic receipt zigzag edges without SVG assets.

import 'package:flutter/material.dart';
import '../../../core/models/scroll_telemetry.dart';
import '../../../core/theme/hypercar_theme.dart';

enum ReceiptSkin {
  mattePaper,
  stealthCarbon,
}

class SerratedEdgeClipper extends CustomClipper<Path> {
  final double toothWidth;
  final double toothHeight;

  const SerratedEdgeClipper({
    this.toothWidth = 8.0,
    this.toothHeight = 5.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    // Top serrated edge
    path.moveTo(0, toothHeight);
    final topTeethCount = (width / toothWidth).floor();
    final actualToothWidth = width / topTeethCount;

    for (int i = 0; i < topTeethCount; i++) {
      final x = i * actualToothWidth;
      path.lineTo(x + actualToothWidth / 2, 0);
      path.lineTo(x + actualToothWidth, toothHeight);
    }

    // Right edge
    path.lineTo(width, height - toothHeight);

    // Bottom serrated edge
    for (int i = topTeethCount; i > 0; i--) {
      final x = (i - 1) * actualToothWidth;
      path.lineTo(x + actualToothWidth / 2, height);
      path.lineTo(x, height - toothHeight);
    }

    // Left edge
    path.lineTo(0, toothHeight);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant SerratedEdgeClipper oldClipper) {
    return oldClipper.toothWidth != toothWidth || oldClipper.toothHeight != toothHeight;
  }
}

class SerratedReceiptCard extends StatelessWidget {
  final ScrollTelemetryData telemetry;
  final ReceiptSkin skin;
  final String receiptNumber;

  const SerratedReceiptCard({
    super.key,
    required this.telemetry,
    required this.skin,
    required this.receiptNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isMatte = skin == ReceiptSkin.mattePaper;
    final bgColor = isMatte ? HypercarColors.receiptMattePaper : HypercarColors.receiptStealthPaper;
    final primaryTextColor = isMatte ? HypercarColors.receiptMatteInk : HypercarColors.receiptStealthInk;
    final mutedTextColor = isMatte ? const Color(0xFF52525B) : const Color(0xFF94A3B8);
    final borderColor = isMatte ? const Color(0xFFD4D4D8) : HypercarColors.carbonBorder;
    final accentDangerColor = isMatte ? const Color(0xFFDC2626) : HypercarColors.solarOrange;

    final result = telemetry.calculation;
    final formattedDate = '${telemetry.timestamp.year}.${telemetry.timestamp.month.toString().padLeft(2, '0')}.${telemetry.timestamp.day.toString().padLeft(2, '0')}';
    final formattedTime = '${telemetry.timestamp.hour.toString().padLeft(2, '0')}:${telemetry.timestamp.minute.toString().padLeft(2, '0')}';

    return ClipPath(
      clipper: const SerratedEdgeClipper(toothWidth: 8, toothHeight: 6),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.symmetric(
            vertical: BorderSide(color: borderColor, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Receipt Title & Cyber Logo
            Center(
              child: Column(
                children: [
                  Text(
                    'SCROLLTAX // INVOICE',
                    style: HypercarTheme.monoStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'DOOMSCROLL OPPORTUNITY COST AUDIT',
                    style: HypercarTheme.monoStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: mutedTextColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDashedLine(borderColor),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Metadata: Serial, Date, Platform
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SERIAL: $receiptNumber',
                  style: HypercarTheme.monoStyle(fontSize: 10, color: mutedTextColor),
                ),
                Text(
                  '$formattedDate $formattedTime',
                  style: HypercarTheme.monoStyle(fontSize: 10, color: mutedTextColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AUDITOR: TELEMETRY ENGINE',
                  style: HypercarTheme.monoStyle(fontSize: 10, color: mutedTextColor),
                ),
                Text(
                  telemetry.isSimulator ? 'MODE: SIMULATOR' : 'MODE: OS VERIFIED',
                  style: HypercarTheme.monoStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: telemetry.isSimulator ? HypercarColors.amberWarning : HypercarColors.matrixGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            _buildDashedLine(borderColor),
            const SizedBox(height: 10),

            // Itemized App Usage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ITEMIZED PLATFORM',
                  style: HypercarTheme.monoStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                Text(
                  'MINUTES',
                  style: HypercarTheme.monoStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...telemetry.appBreakdowns.map((app) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      app.appName.toUpperCase(),
                      style: HypercarTheme.monoStyle(fontSize: 11, color: primaryTextColor),
                    ),
                    Text(
                      '${app.durationMinutes}m (${app.percentage.toStringAsFixed(0)}%)',
                      style: HypercarTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: app.durationMinutes > 0 ? primaryTextColor : mutedTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),
            _buildDashedLine(borderColor),
            const SizedBox(height: 10),

            // Total Burned Minutes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL SCROLL DURATION',
                  style: HypercarTheme.monoStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryTextColor),
                ),
                Text(
                  '${telemetry.totalScrollMinutes} MINS',
                  style: HypercarTheme.monoStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accentDangerColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _buildDashedLine(borderColor),
            const SizedBox(height: 10),

            // Opportunity Cost Breakdown
            Text(
              'OPPORTUNITY COST EQUIVALENCY',
              style: HypercarTheme.monoStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: mutedTextColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),

            _buildCostRow('CODE LINES UNWRITTEN', '${result.linesOfCodeLost} LOC', primaryTextColor, mutedTextColor),
            _buildCostRow('BOOK PAGES UNREAD', '${result.bookPagesLost} PGS', primaryTextColor, mutedTextColor),
            _buildCostRow('${telemetry.goalSettings.goalUnitName.toUpperCase()} LOST', '${result.goalUnitsLost} UNITS', primaryTextColor, mutedTextColor),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: accentDangerColor.withValues(alpha: isMatte ? 0.08 : 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: accentDangerColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VIRTUAL TAX LEVY',
                    style: HypercarTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accentDangerColor,
                    ),
                  ),
                  Text(
                    result.formattedTaxIdr,
                    style: HypercarTheme.monoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: accentDangerColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Stamp: TAX OVERDUE
            Center(
              child: Transform.rotate(
                angle: -0.06,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: accentDangerColor, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    result.totalScrollMinutes > telemetry.goalSettings.dailyLimitMinutes
                        ? '[TAX OVERDUE // CITATION ISSUED]'
                        : '[STATUS: COMPLIANT WITH LIMIT]',
                    style: HypercarTheme.monoStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: accentDangerColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildDashedLine(borderColor),
            const SizedBox(height: 12),

            // Industrial Barcode
            _buildBarcodeWidget(primaryTextColor),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '* $receiptNumber *',
                style: HypercarTheme.monoStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: mutedTextColor,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'SCROLLTAX - DOOMSCROLLING RECKONING',
                style: HypercarTheme.monoStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                  color: mutedTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String title, String value, Color textColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: HypercarTheme.monoStyle(fontSize: 10.5, color: mutedColor),
            ),
          ),
          Text(
            value,
            style: HypercarTheme.monoStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildBarcodeWidget(Color color) {
    // Industrial barcode lines with pseudorandom realistic widths
    final barPatterns = [
      3, 1, 2, 1, 4, 1, 2, 3, 1, 2, 1, 3, 2, 1, 4, 1,
      2, 1, 3, 1, 2, 4, 1, 2, 3, 1, 1, 3, 2, 1, 4, 1,
      2, 3, 1, 2, 1, 4, 2, 1, 3, 1, 2, 1, 3, 4, 1, 2
    ];

    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: barPatterns.map((width) {
          return Container(
            width: width.toDouble() * 1.2,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 1.0),
            color: color,
          );
        }).toList(),
      ),
    );
  }
}
