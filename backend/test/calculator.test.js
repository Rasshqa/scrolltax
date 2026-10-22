// ponytail: Automated check for TRD mathematical formulas in backend engine.

const assert = require('assert');

function calculateOpportunityCost(scrollMinutes, minutesPerUnit = 120) {
  const safeMinutes = Math.max(0, scrollMinutes);
  const linesOfCodeLost = Math.floor((safeMinutes / 60) * 80);
  const bookPagesLost = Math.floor(safeMinutes / 2.5);
  const goalUnitsLost = Math.round((safeMinutes / (minutesPerUnit || 120)) * 100) / 100;
  const taxPenaltyIdr = safeMinutes * 1500;

  let severityTier;
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

// Test Suite
console.log('Running ScrollTax backend formula verification tests...');

// 1. Lines of Code Unwritten: floor((T / 60) * 80)
assert.strictEqual(calculateOpportunityCost(0).linesOfCodeLost, 0);
assert.strictEqual(calculateOpportunityCost(60).linesOfCodeLost, 80);
assert.strictEqual(calculateOpportunityCost(90).linesOfCodeLost, 120);
assert.strictEqual(calculateOpportunityCost(140).linesOfCodeLost, 186);

// 2. Book Pages Unread: floor(T / 2.5)
assert.strictEqual(calculateOpportunityCost(0).bookPagesLost, 0);
assert.strictEqual(calculateOpportunityCost(5).bookPagesLost, 2);
assert.strictEqual(calculateOpportunityCost(140).bookPagesLost, 56);

// 3. Custom Goal Units Lost: round(T / M_unit, 2)
assert.strictEqual(calculateOpportunityCost(0).goalUnitsLost, 0);
assert.strictEqual(calculateOpportunityCost(120, 120).goalUnitsLost, 1.0);
assert.strictEqual(calculateOpportunityCost(140, 120).goalUnitsLost, 1.17);
assert.strictEqual(calculateOpportunityCost(60, 90).goalUnitsLost, 0.67);

// 4. Virtual Tax Penalty: T * 1500 IDR
assert.strictEqual(calculateOpportunityCost(0).taxPenaltyIdr, 0);
assert.strictEqual(calculateOpportunityCost(60).taxPenaltyIdr, 90000);
assert.strictEqual(calculateOpportunityCost(140).taxPenaltyIdr, 210000);

// 5. Severity Tiers
assert.strictEqual(calculateOpportunityCost(25).severityTier, 'NOMINAL');
assert.strictEqual(calculateOpportunityCost(30).severityTier, 'NOMINAL');
assert.strictEqual(calculateOpportunityCost(31).severityTier, 'WARNING');
assert.strictEqual(calculateOpportunityCost(90).severityTier, 'WARNING');
assert.strictEqual(calculateOpportunityCost(91).severityTier, 'HEAVY_TAX');
assert.strictEqual(calculateOpportunityCost(180).severityTier, 'HEAVY_TAX');
assert.strictEqual(calculateOpportunityCost(181).severityTier, 'CRITICAL_BANKRUPTCY');

console.log('All backend formula tests PASSED successfully!');
