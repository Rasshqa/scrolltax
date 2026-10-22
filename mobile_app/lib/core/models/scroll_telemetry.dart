// ponytail: Unified telemetry model holding real or simulated screen time data.

import '../utils/opportunity_calculator.dart';

class AppUsageInfo {
  final String appName;
  final String packageName;
  final int durationMinutes;
  final double percentage; // 0.0 to 100.0

  const AppUsageInfo({
    required this.appName,
    required this.packageName,
    required this.durationMinutes,
    required this.percentage,
  });

  Map<String, dynamic> toJson() => {
    'appName': appName,
    'packageName': packageName,
    'durationMinutes': durationMinutes,
    'percentage': percentage,
  };

  factory AppUsageInfo.fromJson(Map<String, dynamic> json) => AppUsageInfo(
    appName: json['appName'] as String,
    packageName: json['packageName'] as String,
    durationMinutes: json['durationMinutes'] as int,
    percentage: (json['percentage'] as num).toDouble(),
  );
}

class UserGoalSettings {
  final String primaryGoal;
  final String goalUnitName;
  final int minutesPerUnit;
  final int dailyLimitMinutes;

  const UserGoalSettings({
    this.primaryGoal = 'Ship Portfolio Project',
    this.goalUnitName = 'Modules Built',
    this.minutesPerUnit = 120,
    this.dailyLimitMinutes = 60,
  });

  UserGoalSettings copyWith({
    String? primaryGoal,
    String? goalUnitName,
    int? minutesPerUnit,
    int? dailyLimitMinutes,
  }) {
    return UserGoalSettings(
      primaryGoal: primaryGoal ?? this.primaryGoal,
      goalUnitName: goalUnitName ?? this.goalUnitName,
      minutesPerUnit: minutesPerUnit ?? this.minutesPerUnit,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    );
  }
}

class ScrollTelemetryData {
  final int totalScrollMinutes;
  final List<AppUsageInfo> appBreakdowns;
  final bool isSimulator;
  final bool hasPermission;
  final DateTime timestamp;
  final UserGoalSettings goalSettings;

  const ScrollTelemetryData({
    required this.totalScrollMinutes,
    required this.appBreakdowns,
    required this.isSimulator,
    required this.hasPermission,
    required this.timestamp,
    required this.goalSettings,
  });

  OpportunityCostResult get calculation => OpportunityCalculator.evaluate(
    scrollMinutes: totalScrollMinutes,
    minutesPerUnit: goalSettings.minutesPerUnit,
    goalUnitName: goalSettings.goalUnitName,
  );

  Map<String, int> get appBreakdownMap {
    final map = <String, int>{};
    for (final item in appBreakdowns) {
      map[item.appName] = item.durationMinutes;
    }
    return map;
  }
}
