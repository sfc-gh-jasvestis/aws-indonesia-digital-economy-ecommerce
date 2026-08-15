-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for E-Commerce Marketplace Analytics
-- ============================================================================
USE DATABASE ECOMMERCE_ANALYTICS;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.SELLER_DOCS_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, DOC_TYPE, SELLER_TIER
  WAREHOUSE = ECOM_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.SELLER_DOCS
);
