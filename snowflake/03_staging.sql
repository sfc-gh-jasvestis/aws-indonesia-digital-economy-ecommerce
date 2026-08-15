-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for E-Commerce Marketplace Analytics
-- Country: INDONESIA | Currency: IDR
-- ============================================================================
USE DATABASE ECOMMERCE_ANALYTICS;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- ORDERS: 50,000,000 rows — 12 months of marketplace orders with GMV, category, and fulfillment data
-- SELLERS: 500,000 rows — Marketplace seller profiles with tier, performance metrics, and health score
-- BUYERS: 10,000,000 rows — Buyer profiles with purchase history, RFM segmentation, and lifetime value
-- PRODUCTS: 20,000,000 rows — Product catalog with pricing, category, and search ranking data
-- CAMPAIGNS: 10,000 rows — Promotional campaigns, vouchers, and flash sale records
-- SELLER_DOCS: 150 rows — Seller guidelines, policy documents, and category playbooks
