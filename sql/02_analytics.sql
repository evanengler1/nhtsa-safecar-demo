/*=============================================================================
  NHTSA Fleet Safety & Crashworthiness Intelligence Portal
  02_analytics.sql — Analytical Views
=============================================================================*/

USE WAREHOUSE NHTSA_SAFECAR_WH;
USE SCHEMA NHTSA_SAFECAR_DEMO.SAFETY_DATA;

/*-----------------------------------------------------------------------------
  V_SAFETY_SUMMARY_BY_MAKE
  Aggregates average star ratings by make and model year.
  Star columns are CHAR(40) in source — use TRY_TO_NUMBER for safe casting.
-----------------------------------------------------------------------------*/
CREATE OR REPLACE VIEW V_SAFETY_SUMMARY_BY_MAKE AS
SELECT
    MAKE,
    MODEL_YR,
    COUNT(*) AS VEHICLE_COUNT,
    ROUND(AVG(TRY_TO_NUMBER(OVERALL_STARS)), 2) AS AVG_OVERALL_STARS,
    ROUND(AVG(TRY_TO_NUMBER(OVERALL_FRNT_STARS)), 2) AS AVG_FRONTAL_STARS,
    ROUND(AVG(TRY_TO_NUMBER(OVERALL_SIDE_STARS)), 2) AS AVG_SIDE_STARS,
    ROUND(AVG(TRY_TO_NUMBER(ROLLOVER_STARS)), 2) AS AVG_ROLLOVER_STARS,
    ROUND(AVG(TRY_TO_NUMBER(FRNT_DRIV_STARS)), 2) AS AVG_FRNT_DRIV_STARS,
    ROUND(AVG(TRY_TO_NUMBER(FRNT_PASS_STARS)), 2) AS AVG_FRNT_PASS_STARS
FROM RAW_SAFERCAR
WHERE MAKE IS NOT NULL
GROUP BY MAKE, MODEL_YR
ORDER BY MAKE, MODEL_YR;

/*-----------------------------------------------------------------------------
  V_ADVANCED_SAFETY_TECH_ADOPTION
  Calculates adoption percentages of key ADAS technologies by model year
  and body style. A feature is considered "present" if the column is
  non-null and non-empty.
-----------------------------------------------------------------------------*/
CREATE OR REPLACE VIEW V_ADVANCED_SAFETY_TECH_ADOPTION AS
SELECT
    MODEL_YR,
    BODY_STYLE,
    COUNT(*) AS VEHICLE_COUNT,

    ROUND(100.0 * COUNT_IF(FRNT_COLLISION_WARNING IS NOT NULL AND TRIM(FRNT_COLLISION_WARNING) != '')
        / NULLIF(COUNT(*), 0), 1) AS PCT_FCW,

    ROUND(100.0 * COUNT_IF(CRASH_IMMINENT_BRAKE IS NOT NULL AND TRIM(CRASH_IMMINENT_BRAKE) != '')
        / NULLIF(COUNT(*), 0), 1) AS PCT_CIB,

    ROUND(100.0 * COUNT_IF(LANE_DEPARTURE_WARNING IS NOT NULL AND TRIM(LANE_DEPARTURE_WARNING) != '')
        / NULLIF(COUNT(*), 0), 1) AS PCT_LDW,

    ROUND(100.0 * COUNT_IF(ADAPTIVE_CRUISE_CONTROL IS NOT NULL AND TRIM(ADAPTIVE_CRUISE_CONTROL) != '')
        / NULLIF(COUNT(*), 0), 1) AS PCT_ACC,

    ROUND(100.0 * COUNT_IF(BLIND_SPOT_DETECTION IS NOT NULL AND TRIM(BLIND_SPOT_DETECTION) != '')
        / NULLIF(COUNT(*), 0), 1) AS PCT_BLIND_SPOT,

    ROUND(100.0 * COUNT_IF(DYNAMIC_BRAKE_SUPPORT IS NOT NULL AND TRIM(DYNAMIC_BRAKE_SUPPORT) != '')
        / NULLIF(COUNT(*), 0), 1) AS PCT_DBS

FROM RAW_SAFERCAR
WHERE MODEL_YR IS NOT NULL AND BODY_STYLE IS NOT NULL
GROUP BY MODEL_YR, BODY_STYLE
ORDER BY MODEL_YR, BODY_STYLE;

/*-----------------------------------------------------------------------------
  V_BIOMECHANICAL_RISK
  Correlates vehicle weight, stability factor, rollover risk, and head/chest
  injury metrics for engineering analysis.
  CURB_WEIGHT is CHAR(40) — cast safely. Biomechanical columns are NUMBER(10,5).
-----------------------------------------------------------------------------*/
CREATE OR REPLACE VIEW V_BIOMECHANICAL_RISK AS
SELECT
    MAKE,
    MODEL,
    MODEL_YR,
    BODY_STYLE,
    DRIVE_TRAIN,
    TRY_TO_NUMBER(CURB_WEIGHT) AS CURB_WEIGHT_LBS,
    STATIC_STABI_FACTOR,
    ROLLOVER_POSSIBILITY,
    TRY_TO_NUMBER(ROLLOVER_STARS) AS ROLLOVER_STAR_RATING,
    HIC15_DRIV,
    CHEST_DEFL_DRIV,
    SIDE_HIC_36_DRIV,
    RIB_DEFLECTION_DRIV,
    SYMPHYSIS_FORCE_DRIV,
    PELVIC_FORCE_PASS
FROM RAW_SAFERCAR
WHERE TRY_TO_NUMBER(CURB_WEIGHT) IS NOT NULL
  AND (HIC15_DRIV IS NOT NULL OR STATIC_STABI_FACTOR IS NOT NULL)
ORDER BY MAKE, MODEL, MODEL_YR;
