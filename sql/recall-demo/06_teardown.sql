-- Teardown script for NHTSA_RECALL_DEMO environment.
-- Co-authored with CoCo
-- ==========================================
-- NHTSA VEHICLE SAFETY & RECALLS DEMO
-- FILE 6: COMPLETE ENVIRONMENT TEARDOWN
-- ==========================================
-- WARNING: Destructive and irreversible. Only run when the
-- demo environment is no longer needed.
-- ==========================================

USE ROLE SYSADMIN;

-- Remove the Cortex Agent
DROP AGENT IF EXISTS NHTSA_RECALL_DEMO.GOLD.NHTSA_RECALLS_AGENT;

-- Remove the Cortex Search Service
DROP CORTEX SEARCH SERVICE IF EXISTS NHTSA_RECALL_DEMO.GOLD.NHTSA_RECALL_SEARCH;

-- Remove external access objects
DROP EXTERNAL ACCESS INTEGRATION IF EXISTS NHTSA_API_ACCESS;
DROP NETWORK RULE IF EXISTS NHTSA_API_RULE;

-- Drop the database (cascades all schemas, tables, views, stages, procedures)
DROP DATABASE IF EXISTS NHTSA_RECALL_DEMO;

-- Drop the compute warehouse
DROP WAREHOUSE IF EXISTS NHTSA_WH;

-- Confirm cleanup
SHOW DATABASES LIKE 'NHTSA_RECALL_DEMO';
SHOW WAREHOUSES LIKE 'NHTSA_WH';
