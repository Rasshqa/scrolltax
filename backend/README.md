# ScrollTax Backend API & Telemetry Service

High-performance Node.js / Express API powering the ScrollTax telemetry engine, squad synchronization, and discipline leaderboards.

---

## Tech Stack & Architecture

- **Runtime:** Node.js 18+ (tested on Node v20/v26)
- **Framework:** Express with CORS, Helmet, and native JSON parsing
- **ORM & Database:** Prisma ORM with PostgreSQL schema (`User`, `ScrollLog`, `Squad`, `SquadMember`)
- **Resilience Fallback:** Built-in in-memory state engine ensuring full functionality even if PostgreSQL is offline
- **TypeScript:** Fast TS execution and testing via `tsx`

---

## API Endpoints

### 1. Health Check
- **`GET /api/health`**
- Returns server status, timestamp, and database connectivity.

### 2. Telemetry Sync
- **`POST /api/v1/logs/sync`**
- Ingests daily doomscrolling duration and app breakdown from the mobile client.
- Computes opportunity cost metrics (lines of code unwritten, book pages unread, tax penalty IDR).
- Request Payload:
  ```json
  {
    "userId": "user_current",
    "username": "Driver Alpha",
    "totalScrollMinutes": 135,
    "appBreakdown": {
      "com.zhiliaoapp.musically": 65,
      "com.instagram.android": 45,
      "com.twitter.android": 25
    },
    "codeLinesLost": 180,
    "goalUnitsLost": 1.12,
    "taxPenaltyIdr": 202500
  }
  ```

### 3. Squad Leaderboard
- **`GET /api/v1/squads/:code/leaderboard`**
- Returns squad info and ranked racer list ordered by lowest weekly doomscrolling minutes (Rank #1 = Most Disciplined Pacesetter).

### 4. Join Squad
- **`POST /api/v1/squads/join`**
- Joins a squad by invite code (e.g. `DEV-404`, `STUDIO`).

---

## Development Setup

```bash
cd backend
npm install
npx prisma generate
npm test
npm run build
npm start
# Server runs on http://localhost:8080
```
