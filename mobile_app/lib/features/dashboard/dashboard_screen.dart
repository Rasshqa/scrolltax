// ponytail: Reactive hypercar dashboard linking telemetry, tachometer, and opportunity cost cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/scroll_telemetry.dart';
import '../../core/services/usage_tracker_service.dart';
import '../../core/theme/hypercar_theme.dart';
import '../../core/utils/opportunity_calculator.dart';
import 'widgets/rpm_tax_gauge.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  void _openGoalCalibration(BuildContext context, UserGoalSettings currentSettings) {
    final goalCtrl = TextEditingController(text: currentSettings.primaryGoal);
    final unitCtrl = TextEditingController(text: currentSettings.goalUnitName);
    final minsCtrl = TextEditingController(text: currentSettings.minutesPerUnit.toString());
    final limitCtrl = TextEditingController(text: currentSettings.dailyLimitMinutes.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HypercarColors.carbonSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: HypercarColors.carbonBorder),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CALIBRATE TARGET GOAL',
                    style: HypercarTheme.monoStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: HypercarColors.solarOrange,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: HypercarColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: goalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Primary Mission / Goal',
                  helperText: 'e.g. Ship Portfolio Project, Learn Rust',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit Metric Name',
                  helperText: 'e.g. Feature Modules, Reading Chapters',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mins / Unit',
                        helperText: 'Default: 120m',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: limitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daily Limit',
                        helperText: 'Budget: 60m',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final newSettings = UserGoalSettings(
                    primaryGoal: goalCtrl.text.trim().isEmpty ? 'Ship Portfolio Project' : goalCtrl.text.trim(),
                    goalUnitName: unitCtrl.text.trim().isEmpty ? 'Modules Built' : unitCtrl.text.trim(),
                    minutesPerUnit: int.tryParse(minsCtrl.text) ?? 120,
                    dailyLimitMinutes: int.tryParse(limitCtrl.text) ?? 60,
                  );
                  ref.read(usageTrackerProvider.notifier).updateGoalSettings(newSettings);
                  Navigator.pop(ctx);
                },
                child: const Text('SAVE CALIBRATION'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usageTrackerProvider);
    final notifier = ref.read(usageTrackerProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: HypercarColors.obsidianBg,
        body: Center(
          child: CircularProgressIndicator(color: HypercarColors.solarOrange),
        ),
      );
    }

    final telemetry = state.telemetry;
    final calc = telemetry.calculation;

    return Scaffold(
      backgroundColor: HypercarColors.obsidianBg,
      appBar: AppBar(
        backgroundColor: HypercarColors.obsidianBg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: HypercarColors.solarOrange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SCROLLTAX // TELEMETRY',
              style: HypercarTheme.monoStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Calibrate Goals',
            icon: const Icon(Icons.tune_rounded, color: HypercarColors.cyberCyan),
            onPressed: () => _openGoalCalibration(context, telemetry.goalSettings),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: HypercarColors.solarOrange,
          backgroundColor: HypercarColors.carbonSurface,
          onRefresh: () async {
            await notifier.checkPermissionAndSync();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Permission / Simulator Banner
                if (!state.hasPermission)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HypercarColors.carbonSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: HypercarColors.amberWarning.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_clock_outlined, size: 18, color: HypercarColors.amberWarning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'OS TELEMETRY LOCKED: SIMULATOR ACTIVE',
                                style: HypercarTheme.monoStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: HypercarColors.amberWarning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Simulating live metrics. On Android devices, grant usage permission to inspect real social app screen time.',
                          style: TextStyle(
                            fontSize: 12,
                            color: HypercarColors.textSecondary,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: const Size(44, 36),
                              ),
                              onPressed: () => notifier.requestPermission(),
                              child: const Text('GRANT ACCESS', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => notifier.checkPermissionAndSync(),
                              child: Text(
                                'RE-CHECK PERMISSION',
                                style: HypercarTheme.monoStyle(
                                  fontSize: 11,
                                  color: HypercarColors.cyberCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Tachometer RPM Gauge Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: HypercarColors.carbonSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HypercarColors.carbonBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TAX METER GAUGE',
                            style: HypercarTheme.monoStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: HypercarColors.textMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: calc.severityTier.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: calc.severityTier.color, width: 0.8),
                            ),
                            child: Text(
                              calc.severityTier.label,
                              style: HypercarTheme.monoStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: calc.severityTier.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RpmTaxGauge(
                        scrollMinutes: telemetry.totalScrollMinutes,
                        dailyLimitMinutes: telemetry.goalSettings.dailyLimitMinutes,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Interactive Simulator Slider
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HypercarColors.carbonSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HypercarColors.carbonBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'INTERACTIVE TELEMETRY SLIDER',
                            style: HypercarTheme.monoStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: HypercarColors.cyberCyan,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${telemetry.totalScrollMinutes} MINS',
                            style: HypercarTheme.monoStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: HypercarColors.solarOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: HypercarColors.solarOrange,
                          inactiveTrackColor: HypercarColors.carbonBorder,
                          thumbColor: HypercarColors.solarOrange,
                          overlayColor: HypercarColors.solarOrange.withValues(alpha: 0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: telemetry.totalScrollMinutes.toDouble().clamp(0.0, 360.0),
                          min: 0,
                          max: 360,
                          divisions: 72,
                          label: '${telemetry.totalScrollMinutes} mins',
                          onChanged: (val) {
                            notifier.setSimulatorMinutes(val.round());
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0m (Discipline)', style: HypercarTheme.monoStyle(fontSize: 10, color: HypercarColors.textMuted)),
                          Text('60m (Limit)', style: HypercarTheme.monoStyle(fontSize: 10, color: HypercarColors.cyberCyan)),
                          Text('180m (Redline)', style: HypercarTheme.monoStyle(fontSize: 10, color: HypercarColors.laserRed)),
                          Text('360m', style: HypercarTheme.monoStyle(fontSize: 10, color: HypercarColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Quick Telemetry Jump Shortcuts
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPresetChip('0m (Zero)', () => notifier.setSimulatorMinutes(0)),
                            const SizedBox(width: 6),
                            _buildPresetChip('+15m', () => notifier.setSimulatorMinutes((telemetry.totalScrollMinutes + 15).clamp(0, 360))),
                            const SizedBox(width: 6),
                            _buildPresetChip('+30m', () => notifier.setSimulatorMinutes((telemetry.totalScrollMinutes + 30).clamp(0, 360))),
                            const SizedBox(width: 6),
                            _buildPresetChip('+60m', () => notifier.setSimulatorMinutes((telemetry.totalScrollMinutes + 60).clamp(0, 360))),
                            const SizedBox(width: 6),
                            _buildPresetChip('180m Redline', () => notifier.setSimulatorMinutes(180), isAccent: true),
                            const SizedBox(width: 6),
                            _buildPresetChip('360m Max', () => notifier.setSimulatorMinutes(360)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Real-time Telemetry HUD (Burn Rate & Overdraft)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: HypercarColors.carbonElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HypercarColors.carbonBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTelemetryHudItem(
                        label: 'HOURLY BURN',
                        value: 'Rp 90k/h',
                        color: HypercarColors.solarOrange,
                        subtext: 'Rp 1,500/min',
                      ),
                      Container(width: 1, height: 32, color: HypercarColors.carbonBorder),
                      _buildTelemetryHudItem(
                        label: 'DEFICIT TIER',
                        value: calc.severityTier.shortLabel,
                        color: calc.severityTier.color,
                        subtext: '${calc.linesOfCodeLost} LOC unwritten',
                      ),
                      Container(width: 1, height: 32, color: HypercarColors.carbonBorder),
                      _buildTelemetryHudItem(
                        label: 'BUDGET DELTA',
                        value: telemetry.totalScrollMinutes > telemetry.goalSettings.dailyLimitMinutes
                            ? '+${telemetry.totalScrollMinutes - telemetry.goalSettings.dailyLimitMinutes}m'
                            : '${telemetry.goalSettings.dailyLimitMinutes - telemetry.totalScrollMinutes}m ok',
                        color: telemetry.totalScrollMinutes > telemetry.goalSettings.dailyLimitMinutes
                            ? HypercarColors.laserRed
                            : HypercarColors.matrixGreen,
                        subtext: telemetry.totalScrollMinutes > telemetry.goalSettings.dailyLimitMinutes
                            ? 'Overdraft'
                            : 'Within Budget',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Opportunity Cost Breakdown Cards Grid
                Text(
                  'OPPORTUNITY COST EQUIVALENCY',
                  style: HypercarTheme.monoStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: HypercarColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;
                    return GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isWide ? 1.4 : 1.25,
                      children: [
                        _buildMetricCard(
                          icon: Icons.code_rounded,
                          title: 'CODE UNWRITTEN',
                          value: '${calc.linesOfCodeLost}',
                          unit: 'lines of code',
                          accentColor: HypercarColors.cyberCyan,
                          formula: 'floor((T/60)*80)',
                        ),
                        _buildMetricCard(
                          icon: Icons.menu_book_rounded,
                          title: 'PAGES UNREAD',
                          value: '${calc.bookPagesLost}',
                          unit: 'book pages',
                          accentColor: HypercarColors.matrixGreen,
                          formula: 'floor(T/2.5)',
                        ),
                        _buildMetricCard(
                          icon: Icons.flag_rounded,
                          title: telemetry.goalSettings.goalUnitName.toUpperCase(),
                          value: '${calc.goalUnitsLost}',
                          unit: 'units deferred',
                          accentColor: HypercarColors.amberWarning,
                          formula: '${telemetry.goalSettings.minutesPerUnit}m per unit',
                        ),
                        _buildMetricCard(
                          icon: Icons.attach_money_rounded,
                          title: 'VIRTUAL TAX LEVY',
                          value: calc.formattedTaxIdr,
                          unit: 'opportunity debt',
                          accentColor: HypercarColors.solarOrange,
                          formula: 'T * 1500 IDR',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                // App-by-App Offender List
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HypercarColors.carbonSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HypercarColors.carbonBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'OFFENDER AUDIT BY PLATFORM',
                            style: HypercarTheme.monoStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: HypercarColors.textMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${telemetry.appBreakdowns.length} TARGET APPS',
                            style: HypercarTheme.monoStyle(
                              fontSize: 10,
                              color: HypercarColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...telemetry.appBreakdowns.map((app) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _getAppColor(app.appName),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        app.appName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          fontFamily: 'Space Grotesk',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${app.durationMinutes} min (${app.percentage.toStringAsFixed(0)}%)',
                                    style: HypercarTheme.monoStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: app.durationMinutes > 0 ? HypercarColors.textPrimary : HypercarColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: app.percentage / 100,
                                  backgroundColor: HypercarColors.carbonBorder,
                                  valueColor: AlwaysStoppedAnimation<Color>(_getAppColor(app.appName)),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAppColor(String name) {
    switch (name.toLowerCase()) {
      case 'tiktok':
        return const Color(0xFF00F2FE);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'x (twitter)':
        return const Color(0xFF1DA1F2);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return HypercarColors.solarOrange;
    }
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color accentColor,
    required String formula,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HypercarColors.carbonElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HypercarColors.carbonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: accentColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  formula,
                  style: HypercarTheme.monoStyle(fontSize: 8, color: accentColor),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: HypercarColors.textPrimary,
                  fontFamily: 'Space Grotesk',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HypercarTheme.monoStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: HypercarColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, {bool isAccent = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isAccent
              ? HypercarColors.laserRed.withValues(alpha: 0.15)
              : HypercarColors.carbonElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isAccent
                ? HypercarColors.laserRed
                : HypercarColors.carbonBorder,
            width: isAccent ? 1.2 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: HypercarTheme.monoStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isAccent ? HypercarColors.laserRed : HypercarColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryHudItem({
    required String label,
    required String value,
    required Color color,
    required String subtext,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: HypercarTheme.monoStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: HypercarColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'Space Grotesk',
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtext,
          style: HypercarTheme.monoStyle(
            fontSize: 8.5,
            color: HypercarColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
