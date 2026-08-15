-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for E-Commerce Marketplace Analytics
-- ============================================================================
USE DATABASE ECOMMERCE_ANALYTICS;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.MARKETPLACE_INTELLIGENCE_AGENT
  COMMENT = 'E-Commerce Marketplace Analytics AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'ECOMMERCE_ANALYTICS.APP.MARKETPLACE_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'ECOMMERCE_ANALYTICS.SEARCH.SELLER_DOCS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Digital Economy & E-Commerce information')
  )
  SYSTEM_PROMPT = 'You are the Marketplace Intelligence Agent for Indonesia''s leading e-commerce platform with 500,000 sellers, 10 million buyers, and Rp 120 trillion annual GMV.';
