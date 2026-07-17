CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(120) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('administrator', 'operator')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS carts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cart_id VARCHAR(80) NOT NULL UNIQUE,
  cart_name VARCHAR(120) NOT NULL,
  description TEXT,
  serial_number VARCHAR(120),
  model VARCHAR(120),
  installation_date DATE,
  assigned_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS telemetry (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cart_id VARCHAR(80) NOT NULL REFERENCES carts(cart_id) ON DELETE CASCADE,
  power_status VARCHAR(30),
  motion_status VARCHAR(60),
  stop_reason VARCHAR(120),
  battery_voltage NUMERIC(8, 2),
  battery_percentage INTEGER,
  radio_connected BOOLEAN,
  internet_connected BOOLEAN,
  front_sensor_active BOOLEAN,
  front_distance_cm NUMERIC(8, 2),
  left_sensor_active BOOLEAN,
  left_distance_cm NUMERIC(8, 2),
  right_sensor_active BOOLEAN,
  right_distance_cm NUMERIC(8, 2),
  left_rssi INTEGER,
  right_rssi INTEGER,
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),
  location_available BOOLEAN NOT NULL DEFAULT FALSE,
  uptime_ms BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cart_id VARCHAR(80) NOT NULL REFERENCES carts(cart_id) ON DELETE CASCADE,
  alert_type VARCHAR(80) NOT NULL,
  message TEXT NOT NULL,
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_telemetry_cart_created ON telemetry(cart_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_cart_created ON alerts(cart_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_read ON alerts(is_read);
