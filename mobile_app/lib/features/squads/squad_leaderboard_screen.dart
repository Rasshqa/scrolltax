// ponytail: Squad leaderboard screen highlighting lowest scroll time with full empty/loading/error handling.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/squad_api_service.dart';
import '../../core/services/usage_tracker_service.dart';
import '../../core/theme/hypercar_theme.dart';

class SquadLeaderboardScreen extends ConsumerStatefulWidget {
  const SquadLeaderboardScreen({super.key});

  @override
  ConsumerState<SquadLeaderboardScreen> createState() => _SquadLeaderboardScreenState();
}

class _SquadLeaderboardScreenState extends ConsumerState<SquadLeaderboardScreen> {
  String _currentInviteCode = 'DEV-404';
  late Future<SquadDetails> _squadFuture;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSquad();
  }

  void _loadSquad() {
    setState(() {
      _squadFuture = SquadApiService.fetchLeaderboard(_currentInviteCode);
    });
  }

  Future<void> _syncCurrentTelemetry() async {
    setState(() => _isSyncing = true);
    final telemetry = ref.read(usageTrackerProvider).telemetry;
    final calc = telemetry.calculation;

    final success = await SquadApiService.syncLogs(
      userId: 'user_current',
      username: 'You (Driver)',
      totalScrollMinutes: telemetry.totalScrollMinutes,
      appBreakdown: telemetry.appBreakdownMap,
      codeLinesLost: calc.linesOfCodeLost,
      goalUnitsLost: calc.goalUnitsLost,
      taxPenaltyIdr: calc.taxPenaltyIdr,
    );

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: HypercarColors.carbonElevated,
          content: Text(
            success ? 'Telemetry synced to squad!' : 'Saved locally (Backend offline).',
            style: HypercarTheme.monoStyle(
              color: success ? HypercarColors.matrixGreen : HypercarColors.amberWarning,
            ),
          ),
        ),
      );
      _loadSquad();
    }
  }

  void _showJoinSquadDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: HypercarColors.carbonSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: HypercarColors.carbonBorder),
          ),
          title: Text(
            'JOIN OR SWITCH SQUAD',
            style: HypercarTheme.monoStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: HypercarColors.solarOrange,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter 6-character squad code (e.g. DEV-404, STUDIO):',
                style: TextStyle(
                  fontSize: 12,
                  color: HypercarColors.textSecondary,
                  fontFamily: 'Space Grotesk',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 7,
                decoration: const InputDecoration(
                  hintText: 'DEV-404',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: HypercarColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final code = codeCtrl.text.trim().toUpperCase();
                if (code.isNotEmpty) {
                  setState(() {
                    _currentInviteCode = code;
                  });
                  _loadSquad();
                }
                Navigator.pop(ctx);
              },
              child: const Text('CONNECT'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HypercarColors.obsidianBg,
      appBar: AppBar(
        backgroundColor: HypercarColors.obsidianBg,
        elevation: 0,
        title: Text(
          'SQUAD LEADERBOARD',
          style: HypercarTheme.monoStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync screen time',
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: HypercarColors.solarOrange),
                  )
                : const Icon(Icons.cloud_upload_outlined, color: HypercarColors.cyberCyan),
            onPressed: _isSyncing ? null : _syncCurrentTelemetry,
          ),
          IconButton(
            tooltip: 'Join Squad',
            icon: const Icon(Icons.group_add_outlined, color: HypercarColors.solarOrange),
            onPressed: _showJoinSquadDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<SquadDetails>(
          future: _squadFuture,
          builder: (context, snapshot) {
            // Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: HypercarColors.solarOrange),
              );
            }

            // Error State
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: HypercarColors.laserRed),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load squad telemetry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: HypercarColors.textPrimary,
                          fontFamily: 'Space Grotesk',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: HypercarTheme.monoStyle(fontSize: 11, color: HypercarColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSquad,
                        child: const Text('RETRY CONNECTION'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final squad = snapshot.data!;
            final members = squad.leaderboard;

            // Empty State
            if (members.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_outlined, size: 54, color: HypercarColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'NO RACERS IN SQUAD YET',
                        style: HypercarTheme.monoStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: HypercarColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to join squad $_currentInviteCode and log screen time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: HypercarColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _syncCurrentTelemetry,
                        child: const Text('SYNC MY SCREEN TIME'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: HypercarColors.solarOrange,
              backgroundColor: HypercarColors.carbonSurface,
              onRefresh: () async => _loadSquad(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Squad Info Banner
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      squad.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: HypercarColors.textPrimary,
                                        fontFamily: 'Space Grotesk',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Target: Max ${squad.weeklyGoal}m scroll / week',
                                      style: HypercarTheme.monoStyle(
                                        fontSize: 11,
                                        color: HypercarColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: squad.inviteCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: HypercarColors.carbonElevated,
                                      content: Text(
                                        'Code ${squad.inviteCode} copied to clipboard!',
                                        style: HypercarTheme.monoStyle(color: HypercarColors.cyberCyan),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: HypercarColors.carbonElevated,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: HypercarColors.cyberCyan.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        squad.inviteCode,
                                        style: HypercarTheme.monoStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: HypercarColors.cyberCyan,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.copy_rounded, size: 12, color: HypercarColors.cyberCyan),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ranked by lowest screen time. Rank #1 is the most disciplined racer.',
                            style: HypercarTheme.monoStyle(fontSize: 10, color: HypercarColors.textMuted),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    if (members.length >= 2) ...[
                      _buildTopThreePodium(members, squad.weeklyGoal),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'DISCIPLINE RANKINGS',
                      style: HypercarTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: HypercarColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Ranked Member List
                    ...members.map((member) {
                      final isFirst = member.rank == 1;
                      final isSecond = member.rank == 2;
                      final isThird = member.rank == 3;
                      final isCurrentUser = member.userId == 'user_current' || member.username.toLowerCase().contains('you');
                      final isOverGoal = member.weeklyScrollMinutes > squad.weeklyGoal;

                      final rankColor = isFirst
                          ? const Color(0xFFFFB800)
                          : isSecond
                              ? const Color(0xFFE2E8F0)
                              : isThird
                                  ? const Color(0xFFCD7F32)
                                  : HypercarColors.textMuted;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? HypercarColors.cyberCyan.withValues(alpha: 0.05)
                              : HypercarColors.carbonSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrentUser
                                ? HypercarColors.cyberCyan
                                : isFirst
                                    ? const Color(0xFFFFB800).withValues(alpha: 0.8)
                                    : isOverGoal
                                        ? HypercarColors.laserRed.withValues(alpha: 0.4)
                                        : HypercarColors.carbonBorder,
                            width: isCurrentUser || isFirst ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank Badge
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: rankColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: rankColor.withValues(alpha: 0.6),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '#${member.rank}',
                                style: HypercarTheme.monoStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: rankColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Member info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        member.username,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isCurrentUser ? HypercarColors.cyberCyan : HypercarColors.textPrimary,
                                          fontFamily: 'Space Grotesk',
                                        ),
                                      ),
                                      if (isCurrentUser) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: HypercarColors.cyberCyan.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(3),
                                            border: Border.all(color: HypercarColors.cyberCyan.withValues(alpha: 0.5)),
                                          ),
                                          child: Text(
                                            'YOU',
                                            style: HypercarTheme.monoStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: HypercarColors.cyberCyan,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (isFirst) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            'PACESETTER',
                                            style: HypercarTheme.monoStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFFFB800),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${member.codeLinesLost} LOC unwritten | Rp ${(member.taxPenaltyIdr / 1000).toStringAsFixed(0)}k Tax',
                                    style: HypercarTheme.monoStyle(
                                      fontSize: 10,
                                      color: HypercarColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Weekly minutes indicator
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${member.weeklyScrollMinutes}m',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isFirst
                                        ? const Color(0xFFFFB800)
                                        : isOverGoal
                                            ? HypercarColors.laserRed
                                            : HypercarColors.textPrimary,
                                    fontFamily: 'Space Grotesk',
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                Text(
                                  '7-day scroll',
                                  style: HypercarTheme.monoStyle(fontSize: 9, color: HypercarColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopThreePodium(List<SquadLeaderboardEntry> members, int weeklyGoal) {
    final first = members.firstWhere((m) => m.rank == 1, orElse: () => members[0]);
    final second = members.length > 1 ? members.firstWhere((m) => m.rank == 2, orElse: () => members[1]) : null;
    final third = members.length > 2 ? members.firstWhere((m) => m.rank == 3, orElse: () => members[2]) : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: HypercarColors.carbonElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HypercarColors.carbonBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SQUAD PODIUM',
                style: HypercarTheme.monoStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: HypercarColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const Icon(Icons.emoji_events_rounded, size: 16, color: Color(0xFFFFB800)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (second != null)
                _buildPodiumStep(
                  rank: 2,
                  member: second,
                  color: const Color(0xFFE2E8F0),
                  height: 70,
                ),
              _buildPodiumStep(
                rank: 1,
                member: first,
                color: const Color(0xFFFFB800),
                height: 95,
                isCrown: true,
              ),
              if (third != null)
                _buildPodiumStep(
                  rank: 3,
                  member: third,
                  color: const Color(0xFFCD7F32),
                  height: 55,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep({
    required int rank,
    required SquadLeaderboardEntry member,
    required Color color,
    required double height,
    bool isCrown = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCrown)
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800), size: 20)
        else
          Icon(Icons.shield_outlined, color: color, size: 16),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            member.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Space Grotesk',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${member.weeklyScrollMinutes}m',
          style: HypercarTheme.monoStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 72,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: HypercarTheme.monoStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
