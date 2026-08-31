-- ==========================================
-- NHTSA VEHICLE SAFETY & RECALLS DEMO
-- FILE 2: BRONZE LAYER INGESTION
-- ==========================================

USE ROLE SYSADMIN;
USE WAREHOUSE NHTSA_WH;
USE DATABASE NHTSA_DEMO;
USE SCHEMA BRONZE;

-- Raw recalls table using VARIANT to store JSON without schema pre-definition
CREATE OR REPLACE TABLE BRONZE.RAW_RECALLS (
    INGESTION_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    SOURCE_API         VARCHAR(255) DEFAULT 'NHTSA_RECALLS_API_V2',
    RAW_DATA           VARIANT,
    RECORD_COUNT       NUMBER
);

-- Network rule allowing outbound calls to the public NHTSA API
CREATE OR REPLACE NETWORK RULE NHTSA_API_RULE
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = ('api.nhtsa.gov:443');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION NHTSA_API_ACCESS
    ALLOWED_NETWORK_RULES = (NHTSA_API_RULE)
    ENABLED = TRUE
    COMMENT = 'Allows stored procedures to call the public NHTSA API';

-- Python stored procedure that calls the NHTSA Recalls API
-- and lands the full JSON response into BRONZE.RAW_RECALLS
CREATE OR REPLACE PROCEDURE BRONZE.INGEST_NHTSA_RECALLS(
    MODEL_YEAR INT,
    MAKE VARCHAR
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'requests')
EXTERNAL_ACCESS_INTEGRATIONS = (NHTSA_API_ACCESS)
HANDLER = 'ingest_recalls'
COMMENT = 'Pulls recall data from NHTSA public API and lands in BRONZE'
AS
$$
import requests
import json
from snowflake.snowpark import Session

def ingest_recalls(session, model_year: int, make: str) -> str:
    base_url = "https://api.nhtsa.gov/recalls/recallsByVehicle"
    params = {"make": make, "modelYear": model_year}
    
    response = requests.get(base_url, params=params, timeout=30)
    
    if response.status_code != 200:
        return f"ERROR: API returned status {response.status_code}"
    
    data = response.json()
    results = data.get("results", [])
    record_count = data.get("Count", len(results))
    
    if record_count == 0:
        return f"No recalls found for {model_year} {make}"
    
    session.sql(f"""
        INSERT INTO BRONZE.RAW_RECALLS (RAW_DATA, RECORD_COUNT)
        SELECT PARSE_JSON('{json.dumps(data).replace("'", "''")}'), {record_count}
    """).collect()
    
    return f"SUCCESS: Ingested {record_count} recall records for {model_year} {make}"
$$;

-- Ingest recall data for major manufacturers across recent model years
CALL BRONZE.INGEST_NHTSA_RECALLS(2024, 'TOYOTA');
CALL BRONZE.INGEST_NHTSA_RECALLS(2024, 'FORD');
CALL BRONZE.INGEST_NHTSA_RECALLS(2024, 'HONDA');
CALL BRONZE.INGEST_NHTSA_RECALLS(2024, 'CHEVROLET');
CALL BRONZE.INGEST_NHTSA_RECALLS(2024, 'BMW');
CALL BRONZE.INGEST_NHTSA_RECALLS(2024, 'TESLA');
CALL BRONZE.INGEST_NHTSA_RECALLS(2023, 'TOYOTA');
CALL BRONZE.INGEST_NHTSA_RECALLS(2023, 'FORD');
CALL BRONZE.INGEST_NHTSA_RECALLS(2023, 'HONDA');
CALL BRONZE.INGEST_NHTSA_RECALLS(2023, 'TESLA');

-- Verify ingestion — query inside the JSON using dot-notation
SELECT
    INGESTION_TIMESTAMP,
    SOURCE_API,
    RECORD_COUNT,
    RAW_DATA:Count::INT AS API_REPORTED_COUNT
FROM BRONZE.RAW_RECALLS
ORDER BY INGESTION_TIMESTAMP DESC;

-- Preview fields from the first record in each payload
SELECT
    RAW_DATA:Count::INT AS TOTAL_RECALLS,
    RAW_DATA:results[0]:Manufacturer::VARCHAR AS FIRST_MANUFACTURER,
    RAW_DATA:results[0]:Component::VARCHAR AS FIRST_COMPONENT,
    RAW_DATA:results[0]:Summary::VARCHAR AS FIRST_SUMMARY
FROM BRONZE.RAW_RECALLS
LIMIT 5;

-- Explore the full JSON structure of a single recall record
SELECT RAW_DATA:results[0] AS SAMPLE_RECORD
FROM BRONZE.RAW_RECALLS
LIMIT 1;
