# Prompt 1 — Infrastructure Setup

```
I have a CSV file with ~17,000 rows of NHTSA vehicle crash test data that I need to load into Snowflake. The data has 128 columns covering vehicle metadata, star ratings, crash test biomechanical measurements, ADAS features, and safety notes. I have a data dictionary file at data/Safercar_data_READ_ME_file.txt that describes all 128 columns.

Using the SYSADMIN role, set up the full infrastructure:
- An XS warehouse called NHTSA_SAFECAR_WH (auto-suspend 60s, auto-resume, initially suspended)
- A database called NHTSA_SAFECAR_DEMO with a schema called SAFETY_DATA
- A CSV file format called CSV_SAFERCAR that handles quoted fields with commas, skips the header row, and treats empty strings as NULL
- An internal stage called RAW_STAGE using that file format
- A table called RAW_SAFERCAR — read the data dictionary file and create the table matching all 128 columns with appropriate data types. Star rating columns should be VARCHAR(5), biomechanical measurements (HIC, chest deflection, femur loads, etc.) should be FLOAT, and text fields should be VARCHAR with reasonable lengths.

Then load the data from @RAW_STAGE/Safercar_data.csv into the table using COPY INTO, and verify the row count and show me a sample of 5 rows.
```
