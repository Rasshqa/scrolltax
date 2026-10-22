// ponytail: Log synchronization route recalculating opportunity metrics server-side.

import { Router, Request, Response } from 'express';
import { calculateOpportunityCost } from '../utils/calculator';
import { prisma, memoryStore, checkPrismaConnection } from '../db';

export const logsRouter = Router();

logsRouter.post('/sync', async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      userId = 'usr_driver',
      username = 'You (Driver)',
      totalScrollMins = 0,
      appBreakdown = {},
      date,
      minutesPerUnit = 120,
    } = req.body;

    const scrollMins = Math.max(0, Number(totalScrollMins) || 0);
    const logDate = date ? new Date(date) : new Date();
    const dateString = logDate.toISOString().slice(0, 10);

    // ponytail: Server recalculates metrics guaranteeing mathematical integrity
    const computed = calculateOpportunityCost(scrollMins, Number(minutesPerUnit) || 120);

    const hasDb = await checkPrismaConnection();

    if (hasDb) {
      // Upsert User
      const user = await prisma.user.upsert({
        where: { id: userId },
        update: { username },
        create: {
          id: userId,
          email: `${userId}@scrolltax.internal`,
          username,
          minutesPerUnit: Number(minutesPerUnit) || 120,
        },
      });

      // Upsert ScrollLog
      const log = await prisma.scrollLog.upsert({
        where: {
          userId_date: {
            userId: user.id,
            date: new Date(dateString),
          },
        },
        update: {
          totalScrollMins: scrollMins,
          appBreakdown,
          codeLinesLost: computed.linesOfCodeLost,
          goalUnitsLost: computed.goalUnitsLost,
          taxPenaltyIdr: computed.taxPenaltyIdr,
          syncedAt: new Date(),
        },
        create: {
          userId: user.id,
          date: new Date(dateString),
          totalScrollMins: scrollMins,
          appBreakdown,
          codeLinesLost: computed.linesOfCodeLost,
          goalUnitsLost: computed.goalUnitsLost,
          taxPenaltyIdr: computed.taxPenaltyIdr,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Telemetry synchronized via PostgreSQL',
        source: 'database',
        log,
      });
      return;
    }

    // Fallback in-memory persistence
    const logId = `log-${Date.now()}`;
    const mockLog = {
      id: logId,
      userId,
      date: dateString,
      totalScrollMins: scrollMins,
      appBreakdown,
      codeLinesLost: computed.linesOfCodeLost,
      goalUnitsLost: computed.goalUnitsLost,
      taxPenaltyIdr: computed.taxPenaltyIdr,
      syncedAt: new Date(),
    };

    memoryStore.logs.set(`${userId}_${dateString}`, mockLog);
    if (!memoryStore.users.has(userId)) {
      memoryStore.users.set(userId, {
        id: userId,
        email: `${userId}@scrolltax.internal`,
        username,
        primaryGoal: 'Ship Portfolio Project',
        goalUnitName: 'Modules Built',
        minutesPerUnit: Number(minutesPerUnit) || 120,
        dailyLimitMins: 60,
        createdAt: new Date(),
      });
    }

    res.status(200).json({
      success: true,
      message: 'Telemetry synchronized locally',
      source: 'memory',
      log: mockLog,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error?.message || 'Failed to sync scroll telemetry',
    });
  }
});
