-- 001_initial.sql
-- TruckLink PK Initial Schema with PostGIS, TimescaleDB, and Row Level Security (RLS)

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;
-- TimescaleDB (if enabled in Supabase project)
DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'TimescaleDB extension not available or not permitted, continuing with standard PostgreSQL table';
END $$;

-- 2. ENUMS & CORE TABLES

-- PROFILES (Extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
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

-- DRIVER PROFILES
CREATE TABLE IF NOT EXISTS driver_profiles (
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
  license_type TEXT[] NOT NULL DEFAULT '{}', -- {'LTV','HTV','HTV+'}
  experience_years INT DEFAULT 0,
  vehicle_types TEXT[] NOT NULL DEFAULT '{}', -- {'10_wheeler','22_wheeler','container','tanker','mazda','flatbed','dumper'}
  current_location GEOGRAPHY(POINT, 4326),
  location_updated_at TIMESTAMPTZ,
  is_available BOOLEAN DEFAULT TRUE,
  current_trip_id UUID,
  max_weight_tons FLOAT,
  hazmat_certified BOOLEAN DEFAULT FALSE
);

-- OWNER PROFILES
CREATE TABLE IF NOT EXISTS owner_profiles (
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
  company_name TEXT,
  ntn_number TEXT,
  fleet_size INT DEFAULT 1,
  verified_business BOOLEAN DEFAULT FALSE
);

-- LOADS
CREATE TABLE IF NOT EXISTS loads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  origin_city TEXT NOT NULL,
  origin_location GEOGRAPHY(POINT, 4326) NOT NULL,
  destination_city TEXT NOT NULL,
  destination_location GEOGRAPHY(POINT, 4326) NOT NULL,
  vehicle_type_required TEXT NOT NULL,
  weight_tons FLOAT NOT NULL,
  length_ft FLOAT,
  width_ft FLOAT,
  height_ft FLOAT,
  goods_type TEXT,
  offered_rate_pkr FLOAT,
  rate_type TEXT CHECK (rate_type IN ('fixed', 'per_ton', 'negotiable')) DEFAULT 'fixed',
  pickup_window_start TIMESTAMPTZ,
  pickup_window_end TIMESTAMPTZ,
  status TEXT CHECK (status IN ('open', 'assigned', 'in_transit', 'delivered', 'cancelled')) DEFAULT 'open',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TRIPS (active assignments)
CREATE TABLE IF NOT EXISTS trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  load_id UUID REFERENCES loads(id) ON DELETE RESTRICT NOT NULL,
  driver_id UUID REFERENCES profiles(id) ON DELETE RESTRICT NOT NULL,
  owner_id UUID REFERENCES profiles(id) ON DELETE RESTRICT NOT NULL,
  status TEXT CHECK (status IN ('assigned', 'started', 'in_transit', 'delivered', 'completed', 'cancelled')) DEFAULT 'started',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  current_location GEOGRAPHY(POINT, 4326),
  route_geojson JSONB,
  driver_rating_by_owner FLOAT,
  owner_rating_by_driver FLOAT
);

-- GPS TRAILS
CREATE TABLE IF NOT EXISTS gps_trails (
  trip_id UUID REFERENCES trips(id) ON DELETE CASCADE NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  speed_kmh FLOAT,
  heading FLOAT
);

-- Conditionally create hypertable if TimescaleDB is present
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'timescaledb') THEN
    PERFORM create_hypertable('gps_trails', 'recorded_at', if_not_exists => TRUE);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Could not create hypertable, standard index will be used';
END $$;

-- ROAD CONDITION REPORTS
CREATE TABLE IF NOT EXISTS road_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  report_type TEXT CHECK (report_type IN ('kacha', 'broken', 'flooded', 'landslide', 'protest', 'accident')) NOT NULL,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  description TEXT,
  photo_url TEXT,
  confidence FLOAT DEFAULT 0.3,
  upvotes INT DEFAULT 0,
  downvotes INT DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CITY TIMING RULES
CREATE TABLE IF NOT EXISTS city_timing_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_name TEXT NOT NULL,
  vehicle_category TEXT DEFAULT 'all', -- 'heavy', 'container', 'all'
  entry_from TIME,
  entry_until TIME,
  affected_roads TEXT[],
  notes TEXT,
  source TEXT DEFAULT 'historical', -- 'government', 'crowd', 'historical'
  confidence FLOAT DEFAULT 0.5,
  last_verified_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RATINGS
CREATE TABLE IF NOT EXISTS ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID REFERENCES trips(id) ON DELETE CASCADE NOT NULL,
  rater_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  ratee_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  score INT CHECK (score BETWEEN 1 AND 5) NOT NULL,
  review_text TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(trip_id, rater_id)
);

-- 3. POSTGIS & PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_driver_location ON driver_profiles USING GIST(current_location);
CREATE INDEX IF NOT EXISTS idx_load_origin ON loads USING GIST(origin_location);
CREATE INDEX IF NOT EXISTS idx_load_destination ON loads USING GIST(destination_location);
CREATE INDEX IF NOT EXISTS idx_road_reports_location ON road_reports USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_gps_trails_location ON gps_trails USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_gps_trails_trip_time ON gps_trails(trip_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_loads_status_created ON loads(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trips_driver ON trips(driver_id, status);
CREATE INDEX IF NOT EXISTS idx_trips_owner ON trips(owner_id, status);

-- 4. ROW LEVEL SECURITY (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE loads ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE gps_trails ENABLE ROW LEVEL SECURITY;
ALTER TABLE road_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE city_timing_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
CREATE POLICY "Public profiles can be viewed by authenticated users"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- DRIVER PROFILES POLICIES
CREATE POLICY "Driver profiles viewable by authenticated users"
  ON driver_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Drivers manage their own driver profile"
  ON driver_profiles FOR ALL
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- OWNER PROFILES POLICIES
CREATE POLICY "Owner profiles viewable by authenticated users"
  ON owner_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Owners manage their own owner profile"
  ON owner_profiles FOR ALL
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- LOADS POLICIES
CREATE POLICY "Anyone authenticated can view open loads"
  ON loads FOR SELECT
  TO authenticated
  USING (status = 'open' OR owner_id = auth.uid());

CREATE POLICY "Owners can create loads"
  ON loads FOR INSERT
  TO authenticated
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Owners can update their own loads"
  ON loads FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid());

-- TRIPS POLICIES
CREATE POLICY "Trip participants can view trips"
  ON trips FOR SELECT
  TO authenticated
  USING (driver_id = auth.uid() OR owner_id = auth.uid());

CREATE POLICY "Owners and drivers can update assigned trips"
  ON trips FOR UPDATE
  TO authenticated
  USING (driver_id = auth.uid() OR owner_id = auth.uid());

-- GPS TRAILS POLICIES
CREATE POLICY "Participants can view trip GPS trails"
  ON gps_trails FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM trips t
      WHERE t.id = gps_trails.trip_id
      AND (t.driver_id = auth.uid() OR t.owner_id = auth.uid())
    )
  );

CREATE POLICY "Drivers can insert GPS trails for active trip"
  ON gps_trails FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM trips t
      WHERE t.id = gps_trails.trip_id
      AND t.driver_id = auth.uid()
    )
  );

-- ROAD REPORTS POLICIES
CREATE POLICY "Road reports readable by all authenticated users"
  ON road_reports FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can submit road reports"
  ON road_reports FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "Reporters can update their reports"
  ON road_reports FOR UPDATE
  TO authenticated
  USING (reporter_id = auth.uid());

-- CITY TIMING RULES POLICIES
CREATE POLICY "City timing rules readable by all authenticated users"
  ON city_timing_rules FOR SELECT
  TO authenticated
  USING (true);

-- RATINGS POLICIES
CREATE POLICY "Ratings viewable by authenticated users"
  ON ratings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Trip participants can submit rating"
  ON ratings FOR INSERT
  TO authenticated
  WITH CHECK (rater_id = auth.uid());

-- 5. INITIAL SEED DATA FOR CITY TIMING RULES
INSERT INTO city_timing_rules (city_name, vehicle_category, entry_from, entry_until, notes, source, confidence)
VALUES
  ('Karachi', 'heavy', '23:00', '05:00', 'Heavy vehicle entry prohibited during daytime. Entry allowed 11:00 PM to 5:00 AM.', 'government', 0.9),
  ('Lahore', 'heavy', '22:00', '06:00', 'Lahore Ring Road and city arterial restriction. Night window 10:00 PM to 6:00 AM.', 'government', 0.85),
  ('Islamabad', 'heavy', '23:00', '06:00', 'Islamabad expressway heavy traffic restricted during peak hours.', 'government', 0.8),
  ('Rawalpindi', 'heavy', '22:00', '06:00', 'Faizabad and Murree Road heavy traffic restricted during day.', 'government', 0.8)
ON CONFLICT DO NOTHING;
