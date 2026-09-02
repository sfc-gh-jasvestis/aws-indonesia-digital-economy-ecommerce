-- Generated from generator/demo_specs/aws-indonesia-digital-economy-ecommerce.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-indonesia-digital-economy-ecommerce
-- This is the schema that is actually deployed for ID_DIGITAL_ECONOMY_ECOMMERCE.

-- ID_DIGITAL_ECONOMY_ECOMMERCE  (E-Commerce Marketplace Analytics)
-- generated from generator/demo_specs/aws-indonesia-digital-economy-ecommerce.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS ID_DIGITAL_ECONOMY_ECOMMERCE;
CREATE SCHEMA IF NOT EXISTS ID_DIGITAL_ECONOMY_ECOMMERCE.RAW;
CREATE SCHEMA IF NOT EXISTS ID_DIGITAL_ECONOMY_ECOMMERCE.CURATED;
CREATE SCHEMA IF NOT EXISTS ID_DIGITAL_ECONOMY_ECOMMERCE.APP;
USE DATABASE ID_DIGITAL_ECONOMY_ECOMMERCE;

-- 5 real regions; entity names carry their region so the two always agree
