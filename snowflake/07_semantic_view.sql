-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for E-Commerce Marketplace Analytics
-- ============================================================================
USE DATABASE ECOMMERCE_ANALYTICS;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.MARKETPLACE_ANALYTICS
  COMMENT = 'E-commerce marketplace GMV, seller, buyer, and campaign analytics'
AS
  TABLES (
    CURATED.GMV_DASHBOARD AS gmv_dashboard,CURATED.SELLER_HEALTH_SCORE AS seller_health_score,CURATED.DEMAND_SIGNALS AS demand_signals,CURATED.CAMPAIGN_ROI AS campaign_roi
  );
