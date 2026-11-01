-- MiniKalp API — MySQL 8 şeması
-- Kurulum: mysql -u root -p < database/schema.sql

CREATE DATABASE IF NOT EXISTS minikalp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE minikalp;

-- ---------------------------------------------------------------------------
-- Kullanıcılar ve oturum anahtarları
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS users (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(120) NOT NULL,
    email         VARCHAR(190) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Düz token asla saklanmaz; yalnızca SHA-256 özeti tutulur.
CREATE TABLE IF NOT EXISTS api_tokens (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id      INT UNSIGNED NOT NULL,
    token_hash   CHAR(64) NOT NULL UNIQUE,
    device_name  VARCHAR(120) NULL,
    last_used_at DATETIME NULL,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_settings (
    user_id       INT UNSIGNED PRIMARY KEY,
    notifications TINYINT(1) NOT NULL DEFAULT 1,
    volume_unit   ENUM('ml','oz') NOT NULL DEFAULT 'ml',
    weight_unit   ENUM('kg','lb') NOT NULL DEFAULT 'kg',
    language      ENUM('tr','en') NOT NULL DEFAULT 'tr',
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS mood_entries (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNSIGNED NOT NULL,
    score       TINYINT UNSIGNED NOT NULL,
    note        TEXT NULL,
    recorded_at DATETIME NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_mood_user (user_id, recorded_at),
    CONSTRAINT fk_mood_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Bebekler ve bebeğe bağlı veriler
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS babies (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id           INT UNSIGNED NOT NULL,
    name              VARCHAR(120) NOT NULL,
    birth_date        DATE NOT NULL,
    gender            ENUM('girl','boy','unspecified') NOT NULL DEFAULT 'unspecified',
    photo_path        VARCHAR(500) NULL,
    expressed_milk_ml INT NOT NULL DEFAULT 0,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_babies_user (user_id),
    CONSTRAINT fk_babies_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tüm takip kayıtları tek tabloda; türe göre ilgili sütunlar dolar.
CREATE TABLE IF NOT EXISTS records (
    id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    baby_id           INT UNSIGNED NOT NULL,
    type              ENUM('breastfeeding','formula','solid_food','stool','diaper','vomit','sleep','fever','medicine') NOT NULL,
    recorded_at       DATETIME NOT NULL,
    side              ENUM('left','right','both') NULL,
    duration_seconds  INT UNSIGNED NULL,
    milk_type         ENUM('breast_milk','formula') NULL,
    amount_ml         INT UNSIGNED NULL,
    food_name         VARCHAR(190) NULL,
    reaction          ENUM('none','rash','vomit','stool_change') NULL,
    stool_color       ENUM('yellow','green','brown','black','red','white_gray') NULL,
    stool_consistency ENUM('watery','soft','normal','hard','lumpy') NULL,
    diaper_kind       ENUM('wet','dirty','both') NULL,
    vomit_kind        ENUM('spit_up','forceful') NULL,
    vomit_amount      ENUM('low','medium','high') NULL,
    symptoms          JSON NULL,
    color_note        VARCHAR(255) NULL,
    day_night         ENUM('day','night') NULL,
    quality           TINYINT UNSIGNED NULL,
    temperature       DECIMAL(4,1) NULL,
    fever_method      VARCHAR(30) NULL,
    medicine_name     VARCHAR(190) NULL,
    note              TEXT NULL,
    photo_path        VARCHAR(500) NULL,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_records_baby_time (baby_id, recorded_at),
    INDEX idx_records_baby_type (baby_id, type),
    CONSTRAINT fk_records_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS growth_measurements (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    baby_id     INT UNSIGNED NOT NULL,
    weight_kg   DECIMAL(5,2) NULL,
    height_cm   DECIMAL(5,1) NULL,
    head_cm     DECIMAL(5,1) NULL,
    measured_at DATETIME NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_growth_baby (baby_id, measured_at),
    CONSTRAINT fk_growth_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS milestones (
    baby_id      INT UNSIGNED NOT NULL,
    milestone_key VARCHAR(100) NOT NULL,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (baby_id, milestone_key),
    CONSTRAINT fk_milestones_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- tooth_index: 0–19 (süt dişleri)
CREATE TABLE IF NOT EXISTS teeth (
    baby_id     INT UNSIGNED NOT NULL,
    tooth_index TINYINT UNSIGNED NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (baby_id, tooth_index),
    CONSTRAINT fk_teeth_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- "İlk"ler (ilk gülümseme, ilk adım…). Bebek oluşturulunca varsayılanlar eklenir.
CREATE TABLE IF NOT EXISTS memories (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    baby_id    INT UNSIGNED NOT NULL,
    title      VARCHAR(190) NOT NULL,
    photo_path VARCHAR(500) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_memories_baby (baby_id, sort_order),
    CONSTRAINT fk_memories_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS photos (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    baby_id    INT UNSIGNED NOT NULL,
    path       VARCHAR(500) NOT NULL,
    month      TINYINT UNSIGNED NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_photos_baby (baby_id, month),
    CONSTRAINT fk_photos_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS medicine_reminders (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    baby_id        INT UNSIGNED NOT NULL,
    name           VARCHAR(190) NOT NULL,
    schedule_label VARCHAR(100) NOT NULL DEFAULT 'Her gün',
    remind_at      VARCHAR(5) NULL,          -- "HH:MM"
    notify         TINYINT(1) NOT NULL DEFAULT 0,
    done           TINYINT(1) NOT NULL DEFAULT 0,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_reminders_baby (baby_id),
    CONSTRAINT fk_reminders_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS vaccines (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    baby_id    INT UNSIGNED NOT NULL,
    name       VARCHAR(190) NOT NULL,
    age_label  VARCHAR(100) NOT NULL DEFAULT '',
    status     ENUM('upcoming','done','late') NOT NULL DEFAULT 'upcoming',
    due_date   DATE NULL,
    notify     TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_vaccines_baby (baby_id, due_date),
    CONSTRAINT fk_vaccines_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS appointments (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    baby_id      INT UNSIGNED NOT NULL,
    title        VARCHAR(190) NOT NULL,
    doctor       VARCHAR(190) NULL,
    hospital     VARCHAR(190) NULL,
    scheduled_at DATETIME NULL,
    notify       TINYINT(1) NOT NULL DEFAULT 0,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_appointments_baby (baby_id, scheduled_at),
    CONSTRAINT fk_appointments_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Annenin aylık günlüğü (month: bebeğin kaçıncı ayı, 0 tabanlı)
CREATE TABLE IF NOT EXISTS diary_entries (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    baby_id    INT UNSIGNED NOT NULL,
    month      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    body       TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_diary_baby (baby_id, month),
    CONSTRAINT fk_diary_baby FOREIGN KEY (baby_id) REFERENCES babies(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- İçerik ve uygulama ayarı (yönetici tarafından doldurulur)
-- ---------------------------------------------------------------------------

-- Ana sayfa "Bilgilendirmeler"
CREATE TABLE IF NOT EXISTS info_articles (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title      VARCHAR(190) NOT NULL,
    excerpt    VARCHAR(500) NOT NULL DEFAULT '',
    body       TEXT NOT NULL,
    image_url  VARCHAR(500) NULL,
    is_active  TINYINT(1) NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Bebeğin ayına göre gösterilen yazı (month: 0 tabanlı yaş ayı)
CREATE TABLE IF NOT EXISTS month_articles (
    id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    month      TINYINT UNSIGNED NOT NULL UNIQUE,
    title      VARCHAR(190) NOT NULL,
    body       TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Zorunlu güncelleme kontrolü (tek satır, id = 1)
CREATE TABLE IF NOT EXISTS app_config (
    id                   TINYINT UNSIGNED PRIMARY KEY,
    latest_version       VARCHAR(20) NOT NULL DEFAULT '1.0.0',
    min_required_version VARCHAR(20) NOT NULL DEFAULT '1.0.0',
    force_update         TINYINT(1) NOT NULL DEFAULT 0,
    android_store_url    VARCHAR(500) NULL,
    ios_store_url        VARCHAR(500) NULL,
    updated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT IGNORE INTO app_config (id, latest_version, min_required_version, force_update)
VALUES (1, '1.0.0', '1.0.0', 0);
