import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/utils/opportunity_calculator.dart';

void main() {
  group('OpportunityCalculator Mathematical Formulas', () {
    test('Lines of Code Unwritten: floor((T / 60) * 80)', () {
      expect(OpportunityCalculator.calculateLinesOfCode(0), 0);
      expect(OpportunityCalculator.calculateLinesOfCode(30), 40);
      expect(OpportunityCalculator.calculateLinesOfCode(45), 60);
      expect(OpportunityCalculator.calculateLinesOfCode(60), 80);
      expect(OpportunityCalculator.calculateLinesOfCode(90), 120);
      expect(OpportunityCalculator.calculateLinesOfCode(150), 200);
    });

    test('Book Pages Unread: floor(T / 2.5)', () {
      expect(OpportunityCalculator.calculateBookPages(0), 0);
      expect(OpportunityCalculator.calculateBookPages(2), 0);
      expect(OpportunityCalculator.calculateBookPages(5), 2);
      expect(OpportunityCalculator.calculateBookPages(25), 10);
      expect(OpportunityCalculator.calculateBookPages(60), 24);
      expect(OpportunityCalculator.calculateBookPages(150), 60);
    });

    test('Custom Goal Units Lost: round(T / M_unit, 2)', () {
      expect(OpportunityCalculator.calculateGoalUnits(0), 0.0);
      expect(OpportunityCalculator.calculateGoalUnits(60, minutesPerUnit: 120), 0.5);
      expect(OpportunityCalculator.calculateGoalUnits(120, minutesPerUnit: 120), 1.0);
      expect(OpportunityCalculator.calculateGoalUnits(180, minutesPerUnit: 120), 1.5);
      expect(OpportunityCalculator.calculateGoalUnits(100, minutesPerUnit: 120), 0.83);
    });

    test('Virtual Tax Penalty: T * 1500 IDR', () {
      expect(OpportunityCalculator.calculateVirtualTaxIdr(0), 0);
      expect(OpportunityCalculator.calculateVirtualTaxIdr(60), 90000);
      expect(OpportunityCalculator.calculateVirtualTaxIdr(100), 150000);
    });

    test('Tax Severity Tiers', () {
      expect(OpportunityCalculator.getSeverityTier(15), TaxSeverityTier.nominal);
      expect(OpportunityCalculator.getSeverityTier(30), TaxSeverityTier.nominal);
      expect(OpportunityCalculator.getSeverityTier(31), TaxSeverityTier.warning);
      expect(OpportunityCalculator.getSeverityTier(90), TaxSeverityTier.warning);
      expect(OpportunityCalculator.getSeverityTier(91), TaxSeverityTier.heavyTax);
      expect(OpportunityCalculator.getSeverityTier(180), TaxSeverityTier.heavyTax);
      expect(OpportunityCalculator.getSeverityTier(181), TaxSeverityTier.criticalBankruptcy);
      expect(OpportunityCalculator.getSeverityTier(300), TaxSeverityTier.criticalBankruptcy);
    });

    test('Full Evaluation and IDR formatting', () {
      final res = OpportunityCalculator.evaluate(
        scrollMinutes: 100,
        minutesPerUnit: 120,
        goalUnitName: 'Modules Built',
      );
      expect(res.totalScrollMinutes, 100);
      expect(res.linesOfCodeLost, 133);
      expect(res.bookPagesLost, 40);
      expect(res.goalUnitsLost, 0.83);
      expect(res.taxPenaltyIdr, 150000);
      expect(res.formattedTaxIdr, 'Rp 150.000');
      expect(res.severityTier, TaxSeverityTier.heavyTax);
    });
  });
}
