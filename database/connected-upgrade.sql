CREATE TABLE IF NOT EXISTS rs_content (
 content_key VARCHAR(80) NOT NULL, locale VARCHAR(12) NOT NULL,
 title VARCHAR(160) NOT NULL, body TEXT NOT NULL, destination JSON NULL,
 active TINYINT NOT NULL DEFAULT 1, expires_at DATETIME NULL,
 version INT NOT NULL DEFAULT 1, author_id BIGINT UNSIGNED NOT NULL,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(content_key,locale)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_incidents (
 id VARCHAR(32) PRIMARY KEY, severity VARCHAR(12) NOT NULL,
 status VARCHAR(20) NOT NULL, owner_id BIGINT UNSIGNED NOT NULL,
 summary VARCHAR(240) NOT NULL, user_impact TEXT NOT NULL,
 runbook TEXT NOT NULL, mitigation TEXT NOT NULL, follow_up TEXT NOT NULL,
 version INT NOT NULL DEFAULT 1, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_releases (
 id VARCHAR(32) PRIMARY KEY, build_version VARCHAR(40) NOT NULL,
 status VARCHAR(20) NOT NULL, owner_id BIGINT UNSIGNED NOT NULL,
 cohort VARCHAR(80) NOT NULL, health_gates JSON NOT NULL,
 migration_compatible TINYINT NOT NULL, rollback_target VARCHAR(40) NOT NULL,
 evidence TEXT NOT NULL, version INT NOT NULL DEFAULT 1,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_legal_holds (
 id VARCHAR(32) PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 reason TEXT NOT NULL, legal_basis VARCHAR(240) NOT NULL,
 jurisdiction VARCHAR(80) NOT NULL, expires_at DATETIME NOT NULL,
 created_by BIGINT UNSIGNED NOT NULL, request_id VARCHAR(32) NOT NULL,
 released_at DATETIME NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 INDEX(user_id,expires_at)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_attachments (
 id VARCHAR(32) PRIMARY KEY, case_id VARCHAR(32) NOT NULL,
 owner_id BIGINT UNSIGNED NOT NULL, storage_key VARCHAR(32) NOT NULL,
 mime VARCHAR(80) NOT NULL, checksum VARCHAR(64) NOT NULL,
 scan_status VARCHAR(24) NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(case_id) REFERENCES rs_cases(id), INDEX(case_id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_config_versions (
 id VARCHAR(32) PRIMARY KEY, kind VARCHAR(32) NOT NULL, target_key VARCHAR(80) NOT NULL,
 payload JSON NOT NULL, before_json JSON NOT NULL, effective_at DATETIME NOT NULL,
 status VARCHAR(20) NOT NULL DEFAULT 'scheduled', actor_id BIGINT UNSIGNED NOT NULL,
 request_id VARCHAR(32) NOT NULL, applied_at DATETIME NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX(status,effective_at)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_trip_progress (
 trip_id VARCHAR(32) PRIMARY KEY, completed_stops INT NOT NULL DEFAULT 0,
 FOREIGN KEY(trip_id) REFERENCES rs_trips(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rs_fare_reviews (
 trip_id CHAR(32) PRIMARY KEY, request_id CHAR(32) NOT NULL UNIQUE, accepted_fare_minor INT NOT NULL,
 final_fare_minor INT NOT NULL, earning_minor INT NOT NULL, billable_distance_m INT NOT NULL,
 evidence VARCHAR(500) NOT NULL, actor_id BIGINT UNSIGNED NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(trip_id) REFERENCES rs_trips(id)
) ENGINE=InnoDB;

INSERT IGNORE INTO rs_content(content_key,locale,title,body,author_id) VALUES
('help.booking','en-BD','Booking and pickup','Confirm your pickup and destination before requesting. A driver accepts independently and starts the ride after checking your pickup PIN. Cancel before start without a fee.',0),
('help.cash','en-BD','Cash and fare review','Pay the fare shown on the receipt. A driver collection report awaits customer confirmation. You can dispute it in trip Help; staff review is independent and recorded.',0),
('help.safety','en-BD','Safety and urgent help','Open Safety for the device emergency dialer or a restricted report. A support case does not dispatch emergency responders. Do not type while driving.',0),
('help.booking','bn-BD','বুকিং ও যাত্রা শুরু','অনুরোধের আগে ওঠার স্থান ও গন্তব্য নিশ্চিত করুন। চালক নিজে অনুরোধ গ্রহণ করেন এবং পিকআপ পিন যাচাই করে যাত্রা শুরু করেন। যাত্রা শুরুর আগে বাতিলে ফি নেই।',0),
('help.cash','bn-BD','নগদ ও ভাড়া পর্যালোচনা','রসিদে দেখানো ভাড়া পরিশোধ করুন। চালকের নগদ গ্রহণের তথ্য গ্রাহক নিশ্চিত করেন। সমস্যা থাকলে যাত্রার সহায়তা থেকে পর্যালোচনা চান।',0),
('help.safety','bn-BD','নিরাপত্তা ও জরুরি সহায়তা','নিরাপত্তা থেকে জরুরি নম্বরে কলের ডায়ালার বা গোপন প্রতিবেদন খুলুন। সহায়তার আবেদন জরুরি কর্মী পাঠায় না। গাড়ি চালানোর সময় লিখবেন না।',0);

CREATE TABLE IF NOT EXISTS rs_lost_items (
 trip_id CHAR(32) PRIMARY KEY, case_id CHAR(32) NOT NULL, description VARCHAR(1000) NOT NULL,
 status VARCHAR(24) NOT NULL DEFAULT 'reported', customer_consent TINYINT NOT NULL DEFAULT 0,
 driver_consent TINYINT NOT NULL DEFAULT 0, driver_handoff TINYINT NOT NULL DEFAULT 0,
 customer_received TINYINT NOT NULL DEFAULT 0, version INT NOT NULL DEFAULT 1,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(trip_id) REFERENCES rs_trips(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rs_trip_reveals (
 session_id BIGINT UNSIGNED NOT NULL, trip_id CHAR(32) NOT NULL,
 actor_id BIGINT UNSIGNED NOT NULL, purpose VARCHAR(240) NOT NULL, expires_at DATETIME NOT NULL,
 PRIMARY KEY(session_id,trip_id), FOREIGN KEY(trip_id) REFERENCES rs_trips(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rs_execution_attempts (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, request_id CHAR(32) NOT NULL,
 actor_id BIGINT UNSIGNED NOT NULL, outcome VARCHAR(24) NOT NULL, evidence VARCHAR(500) NOT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(request_id) REFERENCES rs_requests(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rs_driver_shifts (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, driver_id BIGINT UNSIGNED NOT NULL,
 started_at DATETIME NOT NULL, ended_at DATETIME NULL, summary JSON NULL,
 FOREIGN KEY(driver_id) REFERENCES rs_users(id), INDEX(driver_id,started_at)
) ENGINE=InnoDB;

INSERT IGNORE INTO rs_settings(setting_key,value_json) VALUES ('feedback','{"rating_window_seconds":2592000,"tags":["clean_vehicle","smooth_trip","clear_pickup","respectful","route_feedback","communication_feedback"]}');

CREATE TABLE IF NOT EXISTS rs_job_state (
 job_key VARCHAR(80) PRIMARY KEY, summary JSON NOT NULL, ran_at DATETIME NOT NULL
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_job_events (
 event_key VARCHAR(160) PRIMARY KEY, created_at DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rs_case_reads (
 case_id CHAR(32) NOT NULL, reader_id BIGINT UNSIGNED NOT NULL, seen_message_id BIGINT UNSIGNED NOT NULL,
 seen_at DATETIME NOT NULL, PRIMARY KEY(case_id,reader_id), FOREIGN KEY(case_id) REFERENCES rs_cases(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_file_purges (
 storage_key CHAR(32) PRIMARY KEY, requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 removed_at DATETIME NULL, attempts INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_account_restrictions (
 request_id CHAR(32) PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 applied_version INT NOT NULL, prior_status VARCHAR(24) NOT NULL,
 policy_basis VARCHAR(1000) NOT NULL, appeal_until DATETIME NOT NULL, expires_at DATETIME NULL,
 status VARCHAR(24) NOT NULL DEFAULT 'active', resolved_at DATETIME NULL,
 FOREIGN KEY(request_id) REFERENCES rs_requests(id), FOREIGN KEY(user_id) REFERENCES rs_users(id),
 INDEX(status,expires_at)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS rs_settlement_controls (
 user_id BIGINT UNSIGNED PRIMARY KEY, held TINYINT NOT NULL DEFAULT 0,
 reason VARCHAR(500) NOT NULL, version INT NOT NULL DEFAULT 1, request_id CHAR(32) NOT NULL,
 FOREIGN KEY(user_id) REFERENCES rs_users(id), FOREIGN KEY(request_id) REFERENCES rs_requests(id)
) ENGINE=InnoDB;
INSERT IGNORE INTO rs_content(content_key,locale,title,body,author_id) VALUES
 ('template.acknowledge','en-BD','Acknowledge review','Thank you for your message. We are reviewing the details of this case and will respond here.',0),
 ('template.more_detail','en-BD','Ask for relevant details','Please describe what happened and the outcome you are requesting. Share only information necessary for this case; do not send passwords or pickup PINs.',0),
 ('template.acknowledge','bn-BD','পর্যালোচনার বার্তা','আপনার বার্তার জন্য ধন্যবাদ। আমরা এই আবেদনের তথ্য পর্যালোচনা করছি এবং এখানেই উত্তর দেব।',0),
 ('template.more_detail','bn-BD','প্রাসঙ্গিক তথ্য চান','কী ঘটেছে এবং আপনি কী সমাধান চান তা জানান। শুধু এই আবেদনের প্রয়োজনীয় তথ্য দিন; পাসওয়ার্ড বা পিকআপ পিন পাঠাবেন না।',0);
