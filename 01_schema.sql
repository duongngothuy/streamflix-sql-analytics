-- StreamFlix schema + data load
-- Run from the folder that contains the CSVs.
-- If LOAD DATA LOCAL INFILE errors, start mysql with:  mysql --local-infile=1 -u root -p
-- and run:  SET GLOBAL local_infile = 1;

CREATE DATABASE IF NOT EXISTS streamflix;
USE streamflix;

DROP TABLE IF EXISTS payments, engagement, marketing_spend, subscriptions, users, plans;

CREATE TABLE plans (
  plan_id       INT PRIMARY KEY,
  plan_name     VARCHAR(20),
  monthly_price DECIMAL(6,2)
);

CREATE TABLE users (
  user_id             INT PRIMARY KEY,
  signup_date         DATE,
  acquisition_channel VARCHAR(20),
  country             VARCHAR(5),
  age                 INT
);

CREATE TABLE subscriptions (
  subscription_id INT PRIMARY KEY,
  user_id         INT,
  plan_id         INT,
  start_date      DATE,
  end_date        DATE NULL,
  status          VARCHAR(12)
);

CREATE TABLE payments (
  payment_id      INT PRIMARY KEY,
  user_id         INT,
  subscription_id INT,
  amount          DECIMAL(6,2),
  payment_date    DATE
);

CREATE TABLE engagement (
  user_id        INT,
  activity_month DATE,
  hours_watched  DECIMAL(5,1),
  days_active    INT
);

CREATE TABLE marketing_spend (
  spend_month  DATE,
  channel      VARCHAR(20),
  spend        DECIMAL(12,2),
  new_signups  INT
);

-- ---- load (note the NULLIF for blank end_dates) ----
LOAD DATA LOCAL INFILE 'plans.csv' INTO TABLE plans
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'users.csv' INTO TABLE users
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'subscriptions.csv' INTO TABLE subscriptions
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (subscription_id, user_id, plan_id, start_date, @end_date, status)
  SET end_date = NULLIF(@end_date, '');

LOAD DATA LOCAL INFILE 'payments.csv' INTO TABLE payments
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'engagement.csv' INTO TABLE engagement
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'marketing_spend.csv' INTO TABLE marketing_spend
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- sanity check
SELECT 'users' t, COUNT(*) n FROM users
UNION ALL SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'engagement', COUNT(*) FROM engagement
UNION ALL SELECT 'marketing_spend', COUNT(*) FROM marketing_spend;
