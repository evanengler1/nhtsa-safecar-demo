-- ============================================================================
-- NHTSA SafeCar Demo — Step 6: Create Cortex Search Service
-- ============================================================================

USE WAREHOUSE NHTSA_SAFECAR_WH;
USE SCHEMA NHTSA_SAFECAR_DEMO.SAFETY_DATA;

CREATE OR REPLACE CORTEX SEARCH SERVICE NHTSA_SAFETY_NOTES_INDEX
    ON COMBINED_SAFETY_NOTES
    ATTRIBUTES MAKE, MODEL, MODEL_YR, BODY_STYLE
    WAREHOUSE = 'NHTSA_SAFECAR_WH'
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
