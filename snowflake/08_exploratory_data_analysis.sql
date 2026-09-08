-- ============================================================================
-- NHTSA SafeCar Demo — Step 8: Exploratory Data Analysis
-- ============================================================================
-- Quick EDA to get a feel for the raw data, the analytical views, and
-- some interesting patterns in the NHTSA crash-test dataset.
-- Run top-to-bottom in Snowsight; each section is self-contained.
-- ============================================================================

USE WAREHOUSE NHTSA_SAFECAR_WH;
USE SCHEMA NHTSA_SAFECAR_DEMO.SAFETY_DATA;

-- ────────────────────────────────────────────────────────────────────────────
-- 1. RAW TABLE: shape and completeness
-- ────────────────────────────────────────────────────────────────────────────

-- Row count and year range
SELECT
    COUNT(*)                          AS TOTAL_VEHICLES,
    MIN(MODEL_YR)                     AS EARLIEST_YEAR,
    MAX(MODEL_YR)                     AS LATEST_YEAR,
    COUNT(DISTINCT MAKE)              AS DISTINCT_MAKES,
    COUNT(DISTINCT MODEL)             AS DISTINCT_MODELS,
    COUNT(DISTINCT BODY_STYLE)        AS DISTINCT_BODY_STYLES
FROM RAW_SAFERCAR;

-- How many vehicles per model year?
SELECT
    MODEL_YR,
    COUNT(*) AS VEHICLE_COUNT
FROM RAW_SAFERCAR
GROUP BY MODEL_YR
ORDER BY MODEL_YR;

-- Top 15 makes by number of tested vehicles
SELECT
    MAKE,
    COUNT(*) AS VEHICLES_TESTED
FROM RAW_SAFERCAR
GROUP BY MAKE
ORDER BY VEHICLES_TESTED DESC
LIMIT 15;

-- Null / empty prevalence for key star-rating columns
SELECT
    COUNT(*) AS TOTAL,
    COUNT_IF(OVERALL_STARS IS NULL OR TRIM(OVERALL_STARS) = '')       AS MISSING_OVERALL,
    COUNT_IF(OVERALL_FRNT_STARS IS NULL OR TRIM(OVERALL_FRNT_STARS) = '') AS MISSING_FRONTAL,
    COUNT_IF(OVERALL_SIDE_STARS IS NULL OR TRIM(OVERALL_SIDE_STARS) = '') AS MISSING_SIDE,
    COUNT_IF(ROLLOVER_STARS IS NULL OR TRIM(ROLLOVER_STARS) = '')     AS MISSING_ROLLOVER
FROM RAW_SAFERCAR;

-- ────────────────────────────────────────────────────────────────────────────
-- 2. STAR RATINGS: distributions
-- ────────────────────────────────────────────────────────────────────────────

-- Overall star rating distribution
SELECT
    TRY_TO_NUMBER(OVERALL_STARS) AS OVERALL_STARS,
    COUNT(*)                     AS VEHICLE_COUNT
FROM RAW_SAFERCAR
WHERE TRY_TO_NUMBER(OVERALL_STARS) IS NOT NULL
GROUP BY OVERALL_STARS
ORDER BY OVERALL_STARS;

-- Average overall rating by body style
SELECT
    BODY_STYLE,
    COUNT(*)                                           AS VEHICLES,
    ROUND(AVG(TRY_TO_NUMBER(OVERALL_STARS)), 2)        AS AVG_OVERALL,
    ROUND(AVG(TRY_TO_NUMBER(OVERALL_FRNT_STARS)), 2)   AS AVG_FRONTAL,
    ROUND(AVG(TRY_TO_NUMBER(OVERALL_SIDE_STARS)), 2)   AS AVG_SIDE,
    ROUND(AVG(TRY_TO_NUMBER(ROLLOVER_STARS)), 2)       AS AVG_ROLLOVER
FROM RAW_SAFERCAR
WHERE TRY_TO_NUMBER(OVERALL_STARS) IS NOT NULL
GROUP BY BODY_STYLE
ORDER BY AVG_OVERALL DESC;

-- ────────────────────────────────────────────────────────────────────────────
-- 3. VIEWS: safety summary trends
-- ────────────────────────────────────────────────────────────────────────────

-- Year-over-year average overall star rating (all makes)
SELECT
    MODEL_YR,
    SUM(VEHICLE_COUNT)                                         AS VEHICLES,
    ROUND(SUM(AVG_OVERALL_STARS * VEHICLE_COUNT)
        / NULLIF(SUM(VEHICLE_COUNT), 0), 2)                    AS WEIGHTED_AVG_OVERALL
FROM V_SAFETY_SUMMARY_BY_MAKE
WHERE MODEL_YR IS NOT NULL
GROUP BY MODEL_YR
ORDER BY MODEL_YR;

-- Makes with the biggest rating improvement (earliest vs latest decade)
WITH ERAS AS (
    SELECT
        MAKE,
        CASE WHEN MODEL_YR < 2015 THEN 'EARLY' ELSE 'RECENT' END AS ERA,
        AVG_OVERALL_STARS,
        VEHICLE_COUNT
    FROM V_SAFETY_SUMMARY_BY_MAKE
    WHERE AVG_OVERALL_STARS IS NOT NULL
),
PIVOTED AS (
    SELECT
        MAKE,
        ROUND(SUM(CASE WHEN ERA = 'EARLY'  THEN AVG_OVERALL_STARS * VEHICLE_COUNT END)
            / NULLIF(SUM(CASE WHEN ERA = 'EARLY'  THEN VEHICLE_COUNT END), 0), 2) AS AVG_EARLY,
        ROUND(SUM(CASE WHEN ERA = 'RECENT' THEN AVG_OVERALL_STARS * VEHICLE_COUNT END)
            / NULLIF(SUM(CASE WHEN ERA = 'RECENT' THEN VEHICLE_COUNT END), 0), 2) AS AVG_RECENT,
        SUM(VEHICLE_COUNT) AS TOTAL_VEHICLES
    FROM ERAS
    GROUP BY MAKE
    HAVING AVG_EARLY IS NOT NULL AND AVG_RECENT IS NOT NULL
)
SELECT
    MAKE,
    AVG_EARLY,
    AVG_RECENT,
    ROUND(AVG_RECENT - AVG_EARLY, 2) AS IMPROVEMENT,
    TOTAL_VEHICLES
FROM PIVOTED
ORDER BY IMPROVEMENT DESC
LIMIT 10;

-- ────────────────────────────────────────────────────────────────────────────
-- 4. ADAS: technology adoption snapshot
-- ────────────────────────────────────────────────────────────────────────────

-- ADAS adoption rates for the most recent model year
SELECT *
FROM V_ADVANCED_SAFETY_TECH_ADOPTION
WHERE MODEL_YR = (SELECT MAX(MODEL_YR) FROM V_ADVANCED_SAFETY_TECH_ADOPTION)
ORDER BY VEHICLE_COUNT DESC;

-- ADAS adoption over time (all body styles combined)
SELECT
    MODEL_YR,
    SUM(VEHICLE_COUNT)                                                        AS VEHICLES,
    ROUND(SUM(PCT_FCW * VEHICLE_COUNT) / NULLIF(SUM(VEHICLE_COUNT), 0), 1)    AS WTAVG_FCW,
    ROUND(SUM(PCT_CIB * VEHICLE_COUNT) / NULLIF(SUM(VEHICLE_COUNT), 0), 1)    AS WTAVG_CIB,
    ROUND(SUM(PCT_LDW * VEHICLE_COUNT) / NULLIF(SUM(VEHICLE_COUNT), 0), 1)    AS WTAVG_LDW,
    ROUND(SUM(PCT_ACC * VEHICLE_COUNT) / NULLIF(SUM(VEHICLE_COUNT), 0), 1)    AS WTAVG_ACC,
    ROUND(SUM(PCT_BLIND_SPOT * VEHICLE_COUNT) / NULLIF(SUM(VEHICLE_COUNT), 0), 1) AS WTAVG_BLIND_SPOT
FROM V_ADVANCED_SAFETY_TECH_ADOPTION
GROUP BY MODEL_YR
ORDER BY MODEL_YR;

-- ────────────────────────────────────────────────────────────────────────────
-- 5. BIOMECHANICAL RISK: weight vs. rollover
-- ────────────────────────────────────────────────────────────────────────────

-- Curb weight stats by body style
SELECT
    BODY_STYLE,
    COUNT(*)                            AS VEHICLES,
    ROUND(AVG(CURB_WEIGHT_LBS))         AS AVG_WEIGHT,
    MIN(CURB_WEIGHT_LBS)                AS MIN_WEIGHT,
    MAX(CURB_WEIGHT_LBS)                AS MAX_WEIGHT,
    ROUND(AVG(ROLLOVER_STAR_RATING), 2) AS AVG_ROLLOVER_STARS
FROM V_BIOMECHANICAL_RISK
GROUP BY BODY_STYLE
ORDER BY AVG_WEIGHT DESC;

-- Heaviest vehicles with low rollover ratings
SELECT
    MAKE,
    MODEL,
    MODEL_YR,
    BODY_STYLE,
    CURB_WEIGHT_LBS,
    ROLLOVER_STAR_RATING,
    ROLLOVER_POSSIBILITY
FROM V_BIOMECHANICAL_RISK
WHERE ROLLOVER_STAR_RATING <= 3
ORDER BY CURB_WEIGHT_LBS DESC
LIMIT 15;

-- ────────────────────────────────────────────────────────────────────────────
-- 6. QUICK JOINS: combining raw data with views
-- ────────────────────────────────────────────────────────────────────────────

-- For each make: overall rating + ADAS adoption in the latest year
WITH LATEST_YEAR AS (
    SELECT MAX(MODEL_YR) AS YR FROM RAW_SAFERCAR
)
SELECT
    s.MAKE,
    s.AVG_OVERALL_STARS,
    s.VEHICLE_COUNT,
    a.PCT_FCW,
    a.PCT_CIB,
    a.PCT_LDW
FROM V_SAFETY_SUMMARY_BY_MAKE s
JOIN LATEST_YEAR ly ON s.MODEL_YR = ly.YR
LEFT JOIN (
    SELECT MODEL_YR, PCT_FCW, PCT_CIB, PCT_LDW, VEHICLE_COUNT AS ADAS_VEHICLES
    FROM V_ADVANCED_SAFETY_TECH_ADOPTION
    WHERE BODY_STYLE = 'Sedan'
) a ON a.MODEL_YR = s.MODEL_YR
WHERE s.VEHICLE_COUNT >= 2
ORDER BY s.AVG_OVERALL_STARS DESC
LIMIT 15;
