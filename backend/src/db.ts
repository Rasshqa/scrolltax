// ponytail: Dual-layer persistence using Prisma with in-memory fallback for offline/demo operation.

import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

// In-memory data store for fallback/demo mode when PostgreSQL is not configured
interface MockUser {
  id: string;
  email: string;
  username: string;
  avatarUrl?: string;
  primaryGoal: string;
  goalUnitName: string;
  minutesPerUnit: number;
  dailyLimitMins: number;
  createdAt: Date;
}

interface MockLog {
  id: string;
  userId: string;
  date: string; // YYYY-MM-DD
  totalScrollMins: number;
  appBreakdown: Record<string, number>;
  codeLinesLost: number;
  goalUnitsLost: number;
  taxPenaltyIdr: number;
  syncedAt: Date;
}

interface MockSquad {
  id: string;
  name: string;
  inviteCode: string;
  weeklyGoal: number;
  createdAt: Date;
  members: string[]; // userIds
}

class MemoryStore {
  users: Map<string, MockUser> = new Map();
  logs: Map<string, MockLog> = new Map();
  squads: Map<string, MockSquad> = new Map();

  constructor() {
    this.seedDefaultData();
  }

  // ponytail: Preload realistic squads so leaderboard demo works immediately out of the box
  private seedDefaultData() {
    const seedSquads = [
      { id: 'sq-1', name: 'Hypercar Circle', inviteCode: 'DEV-404', weeklyGoal: 300 },
      { id: 'sq-2', name: 'Zero Distraction Studio', inviteCode: 'STUDIO', weeklyGoal: 240 },
      { id: 'sq-3', name: 'Matrix Speed Team', inviteCode: 'TITAN6', weeklyGoal: 180 },
    ];

    const seedUsers: MockUser[] = [
      {
        id: 'usr-1',
        email: 'alex.hyper@scrolltax.dev',
        username: 'Alex R. (Discipline Lead)',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop&crop=faces',
        primaryGoal: 'Ship Portfolio Project',
        goalUnitName: 'Modules Built',
        minutesPerUnit: 120,
        dailyLimitMins: 45,
        createdAt: new Date(),
      },
      {
        id: 'usr-2',
        email: 'sara.code@scrolltax.dev',
        username: 'Sara K. (Kernel Dev)',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&h=100&fit=crop&crop=faces',
        primaryGoal: 'Read Operating Systems Book',
        goalUnitName: 'Chapters Read',
        minutesPerUnit: 90,
        dailyLimitMins: 60,
        createdAt: new Date(),
      },
      {
        id: 'usr-3',
        email: 'marcus.turbo@scrolltax.dev',
        username: 'Marcus V. (Apex Racer)',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=faces',
        primaryGoal: 'Full-Stack Rust App',
        goalUnitName: 'Endpoints Shipped',
        minutesPerUnit: 120,
        dailyLimitMins: 60,
        createdAt: new Date(),
      },
      {
        id: 'usr-4',
        email: 'diana.matrix@scrolltax.dev',
        username: 'Diana L. (Heavy Scroller)',
        avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100&h=100&fit=crop&crop=faces',
        primaryGoal: 'Learn Machine Learning',
        goalUnitName: 'Papers Read',
        minutesPerUnit: 120,
        dailyLimitMins: 60,
        createdAt: new Date(),
      },
    ];

    seedUsers.forEach(u => this.users.set(u.id, u));

    seedSquads.forEach(s => {
      this.squads.set(s.inviteCode, {
        ...s,
        createdAt: new Date(),
        members: ['usr-1', 'usr-2', 'usr-3', 'usr-4'],
      });
    });

    // Seed realistic 7-day scroll logs
    const seedLogs: Array<Omit<MockLog, 'id' | 'syncedAt'>> = [
      {
        userId: 'usr-1',
        date: '2026-10-22',
        totalScrollMins: 18,
        appBreakdown: { 'X (Twitter)': 10, 'YouTube': 8 },
        codeLinesLost: 24,
        goalUnitsLost: 0.15,
        taxPenaltyIdr: 27000,
      },
      {
        userId: 'usr-2',
        date: '2026-10-22',
        totalScrollMins: 42,
        appBreakdown: { 'Instagram': 25, 'TikTok': 17 },
        codeLinesLost: 56,
        goalUnitsLost: 0.35,
        taxPenaltyIdr: 63000,
      },
      {
        userId: 'usr-3',
        date: '2026-10-22',
        totalScrollMins: 75,
        appBreakdown: { 'TikTok': 45, 'YouTube': 30 },
        codeLinesLost: 100,
        goalUnitsLost: 0.63,
        taxPenaltyIdr: 112500,
      },
      {
        userId: 'usr-4',
        date: '2026-10-22',
        totalScrollMins: 165,
        appBreakdown: { 'TikTok': 90, 'Instagram': 55, 'YouTube': 20 },
        codeLinesLost: 220,
        goalUnitsLost: 1.38,
        taxPenaltyIdr: 247500,
      },
    ];

    seedLogs.forEach((l, index) => {
      const id = `log-seed-${index + 1}`;
      this.logs.set(`${l.userId}_${l.date}`, {
        ...l,
        id,
        syncedAt: new Date(),
      });
    });
  }
}

export const memoryStore = new MemoryStore();

let isPrismaConnected: boolean | null = null;

export async function checkPrismaConnection(): Promise<boolean> {
  if (isPrismaConnected !== null) return isPrismaConnected;
  if (!process.env.DATABASE_URL) {
    isPrismaConnected = false;
    return false;
  }
  try {
    await prisma.$connect();
    isPrismaConnected = true;
    return true;
  } catch {
    isPrismaConnected = false;
    return false;
  }
}
