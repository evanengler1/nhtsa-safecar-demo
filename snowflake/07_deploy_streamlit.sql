-- ============================================================================
-- NHTSA SafeCar Demo — Step 7: Deploy Streamlit App
-- ============================================================================
-- The Streamlit app is deployed using the Snowflake CLI.
--
-- From the root of this repo, run:
--
--   cd streamlit
--   snow streamlit deploy nhtsa_safecar_analytics -c <connection_name> --replace
--
-- After deploying, run this script to verify it's running.
-- ============================================================================

USE WAREHOUSE NHTSA_SAFECAR_WH;
USE SCHEMA NHTSA_SAFECAR_DEMO.SAFETY_DATA;

-- Verify that all prerequisite objects exist
SELECT 'RAW_SAFERCAR' AS OBJECT_NAME, COUNT(*) AS ROW_COUNT FROM RAW_SAFERCAR
UNION ALL
SELECT 'V_SAFETY_SUMMARY_BY_MAKE', COUNT(*) FROM V_SAFETY_SUMMARY_BY_MAKE
UNION ALL
SELECT 'V_ADVANCED_SAFETY_TECH_ADOPTION', COUNT(*) FROM V_ADVANCED_SAFETY_TECH_ADOPTION
UNION ALL
SELECT 'V_BIOMECHANICAL_RISK', COUNT(*) FROM V_BIOMECHANICAL_RISK
UNION ALL
SELECT 'V_SAFETY_NOTES_SEARCHABLE', COUNT(*) FROM V_SAFETY_NOTES_SEARCHABLE;

-- Verify the Streamlit app is deployed
SHOW STREAMLITS LIKE 'NHTSA_SAFECAR_ANALYTICS' IN SCHEMA NHTSA_SAFECAR_DEMO.SAFETY_DATA;

-- (Optional) Grant access to other roles
-- GRANT USAGE ON STREAMLIT NHTSA_SAFECAR_DEMO.SAFETY_DATA.NHTSA_SAFECAR_ANALYTICS
--     TO ROLE <role_name>;
