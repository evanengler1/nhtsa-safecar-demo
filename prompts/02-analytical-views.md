# Prompt 2 — Analytical Views

```
Create four analytical views in NHTSA_SAFECAR_DEMO.SAFETY_DATA over the RAW_SAFERCAR table:

1. V_SAFETY_SUMMARY_BY_MAKE — aggregate by MAKE and MODEL_YR. Include vehicle count and average star ratings for overall, frontal, side, and rollover categories. Star rating columns are VARCHAR so cast them to numbers. Round averages to 2 decimal places.

2. V_ADVANCED_SAFETY_TECH_ADOPTION — show ADAS adoption rate by model year and body style. Calculate the percentage of vehicles that have each feature: forward collision warning (FRNT_COLLISION_WARNING), crash imminent braking (CRASH_IMMINENT_BRAKE), lane departure warning, adaptive cruise control, blind spot detection, and dynamic brake support. A feature is "available" if its column is not null and not empty.

3. V_BIOMECHANICAL_RISK — pull crash injury risk metrics: make, model, year, body style, drive train, curb weight (cast to number), static stability factor, rollover possibility, rollover star rating, and key biomechanical measurements (HIC15 driver, chest deflection driver, side HIC driver, rib deflection driver, pelvis force driver, pelvic force passenger). Filter to rows where curb weight is not null and at least one biomechanical metric exists.

4. V_SAFETY_NOTES_SEARCHABLE — concatenate all safety-related text columns into a single COMBINED_SAFETY_NOTES column (frontal footnotes, frontal safety concerns driver/passenger, side footnotes, side safety concerns, pole footnotes, pole safety concerns, rollover footnotes, rollover safety concerns). Include a VEHICLE_ID column (make + model + year), plus MAKE, MODEL, MODEL_YR, and BODY_STYLE. Only include rows with at least one non-null safety note.
```
