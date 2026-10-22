// ponytail: Pure calculation utility without external math dependencies.

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tax severity tiers based on daily doomscrolling duration (minutes).
enum TaxSeverityTier {
  nominal,
  warning,
  heavyTax,
  criticalBankruptcy,
}

extension TaxSeverityTierX on TaxSeverityTier {
  String get label {
    switch (this) {
      case TaxSeverityTier.nominal:
        return 'NOMINAL (GREEN)';
      case TaxSeverityTier.warning:
        return 'WARNING (AMBER)';
      case TaxSeverityTier.heavyTax:
        return 'HEAVY TAX (HYPER-ORANGE)';
      case TaxSeverityTier.criticalBankruptcy:
        return 'CRITICAL BANKRUPTCY (CRIMSON)';
    }
  }

  String get shortLabel {
    switch (this) {
      case TaxSeverityTier.nominal:
        return 'NOMINAL';
      case TaxSeverityTier.warning:
        return 'WARNING';
      case TaxSeverityTier.heavyTax:
        return 'HEAVY TAX';
      case TaxSeverityTier.criticalBankruptcy:
        return 'BANKRUPTCY';
    }
  }

  Color get color {
    switch (this) {
      case TaxSeverityTier.nominal:
        return const Color(0xFF10B981); // Matrix Green
      case TaxSeverityTier.warning:
        return const Color(0xFFFFB800); // Amber warning
      case TaxSeverityTier.heavyTax:
        return const Color(0xFFFF5500); // Solar Hyper-Orange
      case TaxSeverityTier.criticalBankruptcy:
        return const Color(0xFFFF2A54); // Laser Red / Crimson
    }
  }
}

/// Opportunity cost calculation result container.
class OpportunityCostResult {
  final int totalScrollMinutes;
  final int linesOfCodeLost;
  final int bookPagesLost;
  final double goalUnitsLost;
  final int taxPenaltyIdr;
  final TaxSeverityTier severityTier;
  final String goalUnitName;

  const OpportunityCostResult({
    required this.totalScrollMinutes,
    required this.linesOfCodeLost,
    required this.bookPagesLost,
    required this.goalUnitsLost,
    required this.taxPenaltyIdr,
    required this.severityTier,
    required this.goalUnitName,
  });

  /// Formatted Indonesian Rupiah string (e.g., Rp 150.000).
  String get formattedTaxIdr {
    final buffer = StringBuffer();
    final str = taxPenaltyIdr.toString();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }
}

/// Mathematical formulas implementation from ScrollTax TRD.
class OpportunityCalculator {
  const OpportunityCalculator();

  /// 1. Lines of Code Unwritten (L):
  /// L = floor((T / 60) * 80)
  static int calculateLinesOfCode(int scrollMinutes) {
    if (scrollMinutes <= 0) return 0;
    // ponytail: integer floor division directly mirrors formula floor(T / 60 * 80)
    return ((scrollMinutes / 60.0) * 80.0).floor();
  }

  /// 2. Book Pages Unread (P):
  /// P = floor(T / 2.5)
  static int calculateBookPages(int scrollMinutes) {
    if (scrollMinutes <= 0) return 0;
    return (scrollMinutes / 2.5).floor();
  }

  /// 3. Custom Goal Units Lost (U):
  /// U = round(T / M_unit, 2)
  /// where M_unit is minutes needed for 1 unit of user target (default 120 mins).
  static double calculateGoalUnits(int scrollMinutes, {int minutesPerUnit = 120}) {
    if (scrollMinutes <= 0 || minutesPerUnit <= 0) return 0.0;
    final value = scrollMinutes / minutesPerUnit.toDouble();
    // Round to 2 decimal places
    final factor = math.pow(10, 2).toDouble();
    return (value * factor).round() / factor;
  }

  /// 4. Virtual Tax Penalty (V_IDR):
  /// V_IDR = T * 1500 IDR (assumes Rp90.000/hour productive time value).
  static int calculateVirtualTaxIdr(int scrollMinutes) {
    if (scrollMinutes <= 0) return 0;
    return scrollMinutes * 1500;
  }

  /// 5. Tax Severity Tier:
  /// T <= 30: NOMINAL (GREEN)
  /// 30 < T <= 90: WARNING (AMBER)
  /// 90 < T <= 180: HEAVY TAX (HYPER-ORANGE)
  /// T > 180: CRITICAL BANKRUPTCY (CRIMSON)
  static TaxSeverityTier getSeverityTier(int scrollMinutes) {
    if (scrollMinutes <= 30) {
      return TaxSeverityTier.nominal;
    } else if (scrollMinutes <= 90) {
      return TaxSeverityTier.warning;
    } else if (scrollMinutes <= 180) {
      return TaxSeverityTier.heavyTax;
    } else {
      return TaxSeverityTier.criticalBankruptcy;
    }
  }

  /// Evaluates full opportunity cost breakdown for given parameters.
  static OpportunityCostResult evaluate({
    required int scrollMinutes,
    int minutesPerUnit = 120,
    String goalUnitName = 'Feature Modules',
  }) {
    return OpportunityCostResult(
      totalScrollMinutes: scrollMinutes,
      linesOfCodeLost: calculateLinesOfCode(scrollMinutes),
      bookPagesLost: calculateBookPages(scrollMinutes),
      goalUnitsLost: calculateGoalUnits(scrollMinutes, minutesPerUnit: minutesPerUnit),
      taxPenaltyIdr: calculateVirtualTaxIdr(scrollMinutes),
      severityTier: getSeverityTier(scrollMinutes),
      goalUnitName: goalUnitName,
    );
  }
}
