-- ============================================================================
-- NHTSA SafeCar Demo — Step 2: Load Data
-- ============================================================================
-- Before running this script, upload the CSV to the stage using the
-- Snowflake CLI from the root of this repo:
--
--   snow stage copy data/Safercar_data.csv @NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_STAGE -c <connection_name>
--
-- Then run this script in Snowsight to load the data into the table.
-- ============================================================================

USE WAREHOUSE NHTSA_SAFECAR_WH;
USE SCHEMA NHTSA_SAFECAR_DEMO.SAFETY_DATA;

-- Load data from stage into table
COPY INTO RAW_SAFERCAR
  FROM @RAW_STAGE/Safercar_data.csv
  FILE_FORMAT = CSV_SAFERCAR
  ON_ERROR = 'ABORT_STATEMENT';

-- Verify the load
SELECT COUNT(*) AS ROW_COUNT FROM RAW_SAFERCAR;
SELECT * FROM RAW_SAFERCAR LIMIT 5;
