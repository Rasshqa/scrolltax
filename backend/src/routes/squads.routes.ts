// ponytail: Squads router delivering leaderboard sorted ascending by weekly scroll minutes.

import { Router, Request, Response } from 'express';
import { prisma, memoryStore, checkPrismaConnection } from '../db';
import { calculateOpportunityCost } from '../utils/calculator';

export const squadsRouter = Router();

// GET /api/v1/squads/:code/leaderboard
squadsRouter.get('/:code/leaderboard', async (req: Request, res: Response): Promise<void> => {
  try {
    const rawCode = req.params.code || '';
    const inviteCode = rawCode.trim().toUpperCase();

    const hasDb = await checkPrismaConnection();

    if (hasDb) {
      const squad = await prisma.squad.findUnique({
        where: { inviteCode },
        include: {
          members: {
            include: {
              user: {
                include: {
                  scrollLogs: {
                    where: {
                      date: {
                        gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
                      },
                    },
                  },
                },
              },
            },
          },
        },
      });

      if (squad) {
        // Aggregate 7-day stats per member
        const aggregated = squad.members.map(m => {
          const totalMins = m.user.scrollLogs.reduce((acc, log) => acc + log.totalScrollMins, 0);
          const computed = calculateOpportunityCost(totalMins, m.user.minutesPerUnit);

          return {
            userId: m.user.id,
            username: m.user.username,
            avatarUrl: m.user.avatarUrl,
            weeklyScrollMinutes: totalMins,
            codeLinesLost: computed.linesOfCodeLost,
            goalUnitsLost: computed.goalUnitsLost,
            taxPenaltyIdr: computed.taxPenaltyIdr,
          };
        });

        // Sort ascending: lowest scroll minutes wins Rank #1 (Most Disciplined)
        aggregated.sort((a, b) => a.weeklyScrollMinutes - b.weeklyScrollMinutes);

        const leaderboard = aggregated.map((entry, index) => ({
          rank: index + 1,
          ...entry,
        }));

        res.status(200).json({
          squad: {
            id: squad.id,
            name: squad.name,
            inviteCode: squad.inviteCode,
            weeklyGoal: squad.weeklyGoal,
          },
          leaderboard,
        });
        return;
      }
    }

    // In-memory fallback
    let squad = memoryStore.squads.get(inviteCode);
    if (!squad) {
      // Auto-provision squad if valid code is passed so demo is seamless
      squad = {
        id: `sq-${inviteCode.toLowerCase()}`,
        name: `${inviteCode} Squad`,
        inviteCode,
        weeklyGoal: 300,
        createdAt: new Date(),
        members: ['usr-1', 'usr-2'],
      };
      memoryStore.squads.set(inviteCode, squad);
    }

    const membersData = squad.members.map(userId => {
      const user = memoryStore.users.get(userId) || {
        id: userId,
        email: `${userId}@scrolltax.internal`,
        username: 'Squad Member',
        primaryGoal: 'Focus',
        goalUnitName: 'Units',
        minutesPerUnit: 120,
        dailyLimitMins: 60,
        createdAt: new Date(),
      };

      // Sum user scroll logs
      let totalMins = 0;
      for (const log of memoryStore.logs.values()) {
        if (log.userId === userId) {
          totalMins += log.totalScrollMins;
        }
      }

      const computed = calculateOpportunityCost(totalMins, user.minutesPerUnit);

      return {
        userId: user.id,
        username: user.username,
        avatarUrl: user.avatarUrl,
        weeklyScrollMinutes: totalMins,
        codeLinesLost: computed.linesOfCodeLost,
        goalUnitsLost: computed.goalUnitsLost,
        taxPenaltyIdr: computed.taxPenaltyIdr,
      };
    });

    // Ascending sort: lowest scroll time is highest rank
    membersData.sort((a, b) => a.weeklyScrollMinutes - b.weeklyScrollMinutes);

    const leaderboard = membersData.map((item, idx) => ({
      rank: idx + 1,
      ...item,
    }));

    res.status(200).json({
      squad: {
        id: squad.id,
        name: squad.name,
        inviteCode: squad.inviteCode,
        weeklyGoal: squad.weeklyGoal,
      },
      leaderboard,
    });
  } catch (error: any) {
    res.status(500).json({
      error: error?.message || 'Failed to fetch squad leaderboard',
    });
  }
});

// POST /api/v1/squads/join
squadsRouter.post('/join', async (req: Request, res: Response): Promise<void> => {
  try {
    const { inviteCode: rawCode, userId = 'usr_driver', username = 'You (Driver)' } = req.body;

    if (!rawCode) {
      res.status(400).json({ error: 'inviteCode is required' });
      return;
    }

    const inviteCode = String(rawCode).trim().toUpperCase();
    const hasDb = await checkPrismaConnection();

    if (hasDb) {
      // Find or create squad
      let squad = await prisma.squad.findUnique({ where: { inviteCode } });
      if (!squad) {
        squad = await prisma.squad.create({
          data: {
            name: `${inviteCode} Squad`,
            inviteCode,
            weeklyGoal: 300,
          },
        });
      }

      // Upsert User
      await prisma.user.upsert({
        where: { id: userId },
        update: { username },
        create: {
          id: userId,
          email: `${userId}@scrolltax.internal`,
          username,
        },
      });

      // Add to squad
      await prisma.squadMember.upsert({
        where: {
          squadId_userId: {
            squadId: squad.id,
            userId,
          },
        },
        update: {},
        create: {
          squadId: squad.id,
          userId,
        },
      });

      res.status(200).json({
        success: true,
        message: `Successfully joined ${squad.name}`,
        squad: {
          id: squad.id,
          name: squad.name,
          inviteCode: squad.inviteCode,
          weeklyGoal: squad.weeklyGoal,
        },
      });
      return;
    }

    // In-memory fallback
    let squad = memoryStore.squads.get(inviteCode);
    if (!squad) {
      squad = {
        id: `sq-${inviteCode.toLowerCase()}`,
        name: `${inviteCode} Squad`,
        inviteCode,
        weeklyGoal: 300,
        createdAt: new Date(),
        members: [],
      };
      memoryStore.squads.set(inviteCode, squad);
    }

    if (!squad.members.includes(userId)) {
      squad.members.push(userId);
    }

    if (!memoryStore.users.has(userId)) {
      memoryStore.users.set(userId, {
        id: userId,
        email: `${userId}@scrolltax.internal`,
        username,
        primaryGoal: 'Ship Portfolio Project',
        goalUnitName: 'Modules Built',
        minutesPerUnit: 120,
        dailyLimitMins: 60,
        createdAt: new Date(),
      });
    }

    res.status(200).json({
      success: true,
      message: `Successfully joined ${squad.name} (local mode)`,
      squad: {
        id: squad.id,
        name: squad.name,
        inviteCode: squad.inviteCode,
        weeklyGoal: squad.weeklyGoal,
      },
    });
  } catch (error: any) {
    res.status(500).json({
      error: error?.message || 'Failed to join squad',
    });
  }
});
