# Prompt 6 — Streamlit Dashboard

```
Build me a Streamlit-in-Snowflake app for NHTSA vehicle safety analytics. The app should connect to NHTSA_SAFECAR_DEMO.SAFETY_DATA and use plotly for all charts, Snowpark for queries, and cache query results with a 10-minute TTL.

**Sidebar:** Filters for manufacturer (multiselect from distinct MAKE values) and model year range (slider from min to max MODEL_YR). All tabs should respect these filters.

**Tab 1 — Safety Ratings:**
- KPIs across the top: total vehicles, average overall stars, percentage with 5-star rating, average frontal/side/rollover ratings
- A bar chart showing the distribution of overall star ratings (1-5)
- A bar chart comparing average ratings across categories (overall, frontal, side, rollover) with a 0-5 y-axis range
- A table of top 20 manufacturers ranked by average overall rating (minimum 5 vehicles tested), showing vehicle count and average ratings per category

**Tab 2 — ADAS Adoption:**
- Calculate the adoption percentage of 6 ADAS features by model year from RAW_SAFERCAR: Forward Collision Warning (FRNT_COLLISION_WARNING), Automatic Emergency Braking (CRASH_IMMINENT_BRAKE), Lane Departure Warning, Adaptive Cruise Control, Blind Spot Detection, and Dynamic Brake Support. A feature counts as "available" if its column is not null, not empty, and not "Not Available"
- A multiselect to pick which technologies to display (all selected by default)
- A plotly line chart with markers, one line per technology, horizontal legend below the chart
- A data table showing the yearly breakdown

**Tab 3 — Crash Risk Analysis:**
- Two side-by-side bar charts: average rollover probability by body style (Oranges color scale) and average Head Injury Criterion HIC-15 by body style (Reds color scale), top 15 body styles each
- A table of the 20 highest-risk vehicles sorted by rollover probability descending, showing make, model, year, body style, curb weight, rollover probability, rollover stars, HIC-15, and chest deflection
- Query RAW_SAFERCAR directly, casting CURB_WEIGHT to number and biomechanical columns (HIC15_DRIV, CHEST_DEFL_DRIV, SIDE_HIC_36_DRIV, RIB_DEFLECTION_DRIV) to double

**Tab 4 — AI Safety Search:**
- 5 suggested search buttons: "frontal crash test concerns for SUVs", "airbag deployment issues", "rollover safety concerns for trucks", "side impact protection", "child seat safety notes"
- A text input for custom queries and a slider for max results (5-50, default 10)
- Use the snowflake.core Root API to call the NHTSA_SAFETY_NOTES_INDEX Cortex Search service in NHTSA_SAFECAR_DEMO.SAFETY_DATA
- Return VEHICLE_ID, MAKE, MODEL, MODEL_YR, BODY_STYLE, and COMBINED_SAFETY_NOTES columns
- If manufacturers are selected in the sidebar, apply them as a Cortex Search filter using the @or/@eq syntax
- Display results as expandable sections showing "Make Model (Year) — Body Style" with the safety notes text inside
```
