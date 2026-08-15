-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for E-Commerce Marketplace Analytics
-- ============================================================================
USE DATABASE ECOMMERCE_ANALYTICS;
USE SCHEMA CURATED;

-- GMV_DASHBOARD: Real-time GMV by category, seller tier, and region with trend analysis
-- Source: ORDERS, SELLERS
CREATE OR REPLACE DYNAMIC TABLE CURATED.GMV_DASHBOARD
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ECOM_WH
AS
SELECT * FROM RAW.ORDERS;
-- TODO: Replace with actual join/aggregation logic per demo

-- SELLER_HEALTH_SCORE: Seller performance scoring: order defect rate, shipping SLA, response time
-- Source: ORDERS, SELLERS
CREATE OR REPLACE DYNAMIC TABLE CURATED.SELLER_HEALTH_SCORE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ECOM_WH
AS
SELECT * FROM RAW.ORDERS;
-- TODO: Replace with actual join/aggregation logic per demo

-- DEMAND_SIGNALS: Category demand trends and seasonal patterns for forecasting
-- Source: ORDERS, PRODUCTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.DEMAND_SIGNALS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ECOM_WH
AS
SELECT * FROM RAW.ORDERS;
-- TODO: Replace with actual join/aggregation logic per demo

-- CAMPAIGN_ROI: Promotional campaign effectiveness and incremental GMV attribution
-- Source: CAMPAIGNS, ORDERS
CREATE OR REPLACE DYNAMIC TABLE CURATED.CAMPAIGN_ROI
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ECOM_WH
AS
SELECT * FROM RAW.CAMPAIGNS;
-- TODO: Replace with actual join/aggregation logic per demo

