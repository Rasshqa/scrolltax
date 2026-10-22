// ponytail: Direct HTTP client with offline mock fallback for squad leaderboards.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SquadLeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final int weeklyScrollMinutes;
  final int codeLinesLost;
  final double goalUnitsLost;
  final int taxPenaltyIdr;

  const SquadLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.weeklyScrollMinutes,
    required this.codeLinesLost,
    required this.goalUnitsLost,
    required this.taxPenaltyIdr,
  });

  factory SquadLeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) {
    return SquadLeaderboardEntry(
      rank: rank,
      userId: json['userId'] ?? json['id'] ?? 'user-anonymous',
      username: json['username'] ?? 'Anonymous Racer',
      avatarUrl: json['avatarUrl'],
      weeklyScrollMinutes: json['weeklyScrollMinutes'] ?? json['totalScrollMins'] ?? 0,
      codeLinesLost: json['codeLinesLost'] ?? 0,
      goalUnitsLost: (json['goalUnitsLost'] as num?)?.toDouble() ?? 0.0,
      taxPenaltyIdr: json['taxPenaltyIdr'] ?? 0,
    );
  }
}

class SquadDetails {
  final String id;
  final String name;
  final String inviteCode;
  final int weeklyGoal;
  final List<SquadLeaderboardEntry> leaderboard;

  const SquadDetails({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.weeklyGoal,
    required this.leaderboard,
  });
}

class SquadApiService {
  // Default backend base URL; customizable via preferences
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:4000';
    // On Android emulator, 10.0.2.2 points to host machine localhost
    return 'http://10.0.2.2:4000';
  }

  static Future<String> getBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('stx_backend_url') ?? defaultBaseUrl;
    } catch (_) {
      return defaultBaseUrl;
    }
  }

  static Future<SquadDetails> fetchLeaderboard(String inviteCode) async {
    final baseUrl = await getBaseUrl();
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/squads/$inviteCode/leaderboard'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final members = (data['leaderboard'] as List? ?? [])
            .asMap()
            .entries
            .map((e) => SquadLeaderboardEntry.fromJson(e.value, e.key + 1))
            .toList();

        return SquadDetails(
          id: data['squad']['id'] ?? 'squad-1',
          name: data['squad']['name'] ?? 'Hypercar Circle',
          inviteCode: data['squad']['inviteCode'] ?? inviteCode,
          weeklyGoal: data['squad']['weeklyGoal'] ?? 300,
          leaderboard: members,
        );
      }
    } catch (_) {
      // ponytail: Fall back to simulated squad when backend is unreachable
    }

    return _getMockSquadDetails(inviteCode);
  }

  static Future<Map<String, dynamic>> joinSquad({
    required String inviteCode,
    required String userId,
    required String username,
  }) async {
    final baseUrl = await getBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/squads/join'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'inviteCode': inviteCode,
              'userId': userId,
              'username': username,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (_) {
      // ponytail: Fallback to local success when offline
    }

    return {
      'success': true,
      'message': 'Joined squad locally (demo mode)',
      'inviteCode': inviteCode,
    };
  }

  static Future<bool> syncLogs({
    required String userId,
    required String username,
    required int totalScrollMinutes,
    required Map<String, int> appBreakdown,
    required int codeLinesLost,
    required double goalUnitsLost,
    required int taxPenaltyIdr,
  }) async {
    final baseUrl = await getBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/logs/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'username': username,
              'totalScrollMins': totalScrollMinutes,
              'appBreakdown': appBreakdown,
              'codeLinesLost': codeLinesLost,
              'goalUnitsLost': goalUnitsLost,
              'taxPenaltyIdr': taxPenaltyIdr,
              'date': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static SquadDetails _getMockSquadDetails(String code) {
    return SquadDetails(
      id: 'mock-squad-$code',
      name: 'Alpha Hypercar Devs',
      inviteCode: code.toUpperCase(),
      weeklyGoal: 300,
      leaderboard: const [
        SquadLeaderboardEntry(
          rank: 1,
          userId: 'u1',
          username: 'cyber_monk',
          weeklyScrollMinutes: 75,
          codeLinesLost: 100,
          goalUnitsLost: 0.6,
          taxPenaltyIdr: 112500,
        ),
        SquadLeaderboardEntry(
          rank: 2,
          userId: 'u2',
          username: 'neon_hacker',
          weeklyScrollMinutes: 140,
          codeLinesLost: 186,
          goalUnitsLost: 1.16,
          taxPenaltyIdr: 210000,
        ),
        SquadLeaderboardEntry(
          rank: 3,
          userId: 'u3',
          username: 'terminal_racer',
          weeklyScrollMinutes: 210,
          codeLinesLost: 280,
          goalUnitsLost: 1.75,
          taxPenaltyIdr: 315000,
        ),
        SquadLeaderboardEntry(
          rank: 4,
          userId: 'u4',
          username: 'doom_scroller',
          weeklyScrollMinutes: 480,
          codeLinesLost: 640,
          goalUnitsLost: 4.0,
          taxPenaltyIdr: 720000,
        ),
      ],
    );
  }
}
