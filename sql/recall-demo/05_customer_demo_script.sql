-- ==========================================
-- NHTSA VEHICLE SAFETY & RECALLS DEMO
-- FILE 5: LIVE CUSTOMER DEMO SCRIPT
-- ==========================================
-- Run this script statement-by-statement in Snowsight.
-- After the SQL queries, switch to Cortex Agent for
-- the natural language prompts listed below.
-- ==========================================

USE ROLE SYSADMIN;
USE WAREHOUSE NHTSA_WH;
USE DATABASE NHTSA_DEMO;

-- ==========================================
-- PART 1: Analytics Queries
-- ==========================================

-- Recall volume and severity by manufacturer
SELECT
    MANUFACTURER,
    COUNT(DISTINCT NHTSA_CAMPAIGN_NUMBER) AS RECALL_CAMPAIGNS,
    SUM(UNITS_AFFECTED) AS TOTAL_UNITS_AT_RISK,
    SUM(CASE WHEN PARK_IT THEN 1 ELSE 0 END) AS CRITICAL_DO_NOT_DRIVE,
    SUM(CASE WHEN PARK_OUTSIDE THEN 1 ELSE 0 END) AS FIRE_RISK
FROM GOLD.RECALL_DETAILS
GROUP BY MANUFACTURER
ORDER BY TOTAL_UNITS_AT_RISK DESC NULLS LAST;

-- Top 10 most-recalled components across all OEMs
SELECT
    COMPONENT,
    COUNT(DISTINCT NHTSA_CAMPAIGN_NUMBER) AS CAMPAIGNS,
    COUNT(DISTINCT MANUFACTURER) AS MANUFACTURERS_AFFECTED,
    SUM(UNITS_AFFECTED) AS TOTAL_UNITS,
    SUM(CASE WHEN PARK_IT OR PARK_OUTSIDE THEN 1 ELSE 0 END) AS CRITICAL_SEVERITY
FROM GOLD.RECALL_DETAILS
GROUP BY COMPONENT
ORDER BY CAMPAIGNS DESC
LIMIT 10;

-- Most severe "PARK IT" recalls — vehicles that should not be driven
SELECT
    MANUFACTURER,
    MODEL,
    MODEL_YEAR,
    COMPONENT,
    UNITS_AFFECTED,
    LEFT(CONSEQUENCE, 200) AS SAFETY_CONSEQUENCE
FROM GOLD.RECALL_DETAILS
WHERE PARK_IT = TRUE
ORDER BY UNITS_AFFECTED DESC NULLS LAST
LIMIT 10;

-- ==========================================
-- PART 2: Natural Language Prompts
-- ==========================================
-- Run these in Cortex Agent (NHTSA_RECALLS_AGENT) or Cortex Code:
--
-- 1. "Which manufacturer has the highest total number of
--     units affected by recalls?"
--
-- 2. "Show me all Tesla recalls and highlight any that
--     are classified as critical safety risks"
--
-- 3. "What components have the most recalls across all
--     manufacturers? Are there common failure patterns?"
--
-- 4. "Compare Ford and Toyota — who has more critical recalls
--     in 2024, and which components are most affected for each?"
--
-- 5. "Are there any recalls involving fire risk? How many
--     total vehicles are affected and which models?"
-- ==========================================

-- ==========================================
-- PART 3: Performance Validation (optional)
-- ==========================================

-- Show recent query execution times to demonstrate performance
SELECT
    QUERY_TEXT,
    EXECUTION_STATUS,
    TOTAL_ELAPSED_TIME / 1000 AS SECONDS,
    WAREHOUSE_SIZE,
    CREDITS_USED_CLOUD_SERVICES
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(
    DATEADD('hours', -1, CURRENT_TIMESTAMP()),
    CURRENT_TIMESTAMP()
))
WHERE QUERY_TYPE = 'SELECT'
ORDER BY START_TIME DESC
LIMIT 10;

-- ==========================================
-- CLEANUP (only run after demo is complete)
-- ==========================================
-- DROP DATABASE IF EXISTS NHTSA_DEMO;
-- DROP WAREHOUSE IF EXISTS NHTSA_WH;
