-- ============================================================================
-- NHTSA SafeCar Demo — Semantic View
-- ============================================================================

USE DATABASE NHTSA_SAFECAR_DEMO;
USE SCHEMA SAFETY_DATA;

CREATE OR REPLACE SEMANTIC VIEW SAFECAR_SAFETY_RATINGS
	TABLES (
		VEHICLES AS NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR
		    COMMENT = 'NHTSA SaferCar vehicle safety ratings, crash test results, and safety feature data'
	)
	FACTS (
		VEHICLES.CURB_WEIGHT AS CURB_WEIGHT COMMENT = 'Vehicle curb weight',
		VEHICLES.MIN_GROSS_WEIGHT AS MIN_GROSS_WEIGHT COMMENT = 'Minimum gross vehicle weight rating',
		VEHICLES.MAX_GROSS_WEIGHT AS MAX_GROSS_WEIGHT COMMENT = 'Maximum gross vehicle weight rating',
		VEHICLES.ROLLOVER_POSSIBILITY AS ROLLOVER_POSSIBILITY COMMENT = 'Rollover probability percentage',
		VEHICLES.STATIC_STABILITY_FACTOR AS STATIC_STABI_FACTOR COMMENT = 'Static stability factor - higher is more stable',
		VEHICLES.HIC15_DRIVER AS HIC15_DRIV COMMENT = 'Head Injury Criterion (15ms) for driver in frontal crash test',
		VEHICLES.CHEST_DEFLECTION_DRIVER AS CHEST_DEFL_DRIV COMMENT = 'Chest deflection measurement for driver in frontal crash test (mm)',
		VEHICLES.LEFT_FEMUR_DRIVER AS LEFT_FEMUR_DRIV COMMENT = 'Left femur load for driver in frontal crash test (N)',
		VEHICLES.RIGHT_FEMUR_DRIVER AS RIGHT_FEMUR_DRIV COMMENT = 'Right femur load for driver in frontal crash test (N)'
	)
	DIMENSIONS (
		VEHICLES.MAKE AS MAKE WITH SYNONYMS = ('manufacturer','brand') COMMENT = 'Vehicle manufacturer (e.g. Toyota, Ford, Honda)',
		VEHICLES.MODEL AS MODEL WITH SYNONYMS = ('vehicle model','car model') COMMENT = 'Vehicle model name',
		VEHICLES.MODEL_YEAR AS MODEL_YR WITH SYNONYMS = ('year','model year') COMMENT = 'Model year of the vehicle',
		VEHICLES.BODY_STYLE AS BODY_STYLE WITH SYNONYMS = ('body type') COMMENT = 'Body style of the vehicle (e.g. Sedan, SUV, Pickup)',
		VEHICLES.VEHICLE_TYPE AS VEHICLE_TYPE COMMENT = 'Type of vehicle (e.g. Passenger Car, Truck)',
		VEHICLES.DRIVE_TRAIN AS DRIVE_TRAIN WITH SYNONYMS = ('drivetrain','drive type') COMMENT = 'Drive train type (e.g. AWD, FWD, RWD, 4WD)',
		VEHICLES.VEHICLE_CLASS AS VEHICLE_CLASS COMMENT = 'Vehicle weight class',
		VEHICLES.OVERALL_STARS AS OVERALL_STARS WITH SYNONYMS = ('overall rating','safety rating','star rating') COMMENT = 'Overall NHTSA safety star rating (1-5 stars)',
		VEHICLES.OVERALL_FRONT_STARS AS OVERALL_FRNT_STARS WITH SYNONYMS = ('frontal crash rating','front stars') COMMENT = 'Overall frontal crash test star rating',
		VEHICLES.OVERALL_SIDE_STARS AS OVERALL_SIDE_STARS WITH SYNONYMS = ('side crash rating','side stars') COMMENT = 'Overall side crash test star rating',
		VEHICLES.ROLLOVER_STARS AS ROLLOVER_STARS WITH SYNONYMS = ('rollover rating','tip over rating') COMMENT = 'Rollover resistance star rating',
		VEHICLES.FRONT_DRIVER_STARS AS FRNT_DRIV_STARS WITH SYNONYMS = ('driver frontal stars') COMMENT = 'Frontal crash test star rating for driver',
		VEHICLES.FRONT_PASSENGER_STARS AS FRNT_PASS_STARS WITH SYNONYMS = ('passenger frontal stars') COMMENT = 'Frontal crash test star rating for passenger',
		VEHICLES.SIDE_DRIVER_STARS AS SIDE_DRIV_STARS COMMENT = 'Side crash test star rating for driver',
		VEHICLES.SIDE_PASSENGER_STARS AS SIDE_PASS_STARS COMMENT = 'Side crash test star rating for passenger',
		VEHICLES.SIDE_BARRIER_STAR AS SIDE_BARRIER_STAR COMMENT = 'Side barrier crash test star rating',
		VEHICLES.SIDE_POLE_STARS AS SIDE_POLE_STARS COMMENT = 'Side pole crash test star rating',
		VEHICLES.BLIND_SPOT_DETECTION AS BLIND_SPOT_DETECTION COMMENT = 'Blind spot detection system availability',
		VEHICLES.ADAPTIVE_CRUISE_CONTROL AS ADAPTIVE_CRUISE_CONTROL WITH SYNONYMS = ('ACC') COMMENT = 'Adaptive cruise control system availability',
		VEHICLES.ABS_SYSTEM AS ABS WITH SYNONYMS = ('anti-lock brakes','anti-lock braking system') COMMENT = 'Anti-lock braking system type',
		VEHICLES.FRONT_COLLISION_WARNING AS FRNT_COLLISION_WARNING WITH SYNONYMS = ('FCW','forward collision warning') COMMENT = 'Front collision warning system availability',
		VEHICLES.LANE_DEPARTURE_WARNING AS LANE_DEPARTURE_WARNING WITH SYNONYMS = ('LDW') COMMENT = 'Lane departure warning system availability',
		VEHICLES.CRASH_IMMINENT_BRAKE AS CRASH_IMMINENT_BRAKE WITH SYNONYMS = ('CIB','automatic emergency braking','AEB') COMMENT = 'Crash imminent braking system availability',
		VEHICLES.DYNAMIC_BRAKE_SUPPORT AS DYNAMIC_BRAKE_SUPPORT WITH SYNONYMS = ('DBS') COMMENT = 'Dynamic brake support system availability',
		VEHICLES.ESC AS NHTSA_ESC WITH SYNONYMS = ('electronic stability control','ESC') COMMENT = 'Electronic stability control compliance',
		VEHICLES.BACKUP_CAMERA AS BACKUP_CAMERA WITH SYNONYMS = ('rear camera','rearview camera') COMMENT = 'Backup camera availability',
		VEHICLES.DAYTIME_RUNNING_LIGHTS AS DAY_RUN_LIGHTS WITH SYNONYMS = ('DRL') COMMENT = 'Daytime running lights availability'
	)
	METRICS (
		VEHICLES.VEHICLE_COUNT AS COUNT(*) WITH SYNONYMS = ('number of vehicles','total vehicles') COMMENT = 'Total number of vehicles tested',
		VEHICLES.AVG_OVERALL_STARS AS AVG(TRY_CAST(OVERALL_STARS AS FLOAT)) WITH SYNONYMS = ('average safety rating','mean star rating') COMMENT = 'Average overall safety star rating',
		VEHICLES.AVG_ROLLOVER_PROBABILITY AS AVG(ROLLOVER_POSSIBILITY) COMMENT = 'Average rollover probability percentage',
		VEHICLES.AVG_STABILITY_FACTOR AS AVG(STATIC_STABI_FACTOR) COMMENT = 'Average static stability factor'
	)
	COMMENT = 'NHTSA SaferCar vehicle safety ratings including overall and category star ratings, crash test measurements, and standard safety feature equipment across vehicle makes and models.'
	AI_VERIFIED_QUERIES (
		FIVE_STAR_VEHICLES AS (
			QUESTION 'Which vehicles have a 5-star overall safety rating?'
			VERIFIED_AT 1756137600
			VERIFIED_BY '(STEWARD = safety_analyst)'
			ONBOARDING_QUESTION TRUE
			SQL 'SELECT MAKE, MODEL, MODEL_YR, OVERALL_STARS, BODY_STYLE, DRIVE_TRAIN
			     FROM NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR
			     WHERE OVERALL_STARS = ''5''
			     ORDER BY MODEL_YR DESC, MAKE, MODEL'
		),
		HIGHEST_ROLLOVER_RISK AS (
			QUESTION 'What vehicles have the highest rollover risk?'
			VERIFIED_AT 1756137600
			VERIFIED_BY '(STEWARD = safety_analyst)'
			ONBOARDING_QUESTION TRUE
			SQL 'SELECT MAKE, MODEL, MODEL_YR, ROLLOVER_POSSIBILITY, STATIC_STABI_FACTOR, VEHICLE_TYPE
			     FROM NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR
			     WHERE ROLLOVER_POSSIBILITY IS NOT NULL
			     ORDER BY ROLLOVER_POSSIBILITY DESC LIMIT 20'
		),
		SAFETY_RATING_BY_MAKE AS (
			QUESTION 'What is the average safety rating by manufacturer?'
			VERIFIED_AT 1756137600
			VERIFIED_BY '(STEWARD = safety_analyst)'
			ONBOARDING_QUESTION TRUE
			SQL 'SELECT MAKE, COUNT(*) AS VEHICLE_COUNT, ROUND(AVG(TRY_CAST(OVERALL_STARS AS FLOAT)), 2) AS AVG_OVERALL_STARS
			     FROM NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR
			     WHERE OVERALL_STARS IS NOT NULL
			     GROUP BY MAKE
			     ORDER BY AVG_OVERALL_STARS DESC'
		),
		SAFETY_FEATURES_BY_YEAR AS (
			QUESTION 'How has the adoption of safety features changed over model years?'
			VERIFIED_AT 1756137600
			VERIFIED_BY '(STEWARD = safety_analyst)'
			ONBOARDING_QUESTION FALSE
			SQL 'SELECT MODEL_YR, COUNT(*) AS TOTAL_VEHICLES,
			     SUM(CASE WHEN BLIND_SPOT_DETECTION != ''Not Available'' THEN 1 ELSE 0 END) AS HAS_BLIND_SPOT,
			     SUM(CASE WHEN LANE_DEPARTURE_WARNING != ''Not Available'' THEN 1 ELSE 0 END) AS HAS_LDW,
			     SUM(CASE WHEN CRASH_IMMINENT_BRAKE != ''Not Available'' THEN 1 ELSE 0 END) AS HAS_AEB,
			     SUM(CASE WHEN BACKUP_CAMERA != ''Not Available'' THEN 1 ELSE 0 END) AS HAS_BACKUP_CAMERA
			     FROM NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR
			     WHERE MODEL_YR >= 2010
			     GROUP BY MODEL_YR
			     ORDER BY MODEL_YR'
		),
		SAFEST_SUVS AS (
			QUESTION 'What are the safest SUVs?'
			VERIFIED_AT 1756137600
			VERIFIED_BY '(STEWARD = safety_analyst)'
			ONBOARDING_QUESTION FALSE
			SQL 'SELECT MAKE, MODEL, MODEL_YR, OVERALL_STARS, OVERALL_FRNT_STARS, OVERALL_SIDE_STARS, ROLLOVER_STARS
			     FROM NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR
			     WHERE BODY_STYLE LIKE ''%SUV%'' AND OVERALL_STARS = ''5''
			     ORDER BY MODEL_YR DESC, MAKE, MODEL'
		)
	);
