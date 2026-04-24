CREATE DATABASE IF NOT EXISTS intrath
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE intrath;

CREATE TABLE roles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  label VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO roles (name, label) VALUES
('superadmin', 'Superadmin'),
('executive', 'Geschäftsführer'),
('admin', 'Admin'),
('employee', 'Mitarbeiter'),
('external', 'Externer Nutzer');

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  role_id INT NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) DEFAULT NULL,
  first_name VARCHAR(100) DEFAULT NULL,
  last_name VARCHAR(100) DEFAULT NULL,
  language ENUM('de','en','uk') DEFAULT 'de',
  is_active TINYINT(1) DEFAULT 0,
  invited_at DATETIME DEFAULT NULL,
  activated_at DATETIME DEFAULT NULL,
  last_login_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME DEFAULT NULL,
  FOREIGN KEY (role_id) REFERENCES roles(id)
);

CREATE TABLE auth_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT DEFAULT NULL,
  email VARCHAR(255) DEFAULT NULL,
  type ENUM('password_reset','invitation') NOT NULL,
  token_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE app_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(100) NOT NULL UNIQUE,
  setting_value TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tasks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT NULL,
  status ENUM('open','in_progress','blocked','review','done','deferred') DEFAULT 'open',
  priority ENUM('low','medium','high','critical') DEFAULT 'medium',
  owner_id INT DEFAULT NULL,
  reviewer_id INT DEFAULT NULL,
  created_by INT NOT NULL,
  due_date DATE DEFAULT NULL,
  completed_at DATETIME DEFAULT NULL,
  approved_at DATETIME DEFAULT NULL,
  approved_by INT DEFAULT NULL,
  archived_at DATETIME DEFAULT NULL,
  deleted_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id),
  FOREIGN KEY (reviewer_id) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id),
  FOREIGN KEY (approved_by) REFERENCES users(id)
);

CREATE TABLE task_participants (
  task_id INT NOT NULL,
  user_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (task_id, user_id),
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE task_checklist_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  task_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  is_done TINYINT(1) DEFAULT 0,
  position INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

CREATE TABLE weeklies (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  scheduled_at DATETIME DEFAULT NULL,
  status ENUM('draft','active','completed','locked') DEFAULT 'draft',
  moderator_id INT DEFAULT NULL,
  completed_at DATETIME DEFAULT NULL,
  locked_at DATETIME DEFAULT NULL,
  protocol_html LONGTEXT DEFAULT NULL,
  protocol_pdf_path VARCHAR(500) DEFAULT NULL,
  created_by INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME DEFAULT NULL,
  FOREIGN KEY (moderator_id) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE weekly_participants (
  weekly_id INT NOT NULL,
  user_id INT NOT NULL,
  status ENUM('invited','present','absent') DEFAULT 'invited',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (weekly_id, user_id),
  FOREIGN KEY (weekly_id) REFERENCES weeklies(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE agenda_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  weekly_id INT DEFAULT NULL,
  parent_agenda_item_id INT DEFAULT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT NULL,
  category ENUM('carry_over','blocker','pipeline','team','decision','new_task','summary','custom') DEFAULT 'custom',
  status ENUM('open','in_progress','done','deferred') DEFAULT 'open',
  priority ENUM('low','medium','high','critical') DEFAULT 'medium',
  owner_id INT DEFAULT NULL,
  time_budget_minutes INT DEFAULT NULL,
  is_blocker TINYINT(1) DEFAULT 0,
  carry_over_count INT DEFAULT 0,
  decision_text TEXT DEFAULT NULL,
  position INT DEFAULT 0,
  created_by INT NOT NULL,
  archived_at DATETIME DEFAULT NULL,
  deleted_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (weekly_id) REFERENCES weeklies(id) ON DELETE SET NULL,
  FOREIGN KEY (parent_agenda_item_id) REFERENCES agenda_items(id) ON DELETE SET NULL,
  FOREIGN KEY (owner_id) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE agenda_item_tasks (
  agenda_item_id INT NOT NULL,
  task_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (agenda_item_id, task_id),
  FOREIGN KEY (agenda_item_id) REFERENCES agenda_items(id) ON DELETE CASCADE,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

CREATE TABLE comments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  entity_type ENUM('task','agenda_item','weekly') NOT NULL,
  entity_id INT NOT NULL,
  body TEXT NOT NULL,
  created_by INT NOT NULL,
  edited_at DATETIME DEFAULT NULL,
  deleted_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE comment_reactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  comment_id INT NOT NULL,
  user_id INT NOT NULL,
  reaction VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_reaction (comment_id, user_id, reaction),
  FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  type VARCHAR(100) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT DEFAULT NULL,
  target_type VARCHAR(50) DEFAULT NULL,
  target_id INT DEFAULT NULL,
  read_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE activity_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  actor_id INT DEFAULT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INT NOT NULL,
  action VARCHAR(100) NOT NULL,
  old_value TEXT DEFAULT NULL,
  new_value TEXT DEFAULT NULL,
  context TEXT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (actor_id) REFERENCES users(id)
);
