-- ============================================================================
-- NHTSA SafeCar Demo — Streamlit App Deployment
-- ============================================================================
-- This file documents the Streamlit-in-Snowflake deployment.
-- The app is deployed using the Snowflake CLI from the streamlit/ directory.
--
-- Prerequisites:
--   1. All prior SQL scripts (01-05) have been executed
--   2. Data has been loaded into RAW_SAFERCAR
--   3. Snowflake CLI is installed and configured
--
-- Deploy command:
--   cd streamlit/
--   snow streamlit deploy nhtsa_safecar_analytics \
--       -c <connection_name> --replace
--
-- Verify deployment:
--   SHOW STREAMLITS LIKE 'NHTSA_SAFECAR_ANALYTICS' IN ACCOUNT;
--
-- Grant access to other roles (optional):
--   GRANT USAGE ON STREAMLIT NHTSA_SAFECAR_DEMO.SAFETY_DATA.NHTSA_SAFECAR_ANALYTICS
--       TO ROLE <role_name>;
-- ============================================================================

USE DATABASE NHTSA_SAFECAR_DEMO;
USE SCHEMA SAFETY_DATA;

-- Verify that prerequisite objects exist before deploying the Streamlit app
SELECT 'RAW_SAFERCAR' AS OBJECT, COUNT(*) AS ROW_COUNT
FROM RAW_SAFERCAR
UNION ALL
SELECT 'V_SAFETY_SUMMARY_BY_MAKE', COUNT(*) FROM V_SAFETY_SUMMARY_BY_MAKE
UNION ALL
SELECT 'V_ADVANCED_SAFETY_TECH_ADOPTION', COUNT(*) FROM V_ADVANCED_SAFETY_TECH_ADOPTION
UNION ALL
SELECT 'V_BIOMECHANICAL_RISK', COUNT(*) FROM V_BIOMECHANICAL_RISK
UNION ALL
SELECT 'V_SAFETY_NOTES_SEARCHABLE', COUNT(*) FROM V_SAFETY_NOTES_SEARCHABLE;
