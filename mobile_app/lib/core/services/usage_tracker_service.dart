// ponytail: Platform adaptive service wrapping native UsageStats with Web/iOS simulator.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';

import '../models/scroll_telemetry.dart';

/// Target social media packages for doomscroll detection on Android.
const Map<String, String> kTargetPackages = {
  'TikTok': 'com.zhiliaoapp.musically',
  'Instagram': 'com.instagram.android',
  'X (Twitter)': 'com.twitter.android',
  'YouTube': 'com.google.android.youtube',
};

class UsageTrackerState {
  final bool isLoading;
  final bool hasPermission;
  final bool isSimulatorMode;
  final ScrollTelemetryData telemetry;
  final String? errorMessage;

  const UsageTrackerState({
    required this.isLoading,
    required this.hasPermission,
    required this.isSimulatorMode,
    required this.telemetry,
    this.errorMessage,
  });

  UsageTrackerState copyWith({
    bool? isLoading,
    bool? hasPermission,
    bool? isSimulatorMode,
    ScrollTelemetryData? telemetry,
    String? errorMessage,
  }) {
    return UsageTrackerState(
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      isSimulatorMode: isSimulatorMode ?? this.isSimulatorMode,
      telemetry: telemetry ?? this.telemetry,
      errorMessage: errorMessage,
    );
  }
}

class UsageTrackerNotifier extends Notifier<UsageTrackerState> {
  static UserGoalSettings _cachedGoals = const UserGoalSettings();

  static ScrollTelemetryData _createDefaultTelemetry(
    int minutes, {
    required bool isSim,
    required bool hasPerm,
    UserGoalSettings? goals,
  }) {
    final effectiveGoals = goals ?? _cachedGoals;
    final List<AppUsageInfo> apps;
    if (minutes <= 0) {
      apps = [
        const AppUsageInfo(appName: 'TikTok', packageName: 'com.zhiliaoapp.musically', durationMinutes: 0, percentage: 0),
        const AppUsageInfo(appName: 'Instagram', packageName: 'com.instagram.android', durationMinutes: 0, percentage: 0),
        const AppUsageInfo(appName: 'X (Twitter)', packageName: 'com.twitter.android', durationMinutes: 0, percentage: 0),
        const AppUsageInfo(appName: 'YouTube', packageName: 'com.google.android.youtube', durationMinutes: 0, percentage: 0),
      ];
    } else {
      final tikTok = (minutes * 0.46).round();
      final insta = (minutes * 0.29).round();
      final x = (minutes * 0.14).round();
      final yt = minutes - (tikTok + insta + x);

      apps = [
        AppUsageInfo(
          appName: 'TikTok',
          packageName: 'com.zhiliaoapp.musically',
          durationMinutes: tikTok,
          percentage: (tikTok / minutes * 100).clamp(0, 100),
        ),
        AppUsageInfo(
          appName: 'Instagram',
          packageName: 'com.instagram.android',
          durationMinutes: insta,
          percentage: (insta / minutes * 100).clamp(0, 100),
        ),
        AppUsageInfo(
          appName: 'X (Twitter)',
          packageName: 'com.twitter.android',
          durationMinutes: x,
          percentage: (x / minutes * 100).clamp(0, 100),
        ),
        AppUsageInfo(
          appName: 'YouTube',
          packageName: 'com.google.android.youtube',
          durationMinutes: yt > 0 ? yt : 0,
          percentage: (yt / minutes * 100).clamp(0, 100),
        ),
      ];
    }

    return ScrollTelemetryData(
      totalScrollMinutes: minutes,
      appBreakdowns: apps,
      isSimulator: isSim,
      hasPermission: hasPerm,
      timestamp: DateTime.now(),
      goalSettings: effectiveGoals,
    );
  }

  @override
  UsageTrackerState build() {
    _initAsync();
    return UsageTrackerState(
      isLoading: true,
      hasPermission: false,
      isSimulatorMode: !kIsWeb && !Platform.isAndroid ? true : kIsWeb,
      telemetry: _createDefaultTelemetry(140, isSim: true, hasPerm: false),
    );
  }

  Future<void> _initAsync() async {
    await _loadPersistedSettings();

    if (kIsWeb || !Platform.isAndroid) {
      state = state.copyWith(
        isLoading: false,
        hasPermission: false,
        isSimulatorMode: true,
        telemetry: _createDefaultTelemetry(
          state.telemetry.totalScrollMinutes,
          isSim: true,
          hasPerm: false,
          goals: _cachedGoals,
        ),
      );
      return;
    }

    await checkPermissionAndSync();
  }

  Future<void> _loadPersistedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goal = prefs.getString('stx_primary_goal') ?? 'Ship Portfolio Project';
      final unitName = prefs.getString('stx_goal_unit_name') ?? 'Modules Built';
      final minsPerUnit = prefs.getInt('stx_mins_per_unit') ?? 120;
      final dailyLimit = prefs.getInt('stx_daily_limit') ?? 60;
      final simMinutes = prefs.getInt('stx_sim_minutes') ?? 140;

      _cachedGoals = UserGoalSettings(
        primaryGoal: goal,
        goalUnitName: unitName,
        minutesPerUnit: minsPerUnit,
        dailyLimitMinutes: dailyLimit,
      );

      state = state.copyWith(
        telemetry: _createDefaultTelemetry(
          simMinutes,
          isSim: state.isSimulatorMode,
          hasPerm: state.hasPermission,
          goals: _cachedGoals,
        ),
      );
    } catch (_) {
      // ponytail: graceful fallback if storage is unavailable
    }
  }

  Future<void> checkPermissionAndSync() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final bool? isGranted = await UsageStats.checkUsagePermission();
      final hasPerm = isGranted ?? false;

      if (!hasPerm) {
        state = state.copyWith(
          isLoading: false,
          hasPermission: false,
          isSimulatorMode: true,
        );
        return;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final List<UsageInfo> usageInfos = await UsageStats.queryUsageStats(startOfDay, now);

      final Map<String, int> foundApps = {};
      int totalMinutes = 0;

      for (final usage in usageInfos) {
        final pkg = usage.packageName ?? '';
        final timeInForegroundMs = int.tryParse(usage.totalTimeInForeground ?? '0') ?? 0;
        final minutes = (timeInForegroundMs / 60000).round();

        for (final entry in kTargetPackages.entries) {
          if (pkg.contains(entry.value) || pkg == entry.value) {
            foundApps[entry.key] = (foundApps[entry.key] ?? 0) + minutes;
            totalMinutes += minutes;
          }
        }
      }

      final List<AppUsageInfo> apps = [];
      if (totalMinutes == 0) {
        for (final entry in kTargetPackages.entries) {
          apps.add(AppUsageInfo(
            appName: entry.key,
            packageName: entry.value,
            durationMinutes: 0,
            percentage: 0,
          ));
        }
      } else {
        for (final entry in kTargetPackages.entries) {
          final mins = foundApps[entry.key] ?? 0;
          apps.add(AppUsageInfo(
            appName: entry.key,
            packageName: entry.value,
            durationMinutes: mins,
            percentage: totalMinutes > 0 ? (mins / totalMinutes * 100) : 0,
          ));
        }
      }

      state = state.copyWith(
        isLoading: false,
        hasPermission: true,
        isSimulatorMode: false,
        telemetry: ScrollTelemetryData(
          totalScrollMinutes: totalMinutes,
          appBreakdowns: apps,
          isSimulator: false,
          hasPermission: true,
          timestamp: DateTime.now(),
          goalSettings: _cachedGoals,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasPermission: false,
        isSimulatorMode: true,
        errorMessage: 'Native telemetry query error. Switched to simulator mode.',
      );
    }
  }

  Future<void> requestPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await UsageStats.grantUsagePermission();
    } catch (_) {
      // Opening settings failed
    }
  }

  void setSimulatorMinutes(int minutes) {
    final clamped = minutes.clamp(0, 480);
    final updated = _createDefaultTelemetry(
      clamped,
      isSim: true,
      hasPerm: state.hasPermission,
      goals: state.telemetry.goalSettings,
    );
    state = state.copyWith(
      isSimulatorMode: true,
      telemetry: updated,
    );
    _persistSimMinutes(clamped);
  }

  void toggleSimulatorMode(bool enable) {
    if (enable) {
      setSimulatorMinutes(state.telemetry.totalScrollMinutes);
    } else {
      checkPermissionAndSync();
    }
  }

  Future<void> updateGoalSettings(UserGoalSettings newSettings) async {
    _cachedGoals = newSettings;
    final updated = ScrollTelemetryData(
      totalScrollMinutes: state.telemetry.totalScrollMinutes,
      appBreakdowns: state.telemetry.appBreakdowns,
      isSimulator: state.telemetry.isSimulator,
      hasPermission: state.telemetry.hasPermission,
      timestamp: state.telemetry.timestamp,
      goalSettings: newSettings,
    );
    state = state.copyWith(telemetry: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stx_primary_goal', newSettings.primaryGoal);
      await prefs.setString('stx_goal_unit_name', newSettings.goalUnitName);
      await prefs.setInt('stx_mins_per_unit', newSettings.minutesPerUnit);
      await prefs.setInt('stx_daily_limit', newSettings.dailyLimitMinutes);
    } catch (_) {}
  }

  Future<void> _persistSimMinutes(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stx_sim_minutes', minutes);
    } catch (_) {}
  }
}

final usageTrackerProvider = NotifierProvider<UsageTrackerNotifier, UsageTrackerState>(UsageTrackerNotifier.new);
