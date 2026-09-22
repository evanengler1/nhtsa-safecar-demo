# Prompt 3 — Stored Procedures

```
Create four SQL stored procedures in NHTSA_SAFECAR_DEMO.SAFETY_DATA. All should use SQL language, RETURNS TABLE(), EXECUTE AS OWNER, and have all filter parameters optional (default NULL) with LIKE pattern matching for text fields:

1. SP_SAFETY_RATINGS_LOOKUP — accepts optional make, model, year, body_style, and limit (default 25). Returns star ratings for matching vehicles from RAW_SAFERCAR ordered by year desc, make, model.

2. SP_SAFETY_SUMMARY_BY_MAKE — accepts optional make, year_start, year_end, and limit (default 50). Queries V_SAFETY_SUMMARY_BY_MAKE with those filters, ordered by make and year desc.

3. SP_ADAS_TECH_ADOPTION — accepts optional year_start, year_end, body_style, and limit (default 50). Queries V_ADVANCED_SAFETY_TECH_ADOPTION ordered by year desc and body style.

4. SP_BIOMECHANICAL_RISK — accepts optional make, model, year, body_style, and limit (default 25). Queries V_BIOMECHANICAL_RISK sorted by rollover probability descending.
```
