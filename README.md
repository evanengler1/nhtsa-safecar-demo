# NHTSA SafeCar Vehicle Safety Ratings Demo

A Snowflake demo that loads NHTSA vehicle crash test data and builds analytics on top of it — views, stored procedures, a Cortex AI semantic layer, Cortex Search, and an interactive Streamlit dashboard.

## What You'll Build

| Snowflake Object | What It Does |
|---|---|
| `RAW_SAFERCAR` table | 17,000+ vehicles with 128 columns of crash test data |
| 4 analytical views | Safety summaries, ADAS adoption trends, crash risk metrics, searchable notes |
| 4 stored procedures | Parameterized lookups for ratings, risk, and trends |
| Semantic View | Cortex AI-powered natural language querying with verified queries |
| Cortex Search Service | Full-text search over crash test safety notes |
| Streamlit App | Interactive 4-tab analytics dashboard |

## Prerequisites

1. **A Snowflake account** — any edition works. You need a role with `SYSADMIN` privileges.
2. **Snowflake CLI (`snow`)** — only needed for the Streamlit app deployment (Step 7). Steps 1-6 use Snowsight only.
   - Install: https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation
   - Configure a connection: `snow connection add` (follow the prompts)
   - Test it: `snow connection test -c <connection_name>`

## Setup (Step by Step)

All SQL scripts are in the `snowflake/` folder, numbered in order. Open each one in [Snowsight](https://app.snowflake.com) (the Snowflake web UI) and run it.

### Step 1: Create the infrastructure

Open `snowflake/01_setup.sql` in Snowsight and run the entire script.

This creates:
- A warehouse (`NHTSA_SAFECAR_WH`)
- A database and schema (`NHTSA_SAFECAR_DEMO.SAFETY_DATA`)
- A CSV file format and internal stage for loading data
- The `RAW_SAFERCAR` table (128 columns)

### Step 2: Upload and load the data

Upload the CSV file to the Snowflake stage through Snowsight:

1. In the left sidebar, navigate to **Data > Databases > NHTSA_SAFECAR_DEMO > SAFETY_DATA > Stages > RAW_STAGE**
2. Click the **"+ Files"** button in the top right
3. Upload the `data/Safercar_data.csv` file from this repo

Then open `snowflake/02_load_data.sql` in Snowsight and run it. This loads the CSV into the table and shows a row count to confirm it worked (expect ~17,000 rows).

### Step 3: Create the views

Open `snowflake/03_create_views.sql` in Snowsight and run it.

Creates four analytical views:
- `V_SAFETY_SUMMARY_BY_MAKE` — average star ratings by manufacturer and year
- `V_ADVANCED_SAFETY_TECH_ADOPTION` — ADAS feature adoption rates by year and body style
- `V_BIOMECHANICAL_RISK` — crash injury metrics correlated with vehicle weight and stability
- `V_SAFETY_NOTES_SEARCHABLE` — concatenated safety notes for Cortex Search

### Step 4: Create the stored procedures

Open `snowflake/04_create_procedures.sql` in Snowsight and run it.

Creates four stored procedures with optional filter parameters:
- `SP_SAFETY_RATINGS_LOOKUP` — look up ratings by make/model/year
- `SP_SAFETY_SUMMARY_BY_MAKE` — summary stats by manufacturer
- `SP_ADAS_TECH_ADOPTION` — ADAS adoption trends
- `SP_BIOMECHANICAL_RISK` — crash injury risk lookup

### Step 5: Create the semantic view

Open `snowflake/05_create_semantic_view.sql` in Snowsight and run it.

This creates a Cortex AI semantic view (`SAFECAR_SAFETY_RATINGS`) that enables natural language querying. It includes five verified queries like "Which vehicles have a 5-star overall safety rating?" and "What are the safest SUVs?".

### Step 6: Create the Cortex Search service

Open `snowflake/06_create_cortex_search.sql` in Snowsight and run it.

This creates a search service (`NHTSA_SAFETY_NOTES_INDEX`) over the crash test safety notes, enabling natural language search from the Streamlit app.

### Step 7: Deploy the Streamlit app

From the root of this repo:

```bash
cd streamlit
snow streamlit deploy nhtsa_safecar_analytics -c <connection_name> --replace
```

Then open `snowflake/07_deploy_streamlit.sql` in Snowsight and run it to verify everything is in place.

The Streamlit app has four tabs:

| Tab | What It Shows |
|---|---|
| Safety Ratings | Filterable star-rating dashboard with KPIs and distribution charts |
| ADAS Adoption | Line charts showing safety technology adoption trends by model year |
| Crash Risk Analysis | Scatter plots and bar charts of crash injury metrics |
| AI Safety Search | Natural language search over crash test notes via Cortex Search |

## Teardown

To remove all demo objects from your account:

Open `snowflake/99_teardown.sql` in Snowsight and run it. This drops everything in reverse order.

## Repository Structure

```
snowflake/                        SQL scripts (run in order)
  01_setup.sql                    Warehouse, database, schema, stage, table
  02_load_data.sql                Load CSV data into the table
  03_create_views.sql             4 analytical views
  04_create_procedures.sql        4 stored procedures
  05_create_semantic_view.sql     Cortex AI semantic view + verified queries
  06_create_cortex_search.sql     Cortex Search service
  07_deploy_streamlit.sql         Streamlit deployment verification
  99_teardown.sql                 Remove everything
  nhtsa_semantic_model.yaml       Cortex Analyst YAML model (alternative to semantic view)

streamlit/                        Streamlit-in-Snowflake app
  streamlit_app.py                Multi-tab analytics dashboard
  snowflake.yml                   SiS deployment manifest
  pyproject.toml                  Python dependencies

app/                              Next.js dashboard (Snowflake App Runtime / SPCS)

data/                             Source data
  Safercar_data.csv               NHTSA SaferCar raw data (~17K vehicles, 128 columns)
  Safercar_data_READ_ME_file.txt  Data dictionary
```

## Data Source

[NHTSA SaferCar API](https://www.nhtsa.gov/nhtsa-safercar) — vehicle safety ratings from the National Highway Traffic Safety Administration.
