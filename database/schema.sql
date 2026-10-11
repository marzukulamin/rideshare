CREATE DATABASE IF NOT EXISTS rideshare CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE rideshare;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(140) NOT NULL,
  phone VARCHAR(24) NOT NULL UNIQUE,
  email VARCHAR(190) NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  avatar_url VARCHAR(500) NULL,
  status ENUM('active','review','suspended','deleted') NOT NULL DEFAULT 'active',
  locale VARCHAR(12) NOT NULL DEFAULT 'en-BD',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS roles (
  id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_key VARCHAR(30) NOT NULL UNIQUE,
  label VARCHAR(80) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_roles (
  user_id BIGINT UNSIGNED NOT NULL,
  role_id SMALLINT UNSIGNED NOT NULL,
  granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS app_settings (
  setting_key VARCHAR(80) PRIMARY KEY,
  setting_value JSON NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS service_zones (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  zone_key VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(120) NOT NULL,
  city VARCHAR(120) NOT NULL,
  country_code CHAR(2) NOT NULL DEFAULT 'BD',
  center_lat DECIMAL(10,7) NOT NULL,
  center_lng DECIMAL(10,7) NOT NULL,
  radius_km DECIMAL(8,2) NOT NULL DEFAULT 35,
  active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ride_products (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_key VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(240) NOT NULL,
  icon_key VARCHAR(40) NOT NULL,
  passenger_capacity TINYINT UNSIGNED NOT NULL DEFAULT 1,
  sort_order SMALLINT NOT NULL DEFAULT 0,
  active TINYINT(1) NOT NULL DEFAULT 1,
  service_type ENUM('ride','delivery','rental') NOT NULL DEFAULT 'ride',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pricing_rules (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'BDT',
  rate_per_km DECIMAL(10,2) NOT NULL DEFAULT 100.00,
  minimum_fare DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  road_distance_multiplier DECIMAL(6,3) NOT NULL DEFAULT 1.250,
  effective_from DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  effective_to DATETIME NULL,
  updated_by BIGINT UNSIGNED NULL,
  CONSTRAINT fk_pricing_product FOREIGN KEY (product_id) REFERENCES ride_products(id),
  CONSTRAINT fk_pricing_admin FOREIGN KEY (updated_by) REFERENCES users(id),
  INDEX ix_pricing_effective (product_id, effective_from, effective_to)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS places (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  place_key VARCHAR(80) NOT NULL UNIQUE,
  label VARCHAR(160) NOT NULL,
  address VARCHAR(240) NOT NULL,
  city VARCHAR(120) NOT NULL,
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  category VARCHAR(40) NOT NULL DEFAULT 'place',
  active TINYINT(1) NOT NULL DEFAULT 1,
  FULLTEXT KEY ft_place_search (label, address, city)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS saved_places (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(80) NOT NULL,
  address VARCHAR(240) NOT NULL,
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_saved_places_user FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX ix_saved_places_user (user_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rider_preferences (
  user_id BIGINT UNSIGNED PRIMARY KEY,
  preferences JSON NOT NULL,
  safety_preferences JSON NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_preferences_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_methods (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  method_key VARCHAR(40) NOT NULL UNIQUE,
  label VARCHAR(80) NOT NULL,
  icon_key VARCHAR(40) NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  requires_provider TINYINT(1) NOT NULL DEFAULT 0,
  provider_ready TINYINT(1) NOT NULL DEFAULT 0,
  sort_order SMALLINT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_payment_methods (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  payment_method_id BIGINT UNSIGNED NOT NULL,
  provider_reference VARCHAR(190) NULL,
  display_suffix VARCHAR(16) NULL,
  preferred TINYINT(1) NOT NULL DEFAULT 0,
  status ENUM('active','pending','unavailable','removed') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_payments_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_user_payments_method FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id),
  INDEX ix_user_payments (user_id, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trip_profiles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  profile_key VARCHAR(40) NOT NULL,
  label VARCHAR(80) NOT NULL,
  payment_method_key VARCHAR(40) NOT NULL DEFAULT 'cash',
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_trip_profile_user FOREIGN KEY (user_id) REFERENCES users(id),
  UNIQUE KEY uq_user_trip_profile (user_id, profile_key)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS driver_profiles (
  user_id BIGINT UNSIGNED PRIMARY KEY,
  approval_status ENUM('pending','approved','rejected','suspended') NOT NULL DEFAULT 'pending',
  online_status ENUM('offline','online','on_trip') NOT NULL DEFAULT 'offline',
  vehicle_label VARCHAR(120) NULL,
  vehicle_plate VARCHAR(40) NULL,
  rating DECIMAL(3,2) NOT NULL DEFAULT 5.00,
  current_lat DECIMAL(10,7) NULL,
  current_lng DECIMAL(10,7) NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_driver_user FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX ix_driver_availability (approval_status, online_status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS quotes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  origin_label VARCHAR(180) NOT NULL,
  origin_address VARCHAR(240) NOT NULL,
  origin_lat DECIMAL(10,7) NOT NULL,
  origin_lng DECIMAL(10,7) NOT NULL,
  destination_label VARCHAR(180) NOT NULL,
  destination_address VARCHAR(240) NOT NULL,
  destination_lat DECIMAL(10,7) NOT NULL,
  destination_lng DECIMAL(10,7) NOT NULL,
  distance_km DECIMAL(9,3) NOT NULL,
  route_source VARCHAR(30) NOT NULL,
  rate_per_km DECIMAL(10,2) NOT NULL,
  fare_amount DECIMAL(10,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'BDT',
  pricing_rule_id BIGINT UNSIGNED NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_quote_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_quote_product FOREIGN KEY (product_id) REFERENCES ride_products(id),
  CONSTRAINT fk_quote_rule FOREIGN KEY (pricing_rule_id) REFERENCES pricing_rules(id),
  INDEX ix_quotes_user (user_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trips (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  public_id CHAR(12) NOT NULL UNIQUE,
  rider_id BIGINT UNSIGNED NOT NULL,
  driver_id BIGINT UNSIGNED NULL,
  quote_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  status ENUM('requested','matching','assigned','driver_arriving','arrived','in_progress','completed','cancelled','no_driver') NOT NULL DEFAULT 'requested',
  payment_method_key VARCHAR(40) NOT NULL,
  fare_amount DECIMAL(10,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'BDT',
  rider_note VARCHAR(240) NULL,
  scheduled_for DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  CONSTRAINT fk_trip_rider FOREIGN KEY (rider_id) REFERENCES users(id),
  CONSTRAINT fk_trip_driver FOREIGN KEY (driver_id) REFERENCES users(id),
  CONSTRAINT fk_trip_quote FOREIGN KEY (quote_id) REFERENCES quotes(id),
  CONSTRAINT fk_trip_product FOREIGN KEY (product_id) REFERENCES ride_products(id),
  INDEX ix_trips_rider (rider_id, created_at),
  INDEX ix_trips_driver_status (driver_id, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trip_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  trip_id BIGINT UNSIGNED NOT NULL,
  actor_user_id BIGINT UNSIGNED NULL,
  event_key VARCHAR(50) NOT NULL,
  details JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_trip_event_trip FOREIGN KEY (trip_id) REFERENCES trips(id),
  CONSTRAINT fk_trip_event_actor FOREIGN KEY (actor_user_id) REFERENCES users(id),
  INDEX ix_trip_events (trip_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS promotions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  promo_key VARCHAR(50) NOT NULL UNIQUE,
  title VARCHAR(120) NOT NULL,
  subtitle VARCHAR(240) NOT NULL,
  badge VARCHAR(40) NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  starts_at DATETIME NULL,
  ends_at DATETIME NULL,
  sort_order SMALLINT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS home_cards (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  card_key VARCHAR(60) NOT NULL UNIQUE,
  title VARCHAR(140) NOT NULL,
  subtitle VARCHAR(240) NOT NULL,
  image_key VARCHAR(80) NOT NULL,
  action_key VARCHAR(40) NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  sort_order SMALLINT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS support_topics (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  topic_key VARCHAR(60) NOT NULL UNIQUE,
  title VARCHAR(120) NOT NULL,
  category VARCHAR(60) NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  sort_order SMALLINT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS support_cases (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  public_id CHAR(12) NOT NULL UNIQUE,
  user_id BIGINT UNSIGNED NOT NULL,
  trip_id BIGINT UNSIGNED NULL,
  topic_id BIGINT UNSIGNED NOT NULL,
  status ENUM('open','in_progress','waiting_for_user','resolved','closed') NOT NULL DEFAULT 'open',
  priority ENUM('normal','urgent') NOT NULL DEFAULT 'normal',
  subject VARCHAR(180) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_case_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_case_trip FOREIGN KEY (trip_id) REFERENCES trips(id),
  CONSTRAINT fk_case_topic FOREIGN KEY (topic_id) REFERENCES support_topics(id),
  INDEX ix_support_queue (status, priority, updated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS support_messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  case_id BIGINT UNSIGNED NOT NULL,
  sender_user_id BIGINT UNSIGNED NULL,
  sender_type ENUM('rider','driver','staff','system') NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_message_case FOREIGN KEY (case_id) REFERENCES support_cases(id),
  CONSTRAINT fk_message_sender FOREIGN KEY (sender_user_id) REFERENCES users(id),
  INDEX ix_case_messages (case_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS admin_audit (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_user_id BIGINT UNSIGNED NOT NULL,
  action_key VARCHAR(80) NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id VARCHAR(80) NOT NULL,
  reason VARCHAR(240) NOT NULL,
  before_data JSON NULL,
  after_data JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES users(id),
  INDEX ix_audit_entity (entity_type, entity_id, created_at)
) ENGINE=InnoDB;

INSERT IGNORE INTO roles (role_key, label) VALUES
('rider','Rider'),('driver','Driver'),('admin','Administrator'),('support','Support agent');

INSERT IGNORE INTO service_zones (zone_key,name,city,country_code,center_lat,center_lng,radius_km,active) VALUES
('dhaka-central','Dhaka Central','Dhaka','BD',23.7806,90.4070,38,1);

INSERT IGNORE INTO ride_products (product_key,name,description,icon_key,passenger_capacity,sort_order,active,service_type) VALUES
('bike','Bike','Quick rides through the city','bike',1,10,1,'ride'),
('bike-saver','Bike Saver','Lower-cost bike rides','bike',1,20,1,'ride'),
('car','Car','Comfortable everyday rides','car',4,30,1,'ride'),
('cng','CNG','Three-wheeler rides around town','cng',3,40,1,'ride'),
('xl','XL','Room for more people','car',6,50,1,'ride'),
('premier','Premier','Premium sedan rides','car',4,60,1,'ride'),
('priority','Priority','Faster pickup when available','bolt',4,70,1,'ride'),
('parcel-bike','Parcel Bike','Send a small package','parcel',1,80,0,'delivery');

INSERT INTO pricing_rules (product_id,currency,rate_per_km,minimum_fare,road_distance_multiplier,effective_from)
SELECT id,'BDT',100.00,0.00,1.250,CURRENT_TIMESTAMP FROM ride_products WHERE service_type='ride'
AND NOT EXISTS (SELECT 1 FROM pricing_rules p WHERE p.product_id=ride_products.id AND p.effective_to IS NULL);

INSERT IGNORE INTO places (place_key,label,address,city,lat,lng,category,active) VALUES
('dhaka','Dhaka','Dhaka, Bangladesh','Dhaka',23.8103,90.4125,'city',1),
('malibagh','Malibagh','Malibagh, Dhaka','Dhaka',23.7516,90.4145,'neighborhood',1),
('gulshan-1','Gulshan 1','Gulshan 1, Dhaka','Dhaka',23.7808,90.4168,'neighborhood',1),
('gulshan-2','Gulshan 2','Gulshan 2, Dhaka','Dhaka',23.7937,90.4142,'neighborhood',1),
('banani','Banani','Banani, Dhaka','Dhaka',23.7936,90.4066,'neighborhood',1),
('dhanmondi','Dhanmondi','Dhanmondi, Dhaka','Dhaka',23.7461,90.3742,'neighborhood',1),
('motijheel','Motijheel','Motijheel, Dhaka','Dhaka',23.7330,90.4172,'neighborhood',1),
('uttara','Uttara','Uttara, Dhaka','Dhaka',23.8759,90.3795,'neighborhood',1),
('airport','Hazrat Shahjalal International Airport','Airport Road, Dhaka','Dhaka',23.8433,90.3978,'landmark',1),
('bashundhara','Bashundhara R/A','Bashundhara Residential Area, Dhaka','Dhaka',23.8151,90.4255,'neighborhood',1),
('rajshahi','Rajshahi','Rajshahi, Bangladesh','Rajshahi',24.3745,88.6042,'city',1),
('chattogram','Chattogram','Chattogram, Bangladesh','Chattogram',22.3569,91.7832,'city',1),
('sylhet','Sylhet','Sylhet, Bangladesh','Sylhet',24.8949,91.8687,'city',1),
('cox-bazar','Cox’s Bazar','Cox’s Bazar, Bangladesh','Cox’s Bazar',21.4272,92.0058,'city',1),
('khulna','Khulna','Khulna, Bangladesh','Khulna',22.8456,89.5403,'city',1);

INSERT IGNORE INTO payment_methods (method_key,label,icon_key,active,requires_provider,provider_ready,sort_order) VALUES
('cash','Cash','cash',1,0,1,10),
('bkash','bKash','bkash',1,1,0,20),
('wallet','RideShare Wallet','wallet',0,0,1,30);

INSERT IGNORE INTO promotions (promo_key,title,subtitle,badge,active,sort_order) VALUES
('welcome','First ride, made simple','A welcome offer configured for your account','WELCOME',1,10),
('weekend','Weekend rides','Local offers appear here when available','BDT 100/km',1,20);

INSERT IGNORE INTO home_cards (card_key,title,subtitle,image_key,action_key,active,sort_order) VALUES
('dhaka-city','Move around Dhaka','Choose a destination and compare your ride options','city','book',1,10),
('bangladesh','Explore Bangladesh','See destinations from Rajshahi to Cox’s Bazar','bangladesh','map',1,20);

INSERT IGNORE INTO support_topics (topic_key,title,category,active,sort_order) VALUES
('fare','Fare or payment issue','Payments',1,10),
('driver','Driver or vehicle feedback','Trip',1,20),
('safety','Safety concern','Safety',1,30),
('lost-item','Lost item','Trip',1,40),
('account','Account access','Account',1,50),
('map','Map or pickup issue','Trip',1,60),
('other','Something else','General',1,70);

INSERT IGNORE INTO app_settings (setting_key,setting_value) VALUES
('market',JSON_OBJECT('country_code','BD','currency','BDT','city','Dhaka','locale','en-BD')),
('fare_policy',JSON_OBJECT('rounding','nearest_taka','quote_expiry_minutes',5,'hidden_fees',false)),
('map',JSON_OBJECT('center_lat',23.8103,'center_lng',90.4125,'default_zoom',12,'country_zoom',7,'provider','OpenStreetMap')),
('services',JSON_OBJECT('rides',true,'parcel',false,'scheduling',false,'cash',true,'bkash_enabled',false));
