# NHTSA SafeCar Vehicle Safety Ratings Demo

Snowflake-powered demo using NHTSA SaferCar vehicle safety crash test data. Includes a Cortex AI semantic layer, Cortex Search, stored procedures, and a Next.js dashboard deployed on Snowflake App Runtime (SPCS).

## Repository Structure

```
├── app/                          # Next.js dashboard (Snowflake App Runtime)
│   ├── app/                      # Next.js pages and API routes
│   │   ├── api/facets/           # Facet filter endpoint
│   │   ├── api/overview/         # Dashboard overview stats
│   │   └── api/vehicles/         # Vehicle search endpoint
│   ├── components/               # React components
│   ├── lib/                      # Snowflake connection, types, utilities
│   ├── app.yml                   # SPCS app manifest
│   └── snowflake.yml             # Snowflake CLI project config
│
├── streamlit/                    # Streamlit-in-Snowflake analytics app
│   ├── streamlit_app.py          # Multi-tab app (ratings, ADAS, risk, AI search)
│   └── snowflake.yml             # SiS deployment manifest
│
├── data/                         # Source data
│   ├── Safercar_data.csv         # NHTSA SaferCar raw data (~17K vehicles)
│   └── Safercar_data_READ_ME_file.txt  # Data dictionary (128 fields)
│
├── snowflake/                    # Snowflake object DDL (exported from account)
│   ├── 01_create_table.sql       # RAW_SAFERCAR table definition
│   ├── 02_create_views.sql       # Analytical views
│   ├── 03_create_procedures.sql  # Stored procedures (4 SPs)
│   ├── 04_create_semantic_view.sql  # Cortex AI semantic view + VQRs
│   ├── 05_create_cortex_search.sql  # Cortex Search service
│   ├── 06_create_streamlit.sql      # Streamlit deployment notes + prereq check
│   └── nhtsa_semantic_model.yaml    # Cortex Analyst YAML model
│
├── sql/                          # Snowsight workspace demo scripts
│   ├── 01_setup.sql              # Environment + table + stage + SPCS setup
│   ├── 02_analytics.sql          # Create analytical views
│   └── 03_teardown.sql           # Full cleanup
```

## Snowflake Objects

| Object | Type | Description |
|--------|------|-------------|
| `NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR` | Table | 17,313 vehicles, 131 columns |
| `V_SAFETY_SUMMARY_BY_MAKE` | View | Avg star ratings by manufacturer/year |
| `V_ADVANCED_SAFETY_TECH_ADOPTION` | View | ADAS feature adoption % by year |
| `V_BIOMECHANICAL_RISK` | View | Crash injury metrics + rollover risk |
| `V_SAFETY_NOTES_SEARCHABLE` | View | Concatenated safety notes for search |
| `SAFECAR_SAFETY_RATINGS` | Semantic View | Cortex AI semantic layer with 5 VQRs |
| `NHTSA_SAFETY_NOTES_INDEX` | Cortex Search | Natural-language search over safety notes |
| `NHTSA_SAFECAR_ANALYTICS` | Streamlit App | Interactive safety analytics dashboard |
| `SP_SAFETY_RATINGS_LOOKUP` | Procedure | Look up ratings by make/model/year |
| `SP_SAFETY_SUMMARY_BY_MAKE` | Procedure | Summary stats by manufacturer |
| `SP_ADAS_TECH_ADOPTION` | Procedure | ADAS adoption trends |
| `SP_BIOMECHANICAL_RISK` | Procedure | Crash injury risk lookup |

## Setup

1. Run `snowflake/01_create_table.sql` through `05_create_cortex_search.sql` in order
2. Load `data/Safercar_data.csv` into the `RAW_SAFERCAR` table
3. Deploy the Next.js app: `cd app && snow app deploy`
4. Deploy the Streamlit app: `cd streamlit && snow streamlit deploy nhtsa_safecar_analytics -c <connection> --replace`

## Streamlit App

The `streamlit/` directory contains a Streamlit-in-Snowflake analytics app with four tabs:

| Tab | Description |
|-----|-------------|
| Safety Ratings | Filterable star-rating dashboard with KPIs and distribution charts |
| ADAS Adoption | Line charts showing safety technology adoption trends over model years |
| Crash Risk Analysis | Scatter plots and bar charts of biomechanical crash injury metrics |
| AI Safety Search | Natural-language search over crash test safety notes via Cortex Search |

Sidebar filters (manufacturer, model year range) apply across all tabs. The app connects via `st.connection("snowflake")` using native SiS embedded identity — no credentials needed.

## Data Source

[NHTSA SaferCar API](https://www.nhtsa.gov/nhtsa-safercar) — vehicle safety ratings from the National Highway Traffic Safety Administration.
