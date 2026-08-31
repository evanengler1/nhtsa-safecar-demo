-- ==========================================
-- NHTSA VEHICLE SAFETY & RECALLS DEMO
-- FILE 3: SILVER TRANSFORMATIONS & GOLD LAYER
-- ==========================================

USE ROLE SYSADMIN;
USE WAREHOUSE NHTSA_WH;
USE DATABASE NHTSA_DEMO;
USE SCHEMA SILVER;

-- ==========================================
-- SILVER LAYER: Flatten JSON into typed columns
-- ==========================================

-- LATERAL FLATTEN unnests each recall from the JSON array into its own row.
-- Dot-notation (::VARCHAR, ::NUMBER, etc.) casts to strong SQL types.
CREATE OR REPLACE TABLE SILVER.VEHICLE_RECALLS AS
SELECT
    r.INGESTION_TIMESTAMP,

    -- Recall identification
    recall.value:NHTSACampaignNumber::VARCHAR(20)       AS NHTSA_CAMPAIGN_NUMBER,
    recall.value:ReportReceivedDate::DATE                AS REPORT_RECEIVED_DATE,

    -- Vehicle identification
    recall.value:Manufacturer::VARCHAR(200)              AS MANUFACTURER,
    recall.value:Make::VARCHAR(100)                      AS MAKE,
    recall.value:Model::VARCHAR(100)                     AS MODEL,
    recall.value:ModelYear::NUMBER(4,0)                  AS MODEL_YEAR,

    -- Recall details
    recall.value:Component::VARCHAR(500)                 AS COMPONENT,
    recall.value:Summary::VARCHAR(5000)                  AS RECALL_SUMMARY,
    recall.value:Consequence::VARCHAR(3000)              AS CONSEQUENCE,
    recall.value:Remedy::VARCHAR(3000)                   AS REMEDY,
    recall.value:Notes::VARCHAR(3000)                    AS NOTES,

    -- Affected units
    recall.value:PotentialNumberofUnitsAffected::NUMBER  AS UNITS_AFFECTED,

    -- Critical safety flags
    -- PARK_IT = TRUE means "do not drive this vehicle"
    -- PARK_OUTSIDE = TRUE means "fire/explosion risk — keep away from structures"
    recall.value:ParkIt::BOOLEAN                         AS PARK_IT,
    recall.value:ParkOutSide::BOOLEAN                    AS PARK_OUTSIDE,

    -- Classification
    recall.value:ReportType::VARCHAR(50)                 AS REPORT_TYPE,
    recall.value:NHTSAActionNumber::VARCHAR(20)          AS NHTSA_ACTION_NUMBER

FROM BRONZE.RAW_RECALLS r,
    LATERAL FLATTEN(input => r.RAW_DATA:results) recall;

-- Cluster on common query patterns for scan efficiency
ALTER TABLE SILVER.VEHICLE_RECALLS
    CLUSTER BY (MANUFACTURER, MODEL_YEAR);

-- Verify row counts and coverage
SELECT
    COUNT(*) AS TOTAL_RECORDS,
    COUNT(DISTINCT NHTSA_CAMPAIGN_NUMBER) AS UNIQUE_CAMPAIGNS,
    COUNT(DISTINCT MANUFACTURER) AS MANUFACTURERS,
    MIN(MODEL_YEAR) AS EARLIEST_YEAR,
    MAX(MODEL_YEAR) AS LATEST_YEAR
FROM SILVER.VEHICLE_RECALLS;

-- Preview the transformed data
SELECT
    NHTSA_CAMPAIGN_NUMBER,
    MANUFACTURER,
    MAKE,
    MODEL,
    MODEL_YEAR,
    COMPONENT,
    UNITS_AFFECTED,
    PARK_IT,
    PARK_OUTSIDE,
    LEFT(RECALL_SUMMARY, 150) AS SUMMARY_PREVIEW
FROM SILVER.VEHICLE_RECALLS
ORDER BY REPORT_RECEIVED_DATE DESC
LIMIT 20;

-- Show the most severe recalls (do-not-drive or fire risk)
SELECT
    MANUFACTURER,
    MODEL,
    MODEL_YEAR,
    COMPONENT,
    UNITS_AFFECTED,
    LEFT(CONSEQUENCE, 200) AS CONSEQUENCE_PREVIEW
FROM SILVER.VEHICLE_RECALLS
WHERE PARK_IT = TRUE OR PARK_OUTSIDE = TRUE
ORDER BY UNITS_AFFECTED DESC NULLS LAST;

-- ==========================================
-- GOLD LAYER: Business-ready aggregates and AI-ready views
-- ==========================================

USE SCHEMA GOLD;

-- Manufacturer + model year summary for trend analysis and dashboards
CREATE OR REPLACE VIEW GOLD.RECALLS_SUMMARY AS
SELECT
    MANUFACTURER,
    MODEL_YEAR,
    COUNT(DISTINCT NHTSA_CAMPAIGN_NUMBER) AS TOTAL_RECALL_CAMPAIGNS,
    COUNT(*) AS TOTAL_RECALL_RECORDS,
    SUM(UNITS_AFFECTED) AS TOTAL_UNITS_AFFECTED,
    SUM(CASE WHEN PARK_IT = TRUE THEN 1 ELSE 0 END) AS CRITICAL_PARK_IT_COUNT,
    SUM(CASE WHEN PARK_OUTSIDE = TRUE THEN 1 ELSE 0 END) AS CRITICAL_PARK_OUTSIDE_COUNT,
    COUNT(DISTINCT COMPONENT) AS DISTINCT_COMPONENTS_AFFECTED,
    MIN(REPORT_RECEIVED_DATE) AS EARLIEST_REPORT,
    MAX(REPORT_RECEIVED_DATE) AS LATEST_REPORT
FROM SILVER.VEHICLE_RECALLS
GROUP BY MANUFACTURER, MODEL_YEAR;

-- Component risk analysis — which systems fail most often and across how many OEMs
CREATE OR REPLACE VIEW GOLD.COMPONENT_RISK_ANALYSIS AS
SELECT
    COMPONENT,
    COUNT(DISTINCT MANUFACTURER) AS MANUFACTURERS_AFFECTED,
    COUNT(DISTINCT NHTSA_CAMPAIGN_NUMBER) AS RECALL_CAMPAIGNS,
    SUM(UNITS_AFFECTED) AS TOTAL_UNITS_AFFECTED,
    SUM(CASE WHEN PARK_IT = TRUE THEN 1 ELSE 0 END) AS CRITICAL_COUNT,
    ARRAY_AGG(DISTINCT MANUFACTURER) AS MANUFACTURER_LIST
FROM SILVER.VEHICLE_RECALLS
GROUP BY COMPONENT;

-- Detailed recall view (used by Cortex Agent for text-to-SQL)
CREATE OR REPLACE VIEW GOLD.RECALL_DETAILS AS
SELECT
    NHTSA_CAMPAIGN_NUMBER,
    REPORT_RECEIVED_DATE,
    MANUFACTURER,
    MAKE,
    MODEL,
    MODEL_YEAR,
    COMPONENT,
    RECALL_SUMMARY,
    CONSEQUENCE,
    REMEDY,
    UNITS_AFFECTED,
    PARK_IT,
    PARK_OUTSIDE,
    REPORT_TYPE
FROM SILVER.VEHICLE_RECALLS;

-- Validate the Gold layer
SELECT * FROM GOLD.RECALLS_SUMMARY
ORDER BY TOTAL_UNITS_AFFECTED DESC NULLS LAST
LIMIT 10;
