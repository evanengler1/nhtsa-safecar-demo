-- ============================================================================
-- NHTSA SafeCar Demo — Cortex Search Service
-- ============================================================================

USE DATABASE NHTSA_SAFECAR_DEMO;
USE SCHEMA SAFETY_DATA;

CREATE OR REPLACE CORTEX SEARCH SERVICE NHTSA_SAFETY_NOTES_INDEX
    ON COMBINED_SAFETY_NOTES
    ATTRIBUTES MAKE, MODEL, MODEL_YR, BODY_STYLE
    WAREHOUSE = 'COMPUTE_WH'
    TARGET_LAG = '1 day'
    REFRESH_MODE = INCREMENTAL
    AS (
        SELECT
            VEHICLE_ID,
            MAKE,
            MODEL,
            MODEL_YR,
            BODY_STYLE,
            COMBINED_SAFETY_NOTES
        FROM NHTSA_SAFECAR_DEMO.SAFETY_DATA.V_SAFETY_NOTES_SEARCHABLE
    );
