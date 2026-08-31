-- ==========================================
-- NHTSA VEHICLE SAFETY & RECALLS DEMO
-- FILE 4: CORTEX SEMANTIC MODEL & AGENT
-- ==========================================

USE ROLE SYSADMIN;
USE WAREHOUSE NHTSA_WH;
USE DATABASE NHTSA_DEMO;
USE SCHEMA GOLD;

-- ==========================================
-- STEP 1: Define the Semantic Model
-- ==========================================
-- The semantic model tells Cortex AI what tables exist, what columns
-- mean in business terms, valid metrics, and pre-verified queries.
-- This prevents hallucination and ensures accurate SQL generation.

CREATE OR REPLACE TEMPORARY TABLE _SEMANTIC_MODEL_STAGING (
    YAML_CONTENT VARCHAR
);

INSERT INTO _SEMANTIC_MODEL_STAGING VALUES (
$$
name: NHTSA Vehicle Recalls
description: >
  Semantic model for NHTSA vehicle safety recall data covering all 
  manufacturers, components, and safety risk classifications. Enables
  natural language queries about recall trends, manufacturer risk,
  and critical safety events.

tables:
  - name: RECALL_DETAILS
    description: >
      Individual recall records from the National Highway Traffic Safety
      Administration (NHTSA). Each row represents one recall campaign
      for a specific vehicle make/model/year combination.
    base_table:
      database: NHTSA_DEMO
      schema: GOLD
      table: RECALL_DETAILS
    dimensions:
      - name: NHTSA_CAMPAIGN_NUMBER
        description: Unique NHTSA-assigned recall campaign identifier
        expr: NHTSA_CAMPAIGN_NUMBER
        data_type: VARCHAR
      - name: MANUFACTURER
        description: Vehicle manufacturer (e.g., Toyota Motor, Ford Motor Company)
        expr: MANUFACTURER
        data_type: VARCHAR
      - name: MAKE
        description: Vehicle make/brand (e.g., TOYOTA, FORD, BMW)
        expr: MAKE
        data_type: VARCHAR
      - name: MODEL
        description: Vehicle model name (e.g., Camry, F-150, 3 Series)
        expr: MODEL
        data_type: VARCHAR
      - name: COMPONENT
        description: >
          Vehicle component or system affected by the recall 
          (e.g., AIR BAGS, ELECTRICAL SYSTEM, FUEL SYSTEM)
        expr: COMPONENT
        data_type: VARCHAR
      - name: RECALL_SUMMARY
        description: Detailed text description of the recall defect
        expr: RECALL_SUMMARY
        data_type: VARCHAR
      - name: CONSEQUENCE
        description: Description of safety consequences if defect is not remedied
        expr: CONSEQUENCE
        data_type: VARCHAR
      - name: REMEDY
        description: Description of the manufacturer remedy for the recall
        expr: REMEDY
        data_type: VARCHAR
      - name: REPORT_TYPE
        description: Type of recall report filed with NHTSA
        expr: REPORT_TYPE
        data_type: VARCHAR
      - name: PARK_IT
        description: >
          Critical safety flag - TRUE means the vehicle should not be driven
          until the recall remedy is applied. Highest severity indicator.
        expr: PARK_IT
        data_type: BOOLEAN
      - name: PARK_OUTSIDE
        description: >
          Critical fire safety flag - TRUE means the vehicle should be parked
          outside and away from structures due to fire risk.
        expr: PARK_OUTSIDE
        data_type: BOOLEAN
    time_dimensions:
      - name: REPORT_RECEIVED_DATE
        description: Date NHTSA received the recall report from the manufacturer
        expr: REPORT_RECEIVED_DATE
        data_type: DATE
    measures:
      - name: TOTAL_RECALLS
        description: Count of recall campaign records
        expr: COUNT(DISTINCT NHTSA_CAMPAIGN_NUMBER)
        data_type: NUMBER
      - name: TOTAL_UNITS_AFFECTED
        description: >
          Sum of potentially affected vehicles across all matching recalls.
          This represents the total exposure or risk footprint.
        expr: SUM(UNITS_AFFECTED)
        data_type: NUMBER
      - name: AVG_UNITS_AFFECTED
        description: Average number of units affected per recall campaign
        expr: AVG(UNITS_AFFECTED)
        data_type: NUMBER
      - name: CRITICAL_RECALL_COUNT
        description: Number of recalls with PARK_IT = TRUE (do not drive severity)
        expr: SUM(CASE WHEN PARK_IT = TRUE THEN 1 ELSE 0 END)
        data_type: NUMBER
      - name: FIRE_RISK_COUNT
        description: Number of recalls with PARK_OUTSIDE = TRUE (fire/explosion risk)
        expr: SUM(CASE WHEN PARK_OUTSIDE = TRUE THEN 1 ELSE 0 END)
        data_type: NUMBER
      - name: DISTINCT_MANUFACTURERS
        description: Count of unique manufacturers affected
        expr: COUNT(DISTINCT MANUFACTURER)
        data_type: NUMBER
      - name: DISTINCT_COMPONENTS
        description: Count of unique components/systems affected
        expr: COUNT(DISTINCT COMPONENT)
        data_type: NUMBER
      - name: MODEL_YEAR
        description: The model year of the recalled vehicle
        expr: MODEL_YEAR
        data_type: NUMBER

  - name: RECALLS_SUMMARY
    description: >
      Pre-aggregated recall metrics by manufacturer and model year.
      Use this table for high-level trend analysis and manufacturer comparisons.
    base_table:
      database: NHTSA_DEMO
      schema: GOLD
      table: RECALLS_SUMMARY
    dimensions:
      - name: MANUFACTURER
        description: Vehicle manufacturer name
        expr: MANUFACTURER
        data_type: VARCHAR
    time_dimensions:
      - name: MODEL_YEAR
        description: Vehicle model year for trend analysis
        expr: MODEL_YEAR
        data_type: NUMBER
    measures:
      - name: TOTAL_RECALL_CAMPAIGNS
        description: Number of distinct recall campaigns
        expr: SUM(TOTAL_RECALL_CAMPAIGNS)
        data_type: NUMBER
      - name: TOTAL_UNITS_AFFECTED
        description: Total vehicles potentially affected
        expr: SUM(TOTAL_UNITS_AFFECTED)
        data_type: NUMBER
      - name: CRITICAL_PARK_IT_COUNT
        description: Recalls where vehicles should not be driven
        expr: SUM(CRITICAL_PARK_IT_COUNT)
        data_type: NUMBER
      - name: CRITICAL_PARK_OUTSIDE_COUNT
        description: Recalls with fire/explosion risk
        expr: SUM(CRITICAL_PARK_OUTSIDE_COUNT)
        data_type: NUMBER

verified_queries:
  - name: top_manufacturers_by_units_affected
    question: Which manufacturers have the most units affected by recalls?
    sql: >
      SELECT MANUFACTURER, SUM(UNITS_AFFECTED) AS TOTAL_UNITS_AFFECTED,
             COUNT(DISTINCT NHTSA_CAMPAIGN_NUMBER) AS RECALL_CAMPAIGNS
      FROM NHTSA_DEMO.GOLD.RECALL_DETAILS
      GROUP BY MANUFACTURER
      ORDER BY TOTAL_UNITS_AFFECTED DESC NULLS LAST
      LIMIT 10
    verified_at: 2024-01-15
    verified_by: Solutions Architecture

  - name: critical_safety_recalls
    question: Show me all critical recalls where vehicles should not be driven
    sql: >
      SELECT MANUFACTURER, MAKE, MODEL, MODEL_YEAR, COMPONENT,
             UNITS_AFFECTED, RECALL_SUMMARY
      FROM NHTSA_DEMO.GOLD.RECALL_DETAILS
      WHERE PARK_IT = TRUE
      ORDER BY UNITS_AFFECTED DESC NULLS LAST
    verified_at: 2024-01-15
    verified_by: Solutions Architecture

  - name: recalls_by_component
    question: What are the most commonly recalled components?
    sql: >
      SELECT COMPONENT, 
             COUNT(DISTINCT NHTSA_CAMPAIGN_NUMBER) AS RECALL_COUNT,
             SUM(UNITS_AFFECTED) AS TOTAL_UNITS,
             COUNT(DISTINCT MANUFACTURER) AS MANUFACTURERS_AFFECTED
      FROM NHTSA_DEMO.GOLD.RECALL_DETAILS
      GROUP BY COMPONENT
      ORDER BY RECALL_COUNT DESC
      LIMIT 15
    verified_at: 2024-01-15
    verified_by: Solutions Architecture

  - name: fire_risk_recalls
    question: Which recalls involve fire risk?
    sql: >
      SELECT MANUFACTURER, MODEL, MODEL_YEAR, COMPONENT,
             UNITS_AFFECTED, CONSEQUENCE
      FROM NHTSA_DEMO.GOLD.RECALL_DETAILS
      WHERE PARK_OUTSIDE = TRUE
      ORDER BY REPORT_RECEIVED_DATE DESC
    verified_at: 2024-01-15
    verified_by: Solutions Architecture

  - name: tesla_recalls
    question: Show me all Tesla recalls
    sql: >
      SELECT MODEL, MODEL_YEAR, COMPONENT, UNITS_AFFECTED,
             REPORT_RECEIVED_DATE, RECALL_SUMMARY, PARK_IT, PARK_OUTSIDE
      FROM NHTSA_DEMO.GOLD.RECALL_DETAILS
      WHERE MAKE = 'TESLA'
      ORDER BY REPORT_RECEIVED_DATE DESC
    verified_at: 2024-01-15
    verified_by: Solutions Architecture
$$
);

-- Upload the semantic model YAML to the stage
-- (In practice, use: PUT file:///path/to/nhtsa_recalls_model.yaml @GOLD.MODELS)
COPY INTO @GOLD.MODELS/nhtsa_recalls_model.yaml
FROM (SELECT YAML_CONTENT FROM _SEMANTIC_MODEL_STAGING)
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = NONE COMPRESSION = NONE)
SINGLE = TRUE
OVERWRITE = TRUE;

-- ==========================================
-- STEP 2: Create a Cortex Search Service for recall text retrieval
-- ==========================================

CREATE OR REPLACE CORTEX SEARCH SERVICE GOLD.NHTSA_RECALL_SEARCH
  ON RECALL_SUMMARY
  WAREHOUSE = NHTSA_WH
  TARGET_LAG = '1 hour'
  AS (
    SELECT
      NHTSA_CAMPAIGN_NUMBER,
      MANUFACTURER,
      MAKE,
      MODEL,
      MODEL_YEAR,
      COMPONENT,
      RECALL_SUMMARY,
      CONSEQUENCE,
      REMEDY
    FROM SILVER.VEHICLE_RECALLS
  );

-- ==========================================
-- STEP 3: Deploy the Cortex Agent
-- ==========================================
-- The agent uses the semantic model for text-to-SQL, ensuring
-- queries are grounded in defined metrics rather than hallucinated.
-- Access control is enforced at the data layer (RBAC on tables).

CREATE OR REPLACE CORTEX AGENT GOLD.NHTSA_RECALLS_AGENT
  COMMENT = 'Conversational AI agent for NHTSA vehicle recall analysis'
  FROM SPECIFICATION $$
models:
  - snowflake-intelligence

orchestration:
  strategy: auto

instructions: >
  You are an expert vehicle safety analyst with deep knowledge of NHTSA
  recall data. Help users understand recall trends, identify high-risk
  manufacturers and components, and surface critical safety issues.
  Always cite specific recall campaign numbers when possible.
  When discussing severity, highlight PARK_IT (do not drive) and
  PARK_OUTSIDE (fire risk) flags prominently.

tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: recall_analyst

tool_resources:
  recall_analyst:
    semantic_model_file: '@NHTSA_DEMO.GOLD.MODELS/nhtsa_recalls_model.yaml'
$$;

-- Verify the agent is deployed
SHOW CORTEX AGENTS IN SCHEMA GOLD;
