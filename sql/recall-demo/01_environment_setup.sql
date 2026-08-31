-- ==========================================
-- NHTSA VEHICLE SAFETY & RECALLS DEMO
-- FILE 1: ENVIRONMENT SETUP
-- ==========================================

-- Set execution context
USE ROLE SYSADMIN;

-- Create a dedicated X-Small warehouse with aggressive auto-suspend
-- to minimize cost when idle (resumes instantly on next query)
CREATE WAREHOUSE IF NOT EXISTS NHTSA_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Dedicated compute for NHTSA Vehicle Safety Demo';

USE WAREHOUSE NHTSA_WH;

-- Create the demo database
CREATE DATABASE IF NOT EXISTS NHTSA_DEMO
    COMMENT = 'NHTSA Vehicle Safety & Recalls - Medallion Architecture Demo';

-- Medallion architecture: Bronze (raw) → Silver (cleansed) → Gold (business-ready)
CREATE SCHEMA IF NOT EXISTS NHTSA_DEMO.BRONZE
    COMMENT = 'Raw ingestion layer - semi-structured data as-landed';

CREATE SCHEMA IF NOT EXISTS NHTSA_DEMO.SILVER
    COMMENT = 'Conformed layer - flattened, typed, quality-checked';

CREATE SCHEMA IF NOT EXISTS NHTSA_DEMO.GOLD
    COMMENT = 'Consumption layer - aggregates, semantic models, AI-ready';

-- Internal stages for raw data landing and semantic model artifacts
CREATE STAGE IF NOT EXISTS NHTSA_DEMO.BRONZE.RAW_DATA
    COMMENT = 'Landing zone for raw JSON from NHTSA API';

CREATE STAGE IF NOT EXISTS NHTSA_DEMO.GOLD.MODELS
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Semantic model YAML specifications for Cortex Analyst';

-- Verify the environment
SHOW SCHEMAS IN DATABASE NHTSA_DEMO;
