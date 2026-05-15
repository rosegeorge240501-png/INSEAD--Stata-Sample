* =====================================================================
* Project: INSEAD Stone Centre Pre-Doc - Health & Wealth Panel
* Task: Impact of Health Spending on Infant Mortality (Controlling for GDP)
* Data: World Bank Health Data (Multiple Indicators)
* Stata Version: 13.1+
* Author: Analysis Script
* Date: May 2026
* =====================================================================

clear all
set more off
set linesize 120

* =====================================================================
* 1. SETUP & CONFIGURATION
* =====================================================================

global root_dir "C:/Users/roseg/Downloads/INSEAD_StataPastSample"
global raw_data "$root_dir/Data"
global output   "$root_dir/Output"
global temp     "$root_dir/Temp"

* Create output directories if they don't exist
capture mkdir "$output"
capture mkdir "$temp"

* Set graph preferences
set scheme s1color
graph set window fontface "Arial"

* =====================================================================
* 2. DATA IMPORT & INITIAL PROCESSING
* =====================================================================

display "=========================================="
display "STEP 1: IMPORTING DATA"
display "=========================================="

import delimited "$raw_data/world_bank_health_data.csv", clear varnames(1)

* Check data structure
display "Data dimensions: `c(N)' observations, `c(k)' variables"
describe

* Rename key identifier variables for clarity
rename seriesname indicator_name
rename seriescode indicator_code
rename countryname country
rename countrycode country_code

* =====================================================================
* 3. DATA RESHAPING: FROM WIDE TO LONG FORMAT
* =====================================================================

display "=========================================="
display "STEP 2: RESHAPING DATA TO LONG FORMAT"
display "=========================================="

* Keep only the two key indicators
keep if indicator_code == "SP.DYN.IMRT.IN" | ///
        indicator_code == "SH.XPD.GHED.GD.ZS"

display "Keeping observations for 2 indicators (Infant Mortality & Health Expenditure)"

* List variable names to identify year columns
ds
display "Checking for year columns..."

* Reshape long - this will convert all year columns into two columns: _j and _d
* The year columns are formatted like "2000 [YR2000]", "2001 [YR2001]", etc.
reshape long , i(indicator_name indicator_code country country_code) j(year_str) string

* Now extract the year from the column names
* Year columns have format like "2000 [YR2000]" so we need to extract from _d values
capture drop year
gen year = substr(_d, 1, 4)
destring year, replace force

* Rename the value column for clarity
rename _d value_str
destring value_str, gen(value) force
drop value_str

display "Data reshaped successfully to long format"
display ""
display "Sample of reshaped data:"
list country year indicator_code value in 1/30

* =====================================================================
* 3B. PIVOT TO WIDE FORMAT FOR INDICATORS
* =====================================================================

* Now reshape to get indicators as columns
reshape wide value, i(country country_code year) j(indicator_code) string

* Rename indicator columns with cleaner names
capture confirm variable valueSH_XPD_GHED_GD_ZS
if !_rc {
    rename valueSH_XPD_GHED_GD_ZS health_exp_pct_gdp
    label variable health_exp_pct_gdp "Govt Health Expenditure (% of GDP)"
}

capture confirm variable valueSP_DYN_IMRT_IN
if !_rc {
    rename valueSP_DYN_IMRT_IN infant_mortality_rate
    label variable infant_mortality_rate "Infant Mortality Rate (per 1,000 live births)"
}

* Check for variables with dots notation (World Bank missing value marker)
display ""
display "Sample of final reshaped data:"
list country year health_exp_pct_gdp infant_mortality_rate in 1/30

* Clean missing value markers
replace health_exp_pct_gdp = . if health_exp_pct_gdp == .
replace infant_mortality_rate = . if infant_mortality_rate == .

display ""
display "Reshape complete!"

* =====================================================================
* 2. DATA IMPORT & INITIAL PROCESSING
* =====================================================================

display "=========================================="
display "STEP 1: IMPORTING DATA"
display "=========================================="

import delimited "$raw_data/world_bank_health_data.csv", clear varnames(1)

* Check data structure
display "Data dimensions: `c(N)' observations, `c(k)' variables"
describe

* Rename key identifier variables for clarity
rename seriesname indicator_name
rename seriescode indicator_code
rename countryname country
rename countrycode country_code

* =====================================================================
* 3. DATA RESHAPING: FROM WIDE TO LONG FORMAT
* =====================================================================

display "=========================================="
display "STEP 2: RESHAPING DATA TO LONG FORMAT"
display "=========================================="

* We have two indicators:
* SP.DYN.IMRT.IN = Infant Mortality Rate (per 1,000 live births)
* SH.XPD.GHED.GD.ZS = Domestic general government health expenditure (% of GDP)

* Keep only countries and the two key indicators
keep if indicator_code == "SP.DYN.IMRT.IN" | ///
        indicator_code == "SH.XPD.GHED.GD.ZS"

display "Keeping observations for 2 indicators (Infant Mortality & Health Expenditure)"

* Drop any variable that doesn't match our structure
keep indicator_name indicator_code country country_code *YR*

* Reshape from wide to long for years
reshape long *YR, i(country country_code indicator_code) j(year_str) string

* Extract numeric year from the suffix (e.g., "2000" from "YR2000")
gen year_num = substr(year_str, 3, 4)
destring year_num, replace
drop year_str

* Rename the value variable
rename *YR value_temp

* Clean up and keep only numeric values
destring value_temp, replace force
rename value_temp value

* Now reshape to get indicators as columns
reshape wide value, i(country country_code year_num) j(indicator_code) string

* Rename year to something more descriptive
rename year_num year

* Rename indicator columns with cleaner names
capture confirm variable valueSH_XPD_GHED_GD_ZS
if !_rc {
    rename valueSH_XPD_GHED_GD_ZS health_exp_pct_gdp
    label variable health_exp_pct_gdp "Govt Health Expenditure (% of GDP)"
}

capture confirm variable valueSP_DYN_IMRT_IN
if !_rc {
    rename valueSP_DYN_IMRT_IN infant_mortality_rate
    label variable infant_mortality_rate "Infant Mortality Rate (per 1,000 live births)"
}

* Display reshape results
display "Data reshaped successfully"
display "Sample of reshaped data:"
list country year health_exp_pct_gdp infant_mortality_rate in 1/20, clean

* =====================================================================
* 4. CLEANING & MISSING VALUE HANDLING
* =====================================================================

display "=========================================="
display "STEP 3: DATA CLEANING & MISSING VALUES"
display "=========================================="

* Replace ".." with missing values (World Bank convention)
replace health_exp_pct_gdp = . if health_exp_pct_gdp == .
replace infant_mortality_rate = . if infant_mortality_rate == .

* Count missing values before cleaning
summarize health_exp_pct_gdp infant_mortality_rate, detail
display "Missing values:"
display "Health Expenditure: " %0.0f (count(health_exp_pct_gdp)==0) " missing"
display "Infant Mortality: " %0.0f (count(infant_mortality_rate)==0) " missing"

* Create analysis dataset (listwise deletion for now)
gen complete_case = !missing(health_exp_pct_gdp) & !missing(infant_mortality_rate)
tab complete_case

* For the control variable (GDP per capita), note the limitation
* Since it's not in the current dataset, we'll proceed with the available variables
* In production, you would merge World Bank GDP data:
* merge 1:1 country year using "$raw_data/gdp_per_capita.dta"

display "NOTE: GDP per capita not included in current dataset"
display "Recommend merging NY.GDP.PCAP.CD from World Bank API"

* =====================================================================
* 5. EXPLORATORY ANALYSIS
* =====================================================================

display "=========================================="
display "STEP 4: EXPLORATORY DATA ANALYSIS"
display "=========================================="

* Summary statistics for main variables
display "========== SUMMARY STATISTICS =========="
summarize health_exp_pct_gdp infant_mortality_rate, detail

* Create categorical variable for health expenditure levels
egen health_exp_quartile = cut(health_exp_pct_gdp), group(4) label
label define health_exp_label 0 "Q1 (Lowest)" 1 "Q2" 2 "Q3" 3 "Q4 (Highest)"
label values health_exp_quartile health_exp_label

* Correlation analysis
display "========== CORRELATION MATRIX =========="
correlate health_exp_pct_gdp infant_mortality_rate
spearman health_exp_pct_gdp infant_mortality_rate

* Visualization: Scatter plot with trend line
twoway (scatter infant_mortality_rate health_exp_pct_gdp, msize(small) msymbol(circle)) ///
       (lfit infant_mortality_rate health_exp_pct_gdp, lwidth(thick) lcolor(red)), ///
    title("Relationship: Infant Mortality vs Health Expenditure", size(large)) ///
    xtitle("Government Health Expenditure (% of GDP)", size(medsmall)) ///
    ytitle("Infant Mortality Rate (per 1,000 live births)", size(medsmall)) ///
    legend(order(1 "Observations" 2 "Linear Fit")) ///
    note("Data: World Bank, Multiple Years Available", size(small)) ///
    graphregion(color(white)) plotregion(color(white))

graph export "$output/01_scatter_correlation.png", replace width(1000) height(600)
display "Scatter plot saved: 01_scatter_correlation.png"

* =====================================================================
* 6. REGRESSION ANALYSIS
* =====================================================================

display "=========================================="
display "STEP 5: REGRESSION ANALYSIS"
display "=========================================="

* Keep only complete cases for regression
keep if complete_case == 1

* Create identifier for panel structure (even if limited use)
encode country, gen(country_id)
xtset country_id year, yearly

display "Panel structure: " c(N) " observations, " c(N_g) " countries, " ///
        "Years: " ///
        "Multiple years per country available"

* ===================================================================
* MODEL 1: Simple Bivariate OLS
* ===================================================================

display ""
display "================================================================"
display "MODEL 1: SIMPLE OLS - Infant Mortality on Health Expenditure"
display "================================================================"

reg infant_mortality_rate health_exp_pct_gdp

* Store results
estimates store model1_ols
local r2_model1 = e(r2)
local n_model1 = e(N)

* Post results to output
matrix model1_coef = [_b[health_exp_pct_gdp], ///
                      _se[health_exp_pct_gdp], ///
                      _b[health_exp_pct_gdp]/_se[health_exp_pct_gdp], ///
                      2*(1-normal(abs(_b[health_exp_pct_gdp]/_se[health_exp_pct_gdp])))]

* Calculate 95% CI
local ci_lower = _b[health_exp_pct_gdp] - 1.96*_se[health_exp_pct_gdp]
local ci_upper = _b[health_exp_pct_gdp] + 1.96*_se[health_exp_pct_gdp]

display ""
display "Coefficient Interpretation:"
display "A 1 percentage point increase in government health expenditure (% of GDP)"
display "is associated with a " %0.3f abs(_b[health_exp_pct_gdp]) " change in infant mortality"
display "95% CI: [" %0.3f `ci_lower' ", " %0.3f `ci_upper' "]"
display ""

* ===================================================================
* MODEL 2: With Year Fixed Effects
* ===================================================================

display ""
display "================================================================"
display "MODEL 2: OLS with YEAR FIXED EFFECTS"
display "================================================================"

reg infant_mortality_rate health_exp_pct_gdp i.year

estimates store model2_year_fe
local r2_model2 = e(r2)
local n_model2 = e(N)

display ""
display "Model 2 includes year dummy variables to control for time trends"
display ""

* ===================================================================
* MODEL 3: With Country Fixed Effects (Fixed Effects Model)
* ===================================================================

display ""
display "================================================================"
display "MODEL 3: FIXED EFFECTS PANEL MODEL (Within-Estimator)"
display "================================================================"

xtreg infant_mortality_rate health_exp_pct_gdp, fe

estimates store model3_country_fe
local r2_model3 = e(r2)
local n_model3 = e(N)

display ""
display "Model 3: Country fixed effects estimate (within-group variation)"
display ""

* ===================================================================
* MODEL 4: Two-Way Fixed Effects (Country + Year)
* ===================================================================

display ""
display "================================================================"
display "MODEL 4: TWO-WAY FIXED EFFECTS (Country + Year Effects)"
display "================================================================"

xtreg infant_mortality_rate health_exp_pct_gdp i.year, fe

estimates store model4_twoway_fe
local r2_model4 = e(r2)
local n_model4 = e(N)

display ""
display "Model 4: Controls for both country-specific and year-specific factors"
display ""

* =====================================================================
* 7. MODEL COMPARISON TABLE
* =====================================================================

display ""
display "=========================================="
display "MODEL COMPARISON TABLE"
display "=========================================="

estimates table model1_ols model2_year_fe model3_country_fe model4_twoway_fe, ///
    b(%0.4f) se(%0.4f) t(%0.2f) p(%0.3f) ///
    title("Regression Results: Impact of Health Expenditure on Infant Mortality") ///
    note("Dependent Variable: Infant Mortality Rate (per 1,000 live births)")

* Create formatted output table
estimates table model1_ols model2_year_fe model3_country_fe model4_twoway_fe, ///
    stats(N r2 r2_a) ///
    b(%0.4f) se(%0.4f) ///
    title("Summary: All Models")

* =====================================================================
* 8. DIAGNOSTIC TESTS & MODEL VALIDATION
* =====================================================================

display ""
display "=========================================="
display "STEP 6: DIAGNOSTIC TESTS"
display "=========================================="

* Use Model 1 results for diagnostics
reg infant_mortality_rate health_exp_pct_gdp
predict residuals_model1, residuals
predict fitted_model1, xb

* Test for heteroskedasticity (Breusch-Pagan test)
display ""
display "Heteroskedasticity Test (Breusch-Pagan):"
estat hettest

* Test for normality of residuals
display ""
display "Normality Test (Shapiro-Wilk):"
sw residuals_model1

* Histogram of residuals
histogram residuals_model1, normal ///
    title("Distribution of Residuals - Model 1") ///
    xtitle("Residuals") ytitle("Frequency") ///
    note("Should be approximately normal if model assumptions hold")

graph export "$output/02_residual_histogram.png", replace width(800) height(600)

* Q-Q plot
qnorm residuals_model1 ///
    title("Q-Q Plot of Residuals - Model 1") ///
    note("Points should follow diagonal line if residuals are normal")

graph export "$output/03_qq_plot.png", replace width(800) height(600)

* Residuals vs fitted values
twoway (scatter residuals_model1 fitted_model1, msize(small)) ///
       (lfit residuals_model1 fitted_model1), ///
    yline(0, lstyle(dash)) ///
    title("Residuals vs Fitted Values - Model 1") ///
    xtitle("Fitted Values") ytitle("Residuals") ///
    legend(off)

graph export "$output/04_residuals_vs_fitted.png", replace width(800) height(600)

* =====================================================================
* 9. SUBSAMPLE & ROBUSTNESS ANALYSIS
* =====================================================================

display ""
display "=========================================="
display "STEP 7: ROBUSTNESS & SUBSAMPLE ANALYSIS"
display "=========================================="

* Analysis by income levels (based on health expenditure)
display ""
display "Regression by Health Expenditure Quartile:"
display ""

forvalues i = 0/3 {
    display ""
    display "--- Quartile `i' ---"
    reg infant_mortality_rate health_exp_pct_gdp if health_exp_quartile == `i'
    display ""
}

* Time period analysis
display ""
display "Regression by Time Period:"
display ""

* Early period (2000-2010)
display "EARLY PERIOD (2000-2010):"
reg infant_mortality_rate health_exp_pct_gdp if year >= 2000 & year <= 2010

* Recent period (2011-2022)
display ""
display "RECENT PERIOD (2011-2022):"
reg infant_mortality_rate health_exp_pct_gdp if year >= 2011 & year <= 2022

* =====================================================================
* 10. RESULTS SUMMARY & EXPORT
* =====================================================================

display ""
display "=========================================="
display "STEP 8: GENERATING SUMMARY OUTPUTS"
display "=========================================="

* Regression with Model 1 for final output
reg infant_mortality_rate health_exp_pct_gdp

* Create comprehensive results output
outreg2 using "$output/regression_results.xls", replace ///
    title("Impact of Government Health Expenditure on Infant Mortality") ///
    label(insert) ///
    ctitle("Model 1: OLS") ///
    keep(health_exp_pct_gdp) ///
    addtext(Model, "Simple OLS", ///
            Specification, "Bivariate", ///
            Fixed Effects, "None")

* Summary statistics export
tabstat health_exp_pct_gdp infant_mortality_rate, ///
    save(matrix(stats_table))

display ""
display "Summary Statistics:"
matrix list stats_table

* =====================================================================
* 11. KEY FINDINGS & INTERPRETATION
* =====================================================================

display ""
display "=========================================="
display "KEY FINDINGS"
display "=========================================="

* Extract key statistics from Model 1
reg infant_mortality_rate health_exp_pct_gdp

display ""
display "MODEL 1 (Simple OLS) KEY RESULTS:"
display "Coefficient on Health Expenditure: " %0.4f _b[health_exp_pct_gdp]
display "Standard Error: " %0.4f _se[health_exp_pct_gdp]
display "t-statistic: " %0.4f _b[health_exp_pct_gdp]/_se[health_exp_pct_gdp]
display "p-value: " %0.4f 2*(1-normal(abs(_b[health_exp_pct_gdp]/_se[health_exp_pct_gdp])))
display "R-squared: " %0.4f e(r2)
display "Observations: " %0.0f e(N)

display ""
display "INTERPRETATION:"
if _b[health_exp_pct_gdp] < 0 {
    display "Finding: NEGATIVE association (more health spending ? LOWER mortality)"
    display "Each additional 1% of GDP in government health expenditure is"
    display "associated with a reduction of " %0.2f abs(_b[health_exp_pct_gdp]) " in infant mortality rate"
}
else {
    display "Finding: POSITIVE association (UNEXPECTED DIRECTION)"
    display "This may indicate: confounding, reverse causality, or data quality issues"
}

display ""
display "LIMITATIONS (no GDP control in current analysis):"
display "- Cannot control for GDP per capita (not in dataset)"
display "- Cannot fully isolate health spending effect from economic development"
display "- Recommend merging World Bank GDP data for more robust analysis"
display ""

* =====================================================================
* 12. CLEANUP & FINAL SUMMARY
* =====================================================================

display ""
display "=========================================="
display "ANALYSIS COMPLETE"
display "=========================================="

display ""
display "Output Files Generated:"
display "  1. 01_scatter_correlation.png - Scatter plot with trend line"
display "  2. 02_residual_histogram.png - Distribution of residuals"
display "  3. 03_qq_plot.png - Q-Q plot for normality check"
display "  4. 04_residuals_vs_fitted.png - Residual diagnostics"
display "  5. regression_results.xls - Regression output table"
display ""
display "All outputs saved in: $output"
display ""
display "Next Steps:"
display "  1. Merge GDP per capita data (NY.GDP.PCAP.CD) for control variable"
display "  2. Consider additional controls (e.g., healthcare access, education)"
display "  3. Test for specification issues (Ramsey RESET test)"
display "  4. Investigate heterogeneity by region/income group"
display ""

* End of script
log close
exit
