# Truck Driver Platform — Complete Technical Blueprint

## 1. Project Overview

**Product Name (working):** TruckLink PK  
**Platform:** Flutter (mobile + web) — single codebase  
**Backend:** Supabase (PostgreSQL + Edge Functions + Realtime + Storage)  
**Development Environment:** Google Antigravity IDE with Dart/Flutter plugin  

This blueprint is structured as an **Antigravity-ready specification** — every section maps to agent tasks that Antigravity can execute in its Manager Surface, using its multi-agent orchestration to build features in parallel across editor, terminal, and browser.

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ FLUTTER CLIENT LAYER                                        │
│ ┌──────────────┐     ┌──────────────┐    ┌──────────────┐   │
│ │  Driver App  │     │  Owner App   │    │  Web Admin   │   │
│ │  (Android)   │     │  (Android)   │    │  (Flutter    │   │
│ │              │     │              │    │    Web)      │   │
│ └──────┬───────┘     └──────┬───────┘    └──────┬───────┘   │
└─────────┼───────────────────┼───────────────────┼───────────┘
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────┐
│ API GATEWAY (Supabase Edge Functions)                       │
│ Auth │ Loads │ Drivers │ Routes │ Alerts │ Chat │ Payments  │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────────┐
│ PostgreSQL   │   │ Realtime     │   │ Storage (S3-     │
│ + PostGIS    │   │ (WebSocket)  │   │ compatible CDN)  │
│ + TimescaleDB│   │              │   │                  │
└──────────────┘   └──────────────┘   └──────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│ EXTERNAL SERVICE INTEGRATIONS                               │
│ ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌───────────┐  │
│ │ NADRA    │   │ TPL Maps │   │ HERE     │   │JazzCash / │  │
│ │ Verisys  │   │ API      │   │ SDK      │   │Easypaisa  │  │
│ └──────────┘   └──────────┘   └──────────┘   └───────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Architecture rationale:** Supabase provides PostgreSQL with PostGIS for geospatial queries (critical for driver proximity matching) and TimescaleDB for time-series GPS trail data. Row Level Security (RLS) maps naturally to role-based access (driver vs. owner vs. admin), which is cleaner than Firebase's NoSQL model for relational logistics data.

---

## 3. Tech Stack (Final Decisions)

| Layer | Technology | Rationale |
|---|---|---|
| **Mobile App** | Flutter (Dart) | Single codebase iOS + Android + Web |
| **State Management** | Riverpod (with code generation) | Compile-safe, testable, no BuildContext dependency |
| **Navigation** | go_router | Declarative, deep-link ready for load-sharing |
| **Backend** | Supabase | Postgres + PostGIS + Realtime + Auth + Storage in one platform |
| **Auth** | Supabase Auth (Phone OTP + Email) | Pakistani users prefer phone-based login |
| **CNIC Verification** | `nadra_verisys_flutter` package | Direct NADRA Verisys API integration |
| **Real-time Chat** | Supabase Realtime (Postgres changes) | Built-in WebSocket, no extra infra |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Works with Supabase via Edge Function trigger |
| **Maps & Routing** | HERE SDK for Flutter (Navigate Edition) | Truck routing with height/weight/width restrictions |
| **Offline Maps** | HERE SDK Offline Routing | Critical for Balochistan/Sindh highways with poor connectivity |
| **Traffic Data (PK)** | TPL Maps Direction API | Pakistan-specific, PKR-denominated, local coverage |
| **Route Intelligence** | HERE SDK + TPL Maps + crowd-sourced reports | Hybrid: HERE for bridge/weight data, TPL for local conditions |
| **Payments** | JazzCash / Easypaisa via Edge Functions | Standard for Pakistani logistics |
| **IDE** | Google Antigravity | Multi-agent Flutter development with Dart/Flutter MCP server |

---

## 4. Detailed Feature Specifications

### 4.1 Driver Side (Job Seeker)

**Profile Module:**
- Name, Photo (captured via camera, stored in Supabase Storage)
- CNIC number + verification via NADRA Verisys API
- License Type: LTV / HTV / HTV+ (multi-select)
- Experience years + Vehicle Types: 10-Wheeler, 22-Wheeler, Container, Tanker, Mazda, Flatbed, Dumper
- Live Location: auto-updated every 3 minutes via `flutter_background_service` with a persistent GPS heartbeat
- Rating (1–5 stars) + Review text from owners

**CNIC Verification Flow:**
```
Driver submits CNIC + name + DOB
↓
Edge Function calls nadra_verisys_flutter client
↓
NADRA returns verified citizen data (name, father name, DOB match)
↓
If verified → profile badge "NADRA Verified" appears
↓
Store verification_transaction_id for audit trail
```

**Driver Availability States:**
- 🟢 Online & Available (shows in nearby search)
- 🟡 On Trip (visible but marked busy)
- 🔴 Offline (hidden)
- 🟠 Available with restrictions (e.g., "Only 22-wheeler")

### 4.2 Owner / Company Side (Job Provider)

**Load Posting Module:**
- Origin city (autocomplete from TPL Maps geocoding)
- Destination city
- Vehicle type required
- Weight (tons) + Dimensions (length × width × height in feet)
- Goods type (general, fragile, hazardous, refrigerated)
- Offered rate (PKR) + Rate type (fixed, per ton, negotiable)
- Pickup date/time window

**Driver Discovery:**
- System queries PostGIS: `ST_DWithin(driver_location, load_origin, radius)` + vehicle_type match + availability = online
- Sorted by: proximity → rating → completion rate
- Owner can "Invite to Apply" or "Direct Hire" (premium feature)

**Communication:**
- In-app chat via Supabase Realtime
- Voice call via `flutter_phone_direct_caller` (intent-based, no VoIP)
- Share load details as image/PDF

### 4.3 Route & City Intelligence (USP) — Deep Specification

This is the core differentiator. Three sub-systems:

#### A. City Timing System (Curfew & Traffic Windows)

**Data sources:**
- TPL Maps Traffic API (real-time congestion in Karachi, Lahore, Islamabad)
- Crowd-sourced reports from drivers: "Karachi entry closed at 6 AM, opens 11 PM"
- Historical pattern database (TimescaleDB): learned from 8+ months of traffic samples

**Algorithm:**
```
1. Driver enters route: Lahore → Karachi
2. System checks destination city (Karachi) traffic window
3. Query city_timing_rules table for Karachi:
- Heavy vehicle entry allowed: 11 PM – 5 AM
- Currently: 8 PM → WAIT 3 HOURS
4. Alternative: suggest parking at Karachi Bypass + notify when window opens
5. Push notification at 10:45 PM: "Entry window opens in 15 minutes"
```

**Data model:**
```sql
CREATE TABLE city_timing_rules (
id UUID PRIMARY KEY,
city_name TEXT NOT NULL,
vehicle_type TEXT, -- 'heavy', 'container', 'all'
entry_allowed_from TIME,
entry_allowed_until TIME,
affected_roads TEXT[], -- specific road names if known
source TEXT, -- 'government', 'crowd', 'historical'
confidence FLOAT DEFAULT 0.5,
last_verified_at TIMESTAMPTZ
);
```

#### B. Road Condition Alert

**Data sources:**
- Driver reports (crowd-sourced): photo + GPS + condition tag
- HERE SDK traffic events (accidents, roadworks, closures)
- `fleet_hazard` package for pure Dart aggregation with pluggable providers

**Condition categories:**
| Tag | Icon | Severity | Auto-expiry |
|---|---|---|---|
| Kacha Road (unpaved) | 🟤 | Medium | 30 days |
| Broken/Terrible Road | 🔴 | High | 7 days |
| Flooded | 🔵 | High | 24 hours |
| Landslide Risk | 🟠 | Critical | 48 hours |
| Protest/Sit-in | 🟣 | High | 12 hours |
| Accident | 🚗 | High | 6 hours |

**Report flow:**
```
Driver taps "Report Road Condition"
→ Select category
→ Optional photo (camera intent)
→ Auto-capture GPS
→ Submit to Supabase
→ Edge Function validates + deduplicates (within 500m, 2-hour window)
→ Realtime broadcast to drivers within 20km radius
→ Aggregation: if 3+ reports same location, confidence → 0.9, show prominently
```

#### C. Bridge Height Alert (Critical for Pakistan)

**Data source:** HERE SDK Truck Routing with `TruckOptions` — provides bridge clearance data and weight restrictions.

**Pre-trip validation:**
```
Owner posts load: "Lahore → Karachi, 40ft Container, 15ft height, 30 ton"
→ System calls HERE Routing API with truck profile:
{ height: 15ft, width: 8ft, length: 40ft, weight: 30ton, axles: 5 }
→ HERE returns route + list of restrictions on corridor
→ If any bridge < 15ft on route → ALERT before driver starts
→ Suggest alternative route avoiding the bridge
```

**In-trip alert:**
- HERE SDK navigation provides turn-by-turn with restriction warnings
- Flutter overlay: red banner "⚠️ Bridge ahead 14ft — your truck 15ft — REROUTING"
- Audio alert via `flutter_tts`: "Warning: low bridge ahead. Rerouting."

**Truck Profile Model:**
```dart
class TruckProfile {
final double heightCm; // e.g., 457 (15ft)
final double widthCm; // e.g., 244 (8ft)
final double lengthCm; // e.g., 1219 (40ft)
final double grossWeightKg; // e.g., 30000
final int axleCount;
final FuelType fuelType;
final List<String> hazmatClasses; // for hazardous loads
}
```

---

## 5. Data Models (PostgreSQL / Supabase)

### 5.1 Core Tables

```sql
-- USERS (extends Supabase auth.users)
CREATE TABLE profiles (
id UUID REFERENCES auth.users PRIMARY KEY,
role TEXT CHECK (role IN ('driver', 'owner', 'admin')),
full_name TEXT NOT NULL,
phone TEXT UNIQUE NOT NULL,
cnic_number TEXT UNIQUE,
cnic_verified BOOLEAN DEFAULT FALSE,
nadra_transaction_id TEXT,
photo_url TEXT,
rating FLOAT DEFAULT 0,
total_ratings INT DEFAULT 0,
created_at TIMESTAMPTZ DEFAULT NOW()
);

-- DRIVER-SPECIFIC
CREATE TABLE driver_profiles (
profile_id UUID REFERENCES profiles PRIMARY KEY,
license_type TEXT[] NOT NULL, -- {'LTV','HTV'}
experience_years INT,
vehicle_types TEXT[], -- {'10_wheeler','22_wheeler','container','tanker','mazda'}
current_location GEOGRAPHY(POINT),
location_updated_at TIMESTAMPTZ,
is_available BOOLEAN DEFAULT TRUE,
current_trip_id UUID,
max_weight_tons FLOAT,
hazmat_certified BOOLEAN DEFAULT FALSE
);

-- OWNER-SPECIFIC
CREATE TABLE owner_profiles (
profile_id UUID REFERENCES profiles PRIMARY KEY,
company_name TEXT,
ntn_number TEXT, -- National Tax Number
fleet_size INT,
verified_business BOOLEAN DEFAULT FALSE
);

-- LOADS
CREATE TABLE loads (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
owner_id UUID REFERENCES profiles NOT NULL,
origin_city TEXT NOT NULL,
origin_location GEOGRAPHY(POINT) NOT NULL,
destination_city TEXT NOT NULL,
destination_location GEOGRAPHY(POINT) NOT NULL,
vehicle_type_required TEXT NOT NULL,
weight_tons FLOAT NOT NULL,
length_ft FLOAT,
width_ft FLOAT,
height_ft FLOAT,
goods_type TEXT,
offered_rate_pkr FLOAT,
rate_type CHECK (rate_type IN ('fixed','per_ton','negotiable')),
pickup_window_start TIMESTAMPTZ,
pickup_window_end TIMESTAMPTZ,
status TEXT DEFAULT 'open', -- open, assigned, in_transit, delivered, cancelled
created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TRIPS (active assignments)
CREATE TABLE trips (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
load_id UUID REFERENCES loads NOT NULL,
driver_id UUID REFERENCES profiles NOT NULL,
owner_id UUID REFERENCES profiles NOT NULL,
status TEXT DEFAULT 'started',
started_at TIMESTAMPTZ DEFAULT NOW(),
completed_at TIMESTAMPTZ,
current_location GEOGRAPHY(POINT),
route_geojson JSONB, -- cached HERE route
driver_rating_by_owner FLOAT,
owner_rating_by_driver FLOAT
);

-- GPS TRAIL (TimescaleDB hypertable)
CREATE TABLE gps_trails (
trip_id UUID REFERENCES trips NOT NULL,
recorded_at TIMESTAMPTZ NOT NULL,
location GEOGRAPHY(POINT) NOT NULL,
speed_kmh FLOAT,
heading FLOAT
);
SELECT create_hypertable('gps_trails', 'recorded_at');

-- ROAD CONDITION REPORTS
CREATE TABLE road_reports (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
reporter_id UUID REFERENCES profiles NOT NULL,
report_type TEXT NOT NULL, -- 'kacha','broken','flooded','landslide','protest','accident'
location GEOGRAPHY(POINT) NOT NULL,
description TEXT,
photo_url TEXT,
confidence FLOAT DEFAULT 0.3,
upvotes INT DEFAULT 0,
downvotes INT DEFAULT 0,
expires_at TIMESTAMPTZ,
created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CITY TIMING RULES
CREATE TABLE city_timing_rules (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
city_name TEXT NOT NULL,
vehicle_category TEXT, -- 'heavy','container','all'
entry_from TIME,
entry_until TIME,
notes TEXT,
source TEXT,
confidence FLOAT DEFAULT 0.5,
updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RATINGS
CREATE TABLE ratings (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
trip_id UUID REFERENCES trips NOT NULL,
rater_id UUID REFERENCES profiles NOT NULL,
ratee_id UUID REFERENCES profiles NOT NULL,
score INT CHECK (score BETWEEN 1 AND 5),
review_text TEXT,
created_at TIMESTAMPTZ DEFAULT NOW(),
UNIQUE(trip_id, rater_id)
);
```

### 5.2 PostGIS Indexes

```sql
CREATE INDEX idx_driver_location ON driver_profiles USING GIST(current_location);
CREATE INDEX idx_load_origin ON loads USING GIST(origin_location);
CREATE INDEX idx_road_reports_location ON road_reports USING GIST(location);
CREATE INDEX idx_gps_trails_location ON gps_trails USING GIST(location);
```

### 5.3 Proximity Query (Driver Discovery)

```sql
-- Find available drivers within 50km of load origin
SELECT p.id, p.full_name, p.rating, dp.vehicle_types,
ST_Distance(dp.current_location, l.origin_location) AS distance_m
FROM driver_profiles dp
JOIN profiles p ON p.id = dp.profile_id
CROSS JOIN loads l
WHERE l.id = $1
AND dp.is_available = TRUE
AND ST_DWithin(dp.current_location, l.origin_location, 50000)
AND l.vehicle_type_required = ANY(dp.vehicle_types)
ORDER BY distance_m ASC, p.rating DESC
LIMIT 20;
```

---

## 6. API Design (Supabase Edge Functions)

| Endpoint | Method | Purpose |
|---|---|---|
| `/functions/v1/verify-cnic` | POST | Call NADRA Verisys, return verification result |
| `/functions/v1/find-drivers` | POST | PostGIS proximity query + filter by vehicle/availability |
| `/functions/v1/calculate-route` | POST | HERE SDK truck routing + bridge/weight restriction check |
| `/functions/v1/report-road-condition` | POST | Validate + deduplicate + insert road report |
| `/functions/v1/check-city-timing` | GET | Return entry window for destination city |
| `/functions/v1/trip-voice-brief` | POST | Generate Urdu voice summary of load details |
| `/functions/v1/process-payment` | POST | JazzCash/Easypaisa integration |

---

## 7. Flutter Project Structure (Feature-First)

```
lib/
├── main.dart
├── app.dart
├── core/
│ ├── config/
│ │ ├── supabase_config.dart
│ │ ├── here_config.dart
│ │ └── tpl_config.dart
│ ├── constants/
│ │ ├── vehicle_types.dart
│ │ ├── load_statuses.dart
│ │ └── report_categories.dart
│ ├── theme/
│ │ ├── app_theme.dart # Material 3, Urdu font (Noto Nastaliq)
│ │ └── colors.dart
│ ├── router/
│ │ └── app_router.dart # go_router with auth guards
│ ├── utils/
│ │ ├── validators.dart # CNIC, phone, plate number
│ │ ├── formatters.dart # PKR, weight, distance
│ │ └── urdu_text.dart # Urdu transliteration helpers
│ └── widgets/ # Shared widgets
│ ├── verified_badge.dart
│ ├── rating_stars.dart
│ └── truck_icon.dart
├── features/
│ ├── auth/
│ ├── driver_profile/
│ ├── loads/
│ ├── route_intelligence/ # ⭐ USP MODULE
│ ├── trip/
│ ├── chat/
│ └── ratings/
├── services/
└── l10n/ # English + Urdu
```
