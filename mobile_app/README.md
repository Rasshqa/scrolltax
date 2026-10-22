# ScrollTax Mobile App (Flutter & Web)

The official Flutter client for ScrollTax, built with Flutter 3.24+ and Dart 3.

---

## Features

- **Hypercar Tachometer RPM Gauge:** CustomPainter curved tachometer with an F1-style 5-LED shift-light rev-indicator, dynamic color zones (Green, Amber, Orange, Laser Red), and redline visual warning.
- **Interactive Telemetry Slider:** 0 to 360m slider with 1-click jump shortcuts (`0m Zero`, `+15m`, `+30m`, `+60m`, `180m Redline`, `360m Max`).
- **Real-Time Burn Rate & Overdraft HUD:** Live tracking of hourly opportunity cost (Rp 90k/h), severity tier, and budget delta.
- **Opportunity Cost Breakdown Cards:** Real-time calculation of Code Unwritten, Pages Unread, Custom Goal Units Deferred, and Virtual Tax Levy.
- **Serrated Thermal Receipt (9:16):** CustomClipper zigzag thermal receipt with Code128 barcode, app breakdown, dual skin (Matte Paper and Stealth Carbon), and 1-click PNG image export.
- **Squad Leaderboard & Top 3 Podium:** Multiplayer competition ranking racers by discipline with elevated Gold, Silver, and Bronze podiums.
- **Dual Platform Support:** Runs natively on Android (`UsageStatsManager`) and on Web/iOS with an interactive telemetry simulator.

---

## Getting Started

```bash
cd mobile_app
flutter pub get
flutter test
flutter build web --release
flutter build apk --release
```
