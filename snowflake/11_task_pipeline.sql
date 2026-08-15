-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for E-Commerce Marketplace Analytics
-- ============================================================================
USE DATABASE ECOMMERCE_ANALYTICS;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_REFRESH_GMV
  WAREHOUSE = ECOM_WH
  SCHEDULE = 'USING CRON 0 */1 * * * UTC'
  COMMENT = 'Refresh GMV dashboard with latest order data'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_SCORE_SELLERS
  WAREHOUSE = ECOM_WH
  AFTER APP.TASK_REFRESH_GMV
  COMMENT = 'Recalculate seller health and churn risk scores'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_FORECAST_GMV
  WAREHOUSE = ECOM_WH
  AFTER APP.TASK_SCORE_SELLERS
  COMMENT = 'Run GMV forecast by category'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_FORECAST_GMV RESUME;
ALTER TASK APP.TASK_SCORE_SELLERS RESUME;
ALTER TASK APP.TASK_REFRESH_GMV RESUME;
