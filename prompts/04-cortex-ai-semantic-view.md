# Prompt 4 — Cortex AI Semantic View

```
Create a Cortex AI semantic view called SAFECAR_SAFETY_RATINGS over the RAW_SAFERCAR table in NHTSA_SAFECAR_DEMO.SAFETY_DATA. It should enable natural language querying of vehicle safety data.

Include these elements:
- Facts: curb weight, min/max gross weight, rollover possibility, static stability factor, HIC15 driver, chest deflection driver, left/right femur driver loads
- Dimensions: make (synonyms: manufacturer, brand), model, model year (synonym: year), body style (synonym: body type), vehicle type, drive train (synonym: drivetrain), vehicle class, plus all the star rating columns (overall, frontal, side, rollover, driver/passenger breakdowns) and ADAS feature columns (blind spot, ACC, ABS, FCW, LDW, AEB/crash imminent brake, dynamic brake support, ESC, backup camera, daytime running lights)
- Metrics: vehicle count, average overall stars, average rollover probability, average stability factor
- Add descriptive comments on each field
- Add synonyms where natural language users might use alternate terms (e.g., "safety rating" for overall_stars, "AEB" for crash imminent brake)

Include these verified queries:
1. "Which vehicles have a 5-star overall safety rating?" (onboarding)
2. "What vehicles have the highest rollover risk?" (onboarding)
3. "What is the average safety rating by manufacturer?" (onboarding)
4. "How has the adoption of safety features changed over model years?"
5. "What are the safest SUVs?"
```
