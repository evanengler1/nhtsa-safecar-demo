-- ============================================================================
-- NHTSA SafeCar Demo — Step 7: Create Streamlit App
-- ============================================================================
-- Create the Streamlit app directly in Snowsight:
--
--   1. Go to Projects > Streamlit > + Streamlit App
--   2. Name: NHTSA_SAFECAR_ANALYTICS
--   3. Database: NHTSA_SAFECAR_DEMO, Schema: SAFETY_DATA,
--      Warehouse: NHTSA_SAFECAR_WH
--   4. Click Create, then paste the contents of streamlit/streamlit_app.py
--   5. Add the "plotly" package via the Packages icon in the left sidebar
--   6. Click Run
--
-- Run this script to verify all prerequisite objects exist.
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
