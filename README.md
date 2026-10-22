# ScrollTax: Doomscrolling Opportunity Cost Tracker & Squad Leaderboard

ScrollTax is a gamified productivity application that tracks time wasted on social media doomscrolling (TikTok, Instagram, X, YouTube Shorts) and converts it into concrete Opportunity Cost metrics based on your life goals: unwritten lines of code, unread book pages, delayed portfolio features, and virtual financial tax penalties.

The app features a Hypercar Telemetry Dashboard, an authentic 9:16 thermal receipt generator with serrated edges and barcode, and a competitive Squad Leaderboard where users compete for the lowest screen time (Rank #1 = Most Disciplined).

---

## Architecture Overview

```
scrolltax/
├── backend/
│   ├── prisma/
│   │   └── schema.prisma         # PostgreSQL schema (User, ScrollLog, Squad, SquadMember)
│   ├── src/
│   │   ├── index.ts              # Express API server with CORS and health checks
│   │   ├── db.ts                 # Prisma Client with in-memory persistence fallback
│   │   ├── routes/
│   │   │   ├── logs.routes.ts    # POST /api/v1/logs/sync
│   │   │   └── squads.routes.ts  # GET /api/v1/squads/:code/leaderboard, POST /api/v1/squads/join
│   │   └── utils/
│   │       └── calculator.ts     # Pure opportunity cost calculation engine
│   └── test/
│       └── calculator.test.js    # Mathematical formula verification tests
└── mobile_app/
    ├── pubspec.yaml              # Flutter 3.24+ & Dart 3 dependencies
    └── lib/
        ├── main.dart             # GoRouter navigation and Riverpod ProviderScope
        ├── core/
        │   ├── theme/
        │   │   └── hypercar_theme.dart        # Hypercar palette (#070709, #FF5500, #00F0FF, #10B981)
        │   ├── models/
        │   │   └── scroll_telemetry.dart      # Unified telemetry and goal models
        │   ├── services/
        │   │   ├── usage_tracker_service.dart # Android UsageStatsManager + Web/iOS simulator
        │   │   └── squad_api_service.dart     # Backend API client with offline fallback
        │   └── utils/
        │       └── opportunity_calculator.dart# TRD mathematical formulas
        └── features/
            ├── dashboard/
            │   ├── dashboard_screen.dart      # Hypercar dashboard and opportunity breakdown
            │   └── widgets/
            │       └── rpm_tax_gauge.dart     # Tachometer arc widget (0-180m+ zones)
            ├── receipt/
            │   ├── receipt_screen.dart        # 9:16 thermal receipt share and export
            │   └── widgets/
            │       └── serrated_receipt_card.dart # CustomClipper zigzag receipt with barcode
            └── squads/
                └── squad_leaderboard_screen.dart  # Multi-player discipline leaderboard
```

---

## Opportunity Cost Formulas (TRD Implementation)

Given total daily doomscrolling duration in minutes ($T$):

1. **Lines of Code Unwritten ($L$):**
   $$L = \lfloor \frac{T}{60} \times 80 \rfloor$$

2. **Book Pages Unread ($P$):**
   $$P = \lfloor \frac{T}{2.5} \rfloor$$

3. **Custom Goal Units Lost ($U$):**
   $$U = \text{round}\left(\frac{T}{M_{\text{unit}}}, 2\right)$$
   (where $M_{\text{unit}}$ is minutes required for 1 unit of user target, default 120 minutes)

4. **Virtual Tax Penalty ($V_{\text{IDR}}$):**
   $$V_{\text{IDR}} = T \times 1500 \text{ IDR}$$
   (based on standard productive time valuation of Rp 90.000/hour)

5. **Tax Severity Tiers:**
   - $T \le 30$: `NOMINAL (GREEN)` (#10B981)
   - $30 < T \le 90$: `WARNING (AMBER)` (#FFB800)
   - $90 < T \le 180$: `HEAVY TAX (HYPER-ORANGE)` (#FF5500)
   - $T > 180$: `CRITICAL BANKRUPTCY (CRIMSON)` (#FF2A54)

---

## Key Interactive Features

- **Tachometer RPM Gauge with 5-LED Rev-Limiter:** CustomPainter tachometer arc featuring an F1-style 5-LED shift-light bar that shifts from green to amber and flashes red when reaching the 180m+ redline zone.
- **Interactive Telemetry Slider & Quick Jump Presets:** Smooth slider spanning 0 to 360 minutes, with 1-click jump pills (`0m Zero`, `+15m`, `+30m`, `+60m`, `180m Redline`, `360m Max`) for rapid simulation.
- **Real-Time Burn Rate & Overdraft HUD:** Live tracking of hourly opportunity cost accrual (Rp 90,000/hour), severity tiers, and real-time budget deficit delta.
- **9:16 Serrated Thermal Receipt:** Dual-skin thermal receipt (Matte Paper and Stealth Carbon) with custom clipped zigzag edges, Code128 barcode, app breakdown, and PNG image export.
- **Squad Leaderboard & Top 3 Podium:** Multiplayer competition ranking racers by lowest screen time, featuring an elevated Top 3 podium with Gold, Silver, and Bronze trophies, pacesetter badges, and live sync to the Prisma/PostgreSQL backend.

---

## Design System: Hypercar Telemetry

- **Deep Obsidian Background:** `#070709`
- **Dashboard Surface:** `#111216` (Border: `#22242C`)
- **Primary Danger / Tax Accent:** `#FF5500` (Solar Hyper-Orange) & `#FF2A54` (Laser Red)
- **Safe / Disciplined Accent:** `#00F0FF` (Cyber Cyan) & `#10B981` (Matrix Green)
- **Thermal Receipt Surfaces:** Dual-skin support:
  - *Matte Paper:* `#F4F4F0` with `#09090B` high-contrast ink
  - *Stealth Carbon:* `#121318` with `#FF5500` accents
- **Typography:**
  - Headings and tachometer figures: `Space Grotesk` (tabular numbers)
  - Telemetry and thermal receipt: `JetBrains Mono`

---

## Getting Started

### Prerequisites
- Flutter SDK 3.24+ (Dart 3.x)
- Node.js 18+ (tested on Node v20/v26)
- npm or pnpm
- (Optional) PostgreSQL database for persistent cloud synchronization

---

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. (Optional) Configure database URL in `.env`:
   ```bash
   DATABASE_URL="postgresql://user:password@localhost:5432/scrolltax?schema=public"
   ```
   *Note: If no database URL is set, the backend seamlessly runs with an in-memory repository for development and demo mode.*

4. Generate Prisma client and compile TypeScript:
   ```bash
   npx prisma generate
   npm run build
   ```

5. Run formula tests:
   ```bash
   npm test
   ```

6. Start the API server:
   ```bash
   npm start
   # API runs at http://localhost:4000
   ```

---

### Mobile Application Setup

1. Navigate to the mobile application directory:
   ```bash
   cd mobile_app
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run unit tests:
   ```bash
   flutter test
   ```

4. Run code analysis (clean linter check):
   ```bash
   flutter analyze
   ```

5. Build for Web:
   ```bash
   flutter build web --release
   ```

6. Build Android APK:
   ```bash
   flutter build apk --release
   ```

7. Run in Chrome (with Interactive Telemetry Simulator):
   ```bash
   flutter run -d chrome
   ```

---

## REST API Specification

### 1. Synchronize Daily Telemetry
- **Endpoint:** `POST /api/v1/logs/sync`
- **Request Body:**
  ```json
  {
    "userId": "usr_driver",
    "username": "You (Driver)",
    "date": "2026-10-22",
    "totalScrollMins": 140,
    "appBreakdown": {
      "TikTok": 65,
      "Instagram": 40,
      "X (Twitter)": 20,
      "YouTube": 15
    },
    "minutesPerUnit": 120
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Telemetry synchronized via PostgreSQL",
    "log": {
      "id": "log-1",
      "userId": "usr_driver",
      "date": "2026-10-22",
      "totalScrollMins": 140,
      "codeLinesLost": 186,
      "goalUnitsLost": 1.17,
      "taxPenaltyIdr": 210000,
      "syncedAt": "2026-10-22T10:45:00.000Z"
    }
  }
  ```

### 2. Get Squad Leaderboard
- **Endpoint:** `GET /api/v1/squads/:code/leaderboard`
- **Description:** Returns squad members sorted ascending by 7-day scroll minutes (Rank #1 = Most Disciplined).
- **Response (200 OK):**
  ```json
  {
    "squad": {
      "id": "sq-1",
      "name": "Hypercar Circle",
      "inviteCode": "DEV-404",
      "weeklyGoal": 300
    },
    "leaderboard": [
      {
        "rank": 1,
        "userId": "usr-1",
        "username": "Alex R. (Discipline Lead)",
        "weeklyScrollMinutes": 18,
        "codeLinesLost": 24,
        "goalUnitsLost": 0.15,
        "taxPenaltyIdr": 27000
      }
    ]
  }
  ```

### 3. Join Squad
- **Endpoint:** `POST /api/v1/squads/join`
- **Request Body:**
  ```json
  {
    "inviteCode": "DEV-404",
    "userId": "usr_driver",
    "username": "You (Driver)"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Successfully joined Hypercar Circle",
    "squad": {
      "id": "sq-1",
      "name": "Hypercar Circle",
      "inviteCode": "DEV-404",
      "weeklyGoal": 300
    }
  }
  ```

---

## License
MIT License. Built by Rasshqa for the Portfolio Batch project.
