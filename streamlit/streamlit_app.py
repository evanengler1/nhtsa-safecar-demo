import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import json
from snowflake.core import Root

st.set_page_config(page_title="NHTSA SafeCar Analytics", page_icon="🚗", layout="wide")

conn = st.connection("snowflake")
session = conn.session()

DATABASE = "NHTSA_SAFECAR_DEMO"
SCHEMA = "SAFETY_DATA"


@st.cache_data(ttl=600)
def run_query(sql):
    return session.sql(sql).to_pandas()


@st.cache_data(ttl=600)
def get_makes():
    df = run_query(
        f"SELECT DISTINCT MAKE FROM {DATABASE}.{SCHEMA}.RAW_SAFERCAR "
        "WHERE MAKE IS NOT NULL ORDER BY MAKE"
    )
    return df["MAKE"].tolist()


@st.cache_data(ttl=600)
def get_year_range():
    df = run_query(
        f"SELECT MIN(MODEL_YR)::INT AS MIN_YR, MAX(MODEL_YR)::INT AS MAX_YR "
        f"FROM {DATABASE}.{SCHEMA}.RAW_SAFERCAR WHERE MODEL_YR IS NOT NULL"
    )
    return int(df["MIN_YR"].iloc[0]), int(df["MAX_YR"].iloc[0])


# ---------------------------------------------------------------------------
# Sidebar filters
# ---------------------------------------------------------------------------
with st.sidebar:
    st.title("NHTSA SafeCar")
    st.caption("Vehicle Safety Analytics")
    st.divider()

    all_makes = get_makes()
    min_yr, max_yr = get_year_range()

    selected_makes = st.multiselect("Manufacturer", all_makes, default=[])
    year_range = st.slider("Model Year", min_yr, max_yr, (2015, max_yr))

    make_filter = ""
    if selected_makes:
        quoted = ", ".join(f"'{m}'" for m in selected_makes)
        make_filter = f"AND MAKE IN ({quoted})"
    year_filter = f"AND MODEL_YR BETWEEN {year_range[0]} AND {year_range[1]}"


# ---------------------------------------------------------------------------
# Tabs
# ---------------------------------------------------------------------------
tab1, tab2, tab3, tab4 = st.tabs(
    ["Safety Ratings", "ADAS Adoption", "Crash Risk Analysis", "AI Safety Search"]
)

# ===========================================================================
# Tab 1 — Safety Ratings Explorer
# ===========================================================================
with tab1:
    st.header("Safety Ratings Explorer")

    kpi_sql = f"""
    SELECT
        COUNT(*) AS TOTAL_VEHICLES,
        ROUND(AVG(TRY_TO_NUMBER(OVERALL_STARS)), 2) AS AVG_STARS,
        ROUND(100.0 * COUNT_IF(OVERALL_STARS = '5') / NULLIF(COUNT(*), 0), 1) AS PCT_FIVE_STAR,
        ROUND(AVG(TRY_TO_NUMBER(OVERALL_FRNT_STARS)), 2) AS AVG_FRONTAL,
        ROUND(AVG(TRY_TO_NUMBER(OVERALL_SIDE_STARS)), 2) AS AVG_SIDE,
        ROUND(AVG(TRY_TO_NUMBER(ROLLOVER_STARS)), 2) AS AVG_ROLLOVER
    FROM {DATABASE}.{SCHEMA}.RAW_SAFERCAR
    WHERE OVERALL_STARS IS NOT NULL {make_filter} {year_filter}
    """
    kpis = run_query(kpi_sql)

    c1, c2, c3, c4, c5, c6 = st.columns(6)
    c1.metric("Total Vehicles", f"{int(kpis['TOTAL_VEHICLES'].iloc[0]):,}")
    c2.metric("Avg Overall", f"{kpis['AVG_STARS'].iloc[0]:.2f} ★")
    c3.metric("5-Star %", f"{kpis['PCT_FIVE_STAR'].iloc[0]:.1f}%")
    c4.metric("Avg Frontal", f"{kpis['AVG_FRONTAL'].iloc[0]:.2f} ★")
    c5.metric("Avg Side", f"{kpis['AVG_SIDE'].iloc[0]:.2f} ★")
    c6.metric("Avg Rollover", f"{kpis['AVG_ROLLOVER'].iloc[0]:.2f} ★")

    st.divider()
    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Star Rating Distribution")
        dist_sql = f"""
        SELECT OVERALL_STARS AS STARS, COUNT(*) AS COUNT
        FROM {DATABASE}.{SCHEMA}.RAW_SAFERCAR
        WHERE OVERALL_STARS IS NOT NULL {make_filter} {year_filter}
        GROUP BY OVERALL_STARS ORDER BY OVERALL_STARS
        """
        dist_df = run_query(dist_sql)
        fig = px.bar(
            dist_df, x="STARS", y="COUNT", color="STARS",
            labels={"STARS": "Star Rating", "COUNT": "Vehicles"},
            color_discrete_sequence=px.colors.sequential.Tealgrn,
        )
        fig.update_layout(showlegend=False, height=350)
        st.plotly_chart(fig, use_container_width=True)

    with col_right:
        st.subheader("Avg Rating by Category")
        cat_data = pd.DataFrame({
            "Category": ["Overall", "Frontal", "Side", "Rollover"],
            "Rating": [
                float(kpis["AVG_STARS"].iloc[0]),
                float(kpis["AVG_FRONTAL"].iloc[0]),
                float(kpis["AVG_SIDE"].iloc[0]),
                float(kpis["AVG_ROLLOVER"].iloc[0]),
            ],
        })
        fig2 = px.bar(
            cat_data, x="Category", y="Rating", color="Category",
            color_discrete_sequence=["#29B5E8", "#71D4F5", "#0D3B66", "#48BF84"],
            range_y=[0, 5],
        )
        fig2.update_layout(showlegend=False, height=350)
        st.plotly_chart(fig2, use_container_width=True)

    st.subheader("Top Manufacturers by Average Rating")
    top_sql = f"""
    SELECT MAKE,
           COUNT(*) AS VEHICLES,
           ROUND(AVG(TRY_TO_NUMBER(OVERALL_STARS)), 2) AS AVG_OVERALL,
           ROUND(AVG(TRY_TO_NUMBER(OVERALL_FRNT_STARS)), 2) AS AVG_FRONTAL,
           ROUND(AVG(TRY_TO_NUMBER(OVERALL_SIDE_STARS)), 2) AS AVG_SIDE,
           ROUND(AVG(TRY_TO_NUMBER(ROLLOVER_STARS)), 2) AS AVG_ROLLOVER
    FROM {DATABASE}.{SCHEMA}.RAW_SAFERCAR
    WHERE OVERALL_STARS IS NOT NULL {make_filter} {year_filter}
    GROUP BY MAKE
    HAVING COUNT(*) >= 5
    ORDER BY AVG_OVERALL DESC
    LIMIT 20
    """
    st.dataframe(run_query(top_sql), use_container_width=True, hide_index=True)


# ===========================================================================
# Tab 2 — ADAS Feature Adoption
# ===========================================================================
with tab2:
    st.header("ADAS Feature Adoption Over Time")

    adas_sql = f"""
    SELECT
        MODEL_YR,
        COUNT(*) AS TOTAL,
        ROUND(100.0 * COUNT_IF(FRNT_COLLISION_WARNING IS NOT NULL
            AND TRIM(FRNT_COLLISION_WARNING) != ''
            AND UPPER(TRIM(FRNT_COLLISION_WARNING)) != 'NOT AVAILABLE')
            / NULLIF(COUNT(*), 0), 1) AS FCW,
        ROUND(100.0 * COUNT_IF(CRASH_IMMINENT_BRAKE IS NOT NULL
            AND TRIM(CRASH_IMMINENT_BRAKE) != ''
            AND UPPER(TRIM(CRASH_IMMINENT_BRAKE)) != 'NOT AVAILABLE')
            / NULLIF(COUNT(*), 0), 1) AS AEB,
        ROUND(100.0 * COUNT_IF(LANE_DEPARTURE_WARNING IS NOT NULL
            AND TRIM(LANE_DEPARTURE_WARNING) != ''
            AND UPPER(TRIM(LANE_DEPARTURE_WARNING)) != 'NOT AVAILABLE')
            / NULLIF(COUNT(*), 0), 1) AS LDW,
        ROUND(100.0 * COUNT_IF(ADAPTIVE_CRUISE_CONTROL IS NOT NULL
            AND TRIM(ADAPTIVE_CRUISE_CONTROL) != ''
            AND UPPER(TRIM(ADAPTIVE_CRUISE_CONTROL)) != 'NOT AVAILABLE')
            / NULLIF(COUNT(*), 0), 1) AS ACC,
        ROUND(100.0 * COUNT_IF(BLIND_SPOT_DETECTION IS NOT NULL
            AND TRIM(BLIND_SPOT_DETECTION) != ''
            AND UPPER(TRIM(BLIND_SPOT_DETECTION)) != 'NOT AVAILABLE')
            / NULLIF(COUNT(*), 0), 1) AS BSD,
        ROUND(100.0 * COUNT_IF(DYNAMIC_BRAKE_SUPPORT IS NOT NULL
            AND TRIM(DYNAMIC_BRAKE_SUPPORT) != ''
            AND UPPER(TRIM(DYNAMIC_BRAKE_SUPPORT)) != 'NOT AVAILABLE')
            / NULLIF(COUNT(*), 0), 1) AS DBS
    FROM {DATABASE}.{SCHEMA}.RAW_SAFERCAR
    WHERE MODEL_YR IS NOT NULL {make_filter} {year_filter}
    GROUP BY MODEL_YR
    ORDER BY MODEL_YR
    """
    adas_df = run_query(adas_sql)

    tech_cols = {
        "FCW": "Forward Collision Warning",
        "AEB": "Automatic Emergency Braking",
        "LDW": "Lane Departure Warning",
        "ACC": "Adaptive Cruise Control",
        "BSD": "Blind Spot Detection",
        "DBS": "Dynamic Brake Support",
    }

    selected_tech = st.multiselect(
        "Select Technologies",
        options=list(tech_cols.keys()),
        default=list(tech_cols.keys()),
        format_func=lambda x: tech_cols[x],
    )

    if selected_tech:
        melted = adas_df.melt(
            id_vars=["MODEL_YR"],
            value_vars=selected_tech,
            var_name="Technology",
            value_name="Adoption %",
        )
        melted["Technology"] = melted["Technology"].map(tech_cols)
        fig3 = px.line(
            melted,
            x="MODEL_YR",
            y="Adoption %",
            color="Technology",
            markers=True,
            labels={"MODEL_YR": "Model Year", "Adoption %": "Adoption Rate (%)"},
        )
        fig3.update_layout(height=450, legend=dict(orientation="h", y=-0.2))
        st.plotly_chart(fig3, use_container_width=True)

    st.subheader("Yearly Breakdown")
    display_df = adas_df.copy()
    display_df.columns = ["Year", "Total Vehicles"] + [tech_cols[c] for c in tech_cols]
    st.dataframe(display_df, use_container_width=True, hide_index=True)


# ===========================================================================
# Tab 3 — Crash Risk Analysis
# ===========================================================================
with tab3:
    st.header("Biomechanical Crash Risk Analysis")

    risk_sql = f"""
    SELECT
        MAKE, MODEL, MODEL_YR, BODY_STYLE, DRIVE_TRAIN,
        TRY_TO_NUMBER(CURB_WEIGHT) AS CURB_WEIGHT_LBS,
        ROLLOVER_POSSIBILITY,
        TRY_TO_NUMBER(ROLLOVER_STARS) AS ROLLOVER_STARS,
        TRY_TO_DOUBLE(HIC15_DRIV) AS HIC15_DRIVER,
        TRY_TO_DOUBLE(CHEST_DEFL_DRIV) AS CHEST_DEFL_DRIVER,
        TRY_TO_DOUBLE(SIDE_HIC_36_DRIV) AS SIDE_HIC_DRIVER,
        TRY_TO_DOUBLE(RIB_DEFLECTION_DRIV) AS RIB_DEFLECTION_DRIVER
    FROM {DATABASE}.{SCHEMA}.RAW_SAFERCAR
    WHERE TRY_TO_NUMBER(CURB_WEIGHT) IS NOT NULL {make_filter} {year_filter}
    """
    risk_df = run_query(risk_sql)

    col_a, col_b = st.columns(2)

    with col_a:
        st.subheader("Curb Weight vs Rollover Probability")
        scatter_df = risk_df.dropna(subset=["CURB_WEIGHT_LBS", "ROLLOVER_POSSIBILITY"])
        if not scatter_df.empty:
            fig4 = px.scatter(
                scatter_df,
                x="CURB_WEIGHT_LBS",
                y="ROLLOVER_POSSIBILITY",
                color="ROLLOVER_STARS",
                hover_data=["MAKE", "MODEL", "MODEL_YR"],
                labels={
                    "CURB_WEIGHT_LBS": "Curb Weight (lbs)",
                    "ROLLOVER_POSSIBILITY": "Rollover Probability (%)",
                    "ROLLOVER_STARS": "Rollover Stars",
                },
                color_continuous_scale="RdYlGn_r",
            )
            fig4.update_layout(height=400)
            st.plotly_chart(fig4, use_container_width=True)
        else:
            st.info("No data available for the selected filters.")

    with col_b:
        st.subheader("Avg Head Injury Criterion by Body Style")
        hic_df = risk_df.dropna(subset=["HIC15_DRIVER"])
        if not hic_df.empty:
            hic_agg = (
                hic_df.groupby("BODY_STYLE")["HIC15_DRIVER"]
                .mean()
                .reset_index()
                .sort_values("HIC15_DRIVER", ascending=False)
                .head(15)
            )
            fig5 = px.bar(
                hic_agg,
                x="BODY_STYLE",
                y="HIC15_DRIVER",
                labels={"BODY_STYLE": "Body Style", "HIC15_DRIVER": "Avg HIC-15"},
                color="HIC15_DRIVER",
                color_continuous_scale="Reds",
            )
            fig5.update_layout(height=400, xaxis_tickangle=-45)
            st.plotly_chart(fig5, use_container_width=True)
        else:
            st.info("No HIC data available for the selected filters.")

    st.subheader("Highest Risk Vehicles")
    high_risk = risk_df.dropna(subset=["ROLLOVER_POSSIBILITY"]).sort_values(
        "ROLLOVER_POSSIBILITY", ascending=False
    ).head(20)
    if not high_risk.empty:
        display_cols = [
            "MAKE", "MODEL", "MODEL_YR", "BODY_STYLE", "CURB_WEIGHT_LBS",
            "ROLLOVER_POSSIBILITY", "ROLLOVER_STARS", "HIC15_DRIVER", "CHEST_DEFL_DRIVER",
        ]
        st.dataframe(
            high_risk[display_cols].reset_index(drop=True),
            use_container_width=True,
            hide_index=True,
        )
    else:
        st.info("No rollover data available for the selected filters.")


# ===========================================================================
# Tab 4 — AI Safety Search (Cortex Search)
# ===========================================================================
with tab4:
    st.header("AI Safety Notes Search")
    st.caption(
        "Search across crash test safety notes, footnotes, and safety concerns "
        "using Cortex Search."
    )

    suggested = [
        "frontal crash test concerns for SUVs",
        "airbag deployment issues",
        "rollover safety concerns for trucks",
        "side impact protection",
        "child seat safety notes",
    ]

    st.markdown("**Suggested searches:**")
    suggestion_cols = st.columns(len(suggested))
    for i, s in enumerate(suggested):
        if suggestion_cols[i].button(s, key=f"suggest_{i}"):
            st.session_state["search_query"] = s

    query = st.text_input(
        "Search safety notes",
        value=st.session_state.get("search_query", ""),
        placeholder="e.g., 'head injury concerns in sedans'",
    )

    if query:
        search_limit = st.slider("Max results", 5, 50, 10)

        filter_obj = {}
        if selected_makes:
            filter_obj["@or"] = [{"@eq": {"MAKE": m}} for m in selected_makes]

        try:
            root = Root(session)
            search_service = (
                root.databases[DATABASE]
                .schemas[SCHEMA]
                .cortex_search_services["NHTSA_SAFETY_NOTES_INDEX"]
            )

            resp = search_service.search(
                query=query,
                columns=["VEHICLE_ID", "MAKE", "MODEL", "MODEL_YR", "BODY_STYLE", "COMBINED_SAFETY_NOTES"],
                filter=filter_obj if filter_obj else None,
                limit=search_limit,
            )

            results = resp.results
            if not results:
                st.warning("No results found. Try a different search term.")
            else:
                st.success(f"Found {len(results)} results")
                for row in results:
                    yr = row.get("MODEL_YR", "")
                    yr_str = str(int(yr)) if yr else ""
                    with st.expander(
                        f"{row.get('MAKE', '')} {row.get('MODEL', '')} ({yr_str}) — {row.get('BODY_STYLE', '')}"
                    ):
                        st.markdown(row.get("COMBINED_SAFETY_NOTES", ""))
        except Exception as e:
            st.error(f"Search error: {e}")
    else:
        st.info("Enter a search query above or click a suggested search to get started.")
