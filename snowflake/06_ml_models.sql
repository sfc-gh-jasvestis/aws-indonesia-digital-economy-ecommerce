-- ============================================================================
-- 06_ML_MODELS.SQL — ML Functions for E-Commerce Marketplace Analytics
-- ============================================================================
USE DATABASE ECOMMERCE_ANALYTICS;
USE SCHEMA ML;

-- ML.FORECAST: GMV_FORECAST
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST ML.GMV_FORECAST(
  INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'CURATED.GMV_DASHBOARD'),
  SERIES_COLNAME => 'CATEGORY',
  TIMESTAMP_COLNAME => 'DS',
  TARGET_COLNAME => 'Y'
  
);

CREATE OR REPLACE TABLE ML.GMV_FORECAST_RESULTS AS
SELECT * FROM TABLE(ML.GMV_FORECAST!FORECAST(FORECASTING_PERIODS => 14));

