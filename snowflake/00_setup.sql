-- ============================================================================
-- E-Commerce Marketplace Analytics
-- Seller and buyer intelligence for Indonesia's US$82B e-commerce market — ML.FORECAST projects GMV growth, Dynamic Tables build real-time marketplace dashboards, and Cortex AI generates seller recommendations.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS ECOMMERCE_ANALYTICS;
CREATE WAREHOUSE IF NOT EXISTS ECOM_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE ECOMMERCE_ANALYTICS;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE ECOM_WH;
