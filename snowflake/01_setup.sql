-- ============================================================================
-- NHTSA SafeCar Demo — Step 1: Setup
-- ============================================================================
-- Creates all the infrastructure needed for this demo:
--   - Warehouse, Database, Schema
--   - File format and internal stage for CSV loading
--   - The RAW_SAFERCAR table (128 columns)
--
-- Run this entire script in Snowsight (or SnowSQL) as SYSADMIN.
-- ============================================================================

USE ROLE SYSADMIN;

-- 1. Warehouse
CREATE OR REPLACE WAREHOUSE NHTSA_SAFECAR_WH
  WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- 2. Database and Schema
CREATE OR REPLACE DATABASE NHTSA_SAFECAR_DEMO;
CREATE OR REPLACE SCHEMA NHTSA_SAFECAR_DEMO.SAFETY_DATA;

USE WAREHOUSE NHTSA_SAFECAR_WH;
USE SCHEMA NHTSA_SAFECAR_DEMO.SAFETY_DATA;

-- 3. File format for the CSV (handles quoted fields with commas)
CREATE OR REPLACE FILE FORMAT CSV_SAFERCAR
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('')
  EMPTY_FIELD_AS_NULL = TRUE
  TRIM_SPACE = TRUE;

-- 4. Internal stage for uploading the CSV
CREATE OR REPLACE STAGE RAW_STAGE
  FILE_FORMAT = CSV_SAFERCAR;

-- 5. Table matching all 128 columns from the NHTSA data dictionary
CREATE OR REPLACE TABLE RAW_SAFERCAR (
    -- Vehicle metadata
    MAKE                           VARCHAR(20),
    MODEL                          VARCHAR(50),
    MODEL_YR                       NUMBER,
    BODY_STYLE                     VARCHAR(30),
    VEHICLE_TYPE                   VARCHAR(25),
    DRIVE_TRAIN                    VARCHAR(10),
    PRODUCTION_RELEASE             NUMBER,
    VEHICLE_CLASS                  VARCHAR(16),
    BODY_FRAME                     VARCHAR(16),
    NUM_OF_SEATING                 VARCHAR(35),
    SEAT_LOC                       VARCHAR(150),
    SEAT_LOC_COMMENTS              VARCHAR(130),

    -- Weight
    MIN_GROSS_WEIGHT               NUMBER,
    MAX_GROSS_WEIGHT               NUMBER,

    -- Seat belt systems
    UPPER_BELT_ANCHORAGE           VARCHAR(16),
    UPPER_BELT_ANCHORAGE_LOC       VARCHAR(40),
    SEAT_BELT_PRETENSIONER         VARCHAR(16),
    SEAT_BELT_PRETENSIONER_LOC     VARCHAR(40),
    LOAD_LIMITERS                  VARCHAR(16),
    LOAD_LIMITERS_LOC              VARCHAR(20),
    FRNT_BELT_INDICATOR            VARCHAR(16),
    FRNT_BELT_LOC                  VARCHAR(35),
    REAR_BELT_INDICATOR            VARCHAR(16),
    LATCH_REAR_POSITION            VARCHAR(60),

    -- Head side air bag
    HEAD_SAB                       VARCHAR(100),
    HEAD_SAB_TYPE                  VARCHAR(20),
    HEAD_SAB_LOC                   VARCHAR(40),
    HEAD_SAB_MOUNT_LOC             VARCHAR(16),
    HEAD_SAB_MEET_REQUIREMENTS     VARCHAR(70),
    HEAD_SAB_DEPLOY_IN_ROLLOVER    VARCHAR(16),

    -- Torso side air bag
    TORSO_SAB                      VARCHAR(40),
    TORSO_SAB_TYPE                 VARCHAR(40),
    TORSO_SAB_LOC                  VARCHAR(16),
    TORSO_SAB_MOUNT_LOC            VARCHAR(40),

    -- Knee bolsters
    KNEE_BOLSTERS                  VARCHAR(16),
    KNEE_BOLSTERS_LOC              VARCHAR(16),

    -- Misc safety
    ADL                            VARCHAR(35),
    HEAD_RESTRAINT_IND             VARCHAR(50),
    DYNAMIC_HEAD_RESTRAINT_IND     VARCHAR(16),
    BETI                           VARCHAR(16),

    -- ADAS & active safety
    BLIND_SPOT_DETECTION           VARCHAR(60),
    DAY_RUN_LIGHTS                 VARCHAR(80),
    ADAPTIVE_CRUISE_CONTROL        VARCHAR(60),
    ABS                            VARCHAR(30),
    ARS                            VARCHAR(25),
    ARS_LOC                        VARCHAR(20),
    AUTO_CRASH_NOTIFICATION        VARCHAR(16),
    CRASH_DATA_RECORDER            VARCHAR(20),
    ANTI_THEFT_DEVICE              VARCHAR(30),
    ANTI_THEFT_DEVICE_TYPE         VARCHAR(200),
    FRNT_COLLISION_WARNING         VARCHAR(20),
    NHTSA_FRNT_COLLISION_WARNING   VARCHAR(25),
    NHTSA_FCW_EVALUATION           VARCHAR(50),
    LANE_DEPARTURE_WARNING         VARCHAR(16),
    NHTSA_LANE_DEPARTURE_WARNING   VARCHAR(25),
    NHTSA_LDW_EVALUATION           VARCHAR(50),
    CRASH_IMMINENT_BRAKE           VARCHAR(16),
    NHTSA_CRASH_IMMINENT_BRAKE     VARCHAR(25),
    NHTSA_CIB_EVALUATION           VARCHAR(50),
    DYNAMIC_BRAKE_SUPPORT          VARCHAR(16),
    NHTSA_DYNAMIC_BRAKE_SUPPORT    VARCHAR(25),
    NHTSA_DBS_EVALUATION           VARCHAR(50),
    NHTSA_ESC                      VARCHAR(16),

    -- Pelvis side air bag
    PELVIS_SAB                     VARCHAR(30),
    PELVIS_SAB_TYPE                VARCHAR(16),
    PELVIS_SAB_LOC                 VARCHAR(16),
    PELVIS_SAB_MOUNT_LOC           VARCHAR(16),

    -- Overall rating
    OVERALL_STARS                  VARCHAR(5),

    -- Frontal impact
    FRNT_TEST_NO                   NUMBER,
    FRNT_VIN                       VARCHAR(17),
    FRNT_DRIV_STARS                VARCHAR(5),
    FRNT_PASS_STARS                VARCHAR(5),
    FRNT_SAFETY_CONCERN_DRIV       VARCHAR(450),
    FRNT_SAFETY_CONCERN_PASS       VARCHAR(320),
    FRNT_FOOT_NOTES                VARCHAR(600),
    FRNT_FOOT_NOTES_PASS           VARCHAR(320),
    OVERALL_FRNT_STARS             VARCHAR(5),
    CURB_WEIGHT                    VARCHAR(10),
    FRNT_TESTED_WITH               VARCHAR(100),
    HIC15_DRIV                     FLOAT,
    CHEST_DEFL_DRIV                FLOAT,
    LEFT_FEMUR_DRIV                FLOAT,
    RIGHT_FEMUR_DRIV               FLOAT,
    NIJ_DRIV                       FLOAT,
    NECK_TENS_DRIV                 FLOAT,
    NET_COMP_DRIV                  FLOAT,
    HIC15_PASS                     FLOAT,
    CHEST_DEFL_PASS                FLOAT,
    LEFT_FEMUR_PASS                FLOAT,
    RIGHT_FEMUR_PASS               FLOAT,
    NIJ_PASS                       FLOAT,
    NECK_TENS_PASS                 FLOAT,
    NET_COMP_PASS                  FLOAT,

    -- Side impact
    SIDE_TEST_NO                   NUMBER,
    SIDE_VIN                       VARCHAR(17),
    SIDE_DRIV_STARS                VARCHAR(5),
    SIDE_PASS_STARS                VARCHAR(5),
    SIDE_BARRIER_STAR              VARCHAR(5),
    COMB_FRNT_STAR                 VARCHAR(5),
    COMB_REAR_STAR                 VARCHAR(5),
    SIDE_SAFETY_CONCERN_DRIV       VARCHAR(500),
    SIDE_SAFETY_CONCERN_PASS       VARCHAR(600),
    SIDE_FOOT_NOTES                VARCHAR(700),
    SIDE_FOOT_NOTES_PASS           VARCHAR(450),
    OVERALL_SIDE_STARS             VARCHAR(5),
    SIDE_TESTED_WITH               VARCHAR(90),
    SIDE_HIC_36_DRIV               FLOAT,
    RIB_DEFLECTION_DRIV            FLOAT,
    ABDOMEN_FORCE_DRIV             FLOAT,
    SYMPHYSIS_FORCE_DRIV           FLOAT,
    SIDE_HIC_36_PASS               FLOAT,
    PELVIC_FORCE_PASS              FLOAT,

    -- Pole impact
    POLE_TEST_NO                   NUMBER,
    POLE_VIN                       VARCHAR(17),
    SIDE_POLE_STARS                VARCHAR(5),
    POLE_SAFETY_CONCERN            VARCHAR(370),
    POLE_FOOT_NOTES                VARCHAR(760),
    POLE_TESTED_WITH               VARCHAR(100),
    POLE_HIC_36_DRIV               FLOAT,
    PELVIC_FORCE                   FLOAT,

    -- Rollover
    ROLLOVER_POSSIBILITY           FLOAT,
    STATIC_STABI_FACTOR            FLOAT,
    TIP                            VARCHAR(10),
    ROLL_SAFETY_CONCERN            VARCHAR(130),
    ROLL_FOOT_NOTES                VARCHAR(130),
    ROLLOVER_STARS                 VARCHAR(5),

    -- Backup camera
    NHTSA_BACKUP_CAMERA            VARCHAR(16),
    BACKUP_CAMERA                  VARCHAR(16)
);
