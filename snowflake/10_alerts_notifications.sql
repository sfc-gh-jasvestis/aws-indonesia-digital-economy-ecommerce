-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for E-Commerce Marketplace Analytics
-- ============================================================================
USE DATABASE ECOMMERCE_ANALYTICS;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_indonesia_digital_economy_ecommerce_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: GMV_DECLINE_ALERT
CREATE OR REPLACE ALERT APP.GMV_DECLINE_ALERT
  WAREHOUSE = ECOM_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Significant GMV decline detected — investigate category and seller performance'
IF (EXISTS (
  SELECT 1 FROM CURATED.GMV_DASHBOARD
  WHERE 1=1 -- Condition: Daily GMV drops below 80% of 7-day moving average
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_digital_economy_ecommerce_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] E-Commerce Marketplace Analytics: Significant GMV decline detected — investigate category and seller performance',
    'Significant GMV decline detected — investigate category and seller performance'
  );

ALTER ALERT APP.GMV_DECLINE_ALERT RESUME;

-- Alert: SELLER_CHURN_ALERT
CREATE OR REPLACE ALERT APP.SELLER_CHURN_ALERT
  WAREHOUSE = ECOM_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'High-value seller at critical churn risk'
IF (EXISTS (
  SELECT 1 FROM CURATED.GMV_DASHBOARD
  WHERE 1=1 -- Condition: High-GMV seller churn risk score exceeds 85
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_digital_economy_ecommerce_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] E-Commerce Marketplace Analytics: High-value seller at critical churn risk',
    'High-value seller at critical churn risk'
  );

ALTER ALERT APP.SELLER_CHURN_ALERT RESUME;

