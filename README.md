# TruckLink PK (ٹرک لنک پی کے)

> Pakistan's Freight, Route Intelligence & Fleet Logistics Platform

🌐 **Live Web Application:** [https://trucklink-pk.web.app](https://trucklink-pk.web.app)  
🚀 **Firebase Project:** `trucker-s-website` (Hosting target: `trucklink-pk`, Region: `asia-south1`)

---

## Overview

**TruckLink PK** connects truck drivers, fleet owners, and freight shippers across Pakistan with real-time loads matching, bridge clearance & overhead hazard warnings, city curfew entry timings, and bilingual (English / اردو) support.

### Key Capabilities
- **Real-Time Loads Feed & Bidding:** Instant load requests with weight, vehicle requirements, and rate negotiation.
- **Route Intelligence & Bridge Clearances:** Interactive Google Maps with turn-by-turn route guidance, CPEC / N-5 / Motorway corridors, and bridge clearance calculations based on vehicle height.
- **City Entry & Curfew Windows:** Live countdowns and curfew timings for heavy vehicles across major Pakistani hubs (Karachi, Lahore, Islamabad/Rawalpindi, Multan).
- **Driver Verification Panel:** Admin review and verification for NADRA CNIC, HTV/LTV driving license, and vehicle registration documents.
- **Automated Cloud Push Notifications:** Real-time FCM notifications for bids, approvals, and highway hazard alerts.
- **Anti-Bot Defense:** Integrated browser challenge to secure sign-in and protect against automated bots.

---

## Tech Stack & Architecture

- **Frontend:** Flutter Web (Dart 3, pure zero-dependency `AppScope` + `InheritedNotifier` reactive state).
- **Backend Services:** Firebase Authentication (Phone OTP & Email), Cloud Firestore, Firebase Storage, and Cloud Functions v2 (Node 22, `asia-south1`).
- **Mapping & Geocoding:** Google Maps JavaScript SDK v2 and bespoke Pakistani Logistics Geocoding Service.
- **Bilingual Engine:** Flutter `flutter_localizations` with native Urdu typography (Noto Nastaliq Urdu).

---

## Development & Deployment

### Run Locally
```bash
flutter pub get
flutter run -d chrome
```

### Run Tests & Static Analysis
```bash
flutter analyze
flutter test
```

### Build & Deploy to Firebase
```bash
# Build production web bundle
flutter build web --release

# Deploy Hosting to https://trucklink-pk.web.app and Cloud Functions
firebase deploy --only hosting,functions --project trucker-s-website
```
