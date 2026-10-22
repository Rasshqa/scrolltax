// ponytail: Pure calculation utility mirroring TRD formulas in TypeScript.

export interface CalculationResult {
  linesOfCodeLost: number;
  bookPagesLost: number;
  goalUnitsLost: number;
  taxPenaltyIdr: number;
  severityTier: 'NOMINAL' | 'WARNING' | 'HEAVY_TAX' | 'CRITICAL_BANKRUPTCY';
}

export function calculateOpportunityCost(
  scrollMinutes: number,
  minutesPerUnit: number = 120
): CalculationResult {
  const safeMinutes = Math.max(0, scrollMinutes);

  // 1. Lines of Code Unwritten: floor((T / 60) * 80)
  const linesOfCodeLost = Math.floor((safeMinutes / 60) * 80);

  // 2. Book Pages Unread: floor(T / 2.5)
  const bookPagesLost = Math.floor(safeMinutes / 2.5);

  // 3. Custom Goal Units Lost: round(T / M_unit, 2)
  const goalUnitsLost = Math.round((safeMinutes / (minutesPerUnit || 120)) * 100) / 100;

  // 4. Virtual Tax Penalty: T * 1500 IDR
  const taxPenaltyIdr = safeMinutes * 1500;

  // 5. Tax Severity Tier
  let severityTier: CalculationResult['severityTier'];
  if (safeMinutes <= 30) {
    severityTier = 'NOMINAL';
  } else if (safeMinutes <= 90) {
    severityTier = 'WARNING';
  } else if (safeMinutes <= 180) {
    severityTier = 'HEAVY_TAX';
  } else {
    severityTier = 'CRITICAL_BANKRUPTCY';
  }

  return {
    linesOfCodeLost,
    bookPagesLost,
    goalUnitsLost,
    taxPenaltyIdr,
    severityTier,
  };
}
