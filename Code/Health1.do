* =====================================================================
* Project: INSEAD Stone Centre Pre-Doc - Health & Wealth Panel
* Task: Impact of Health Spending on Infant Mortality
* Stata Version: 13+
* =====================================================================

clear all
set more off

* =====================================================================
* 1. Setup Directories
* =====================================================================

global root_dir "C:/Users/roseg/Downloads/INSEAD_StataPastSample"
global raw_data "$root_dir/Data"
global output   "$root_dir/Output"

* =====================================================================
* 2. Import Data
* =====================================================================
* Note: Headers are imported as messy variable names (e.g., "2000 [YR2000]")

import delimited "$raw_data/world_bank_health_data.csv", clear 

* Display first few observations to understand structure
display "Dataset imported. First few observations:"
list in 1/10

* Rename variables for easier handling
* Series Name, Series Code, Country Name, Country Code, then year columns

* Note: The data structure has multiple indicator rows
* We need to reshape data to get variables in columns

* First, keep only the indicators we need:
* "Mortality rate, infant (per 1,000 live births)" - SP.DYN.IMRT.IN
* "Domestic general government health expenditure (% of GDP)" - SH.XPD.GHED.GD.ZS

keep if seriescode == "SP.DYN.IMRT.IN" | seriescode == "SH.XPD.GHED.GD.ZS"

* Reshape from wide to long format for years
reshape long yr, i(countrycode seriescode) j(year)

* Create numeric year variable
gen year_num = substr(year, 1, 4)
destring year_num, replace
drop year

* Reshape to get indicators as separate columns
rename yr value
reshape wide value, i(countrycode countryname year_num) j(seriescode) string

* Rename the indicators
rename valueSH_XPD_GHED_GD_ZS health_exp_gdp    // Health expenditure % of GDP
rename valueSP_DYN_IMRT_IN infant_mortality     // Infant mortality rate

* For the control variable (GDP per capita), we need to add it from another source
* Since it's not in the current dataset, I'll create a note
* In practice, you would import GDP per capita data and merge it

display "Variables created:"
display "infant_mortality: Mortality rate, infant (per 1,000 live births)"
display "health_exp_gdp: Domestic general government health expenditure (% of GDP)"
display "NOTE: GDP per capita needs to be added from another data source"

* Convert variables to numeric
destring health_exp_gdp infant_mortality, replace

* Generate country code variable if needed for panel structure
encode countryname, gen(country_id)

* Check for missing values
display "Missing value summary:"
summarize infant_mortality health_exp_gdp, detail

* Create a country-year identifier for panel data
gen country_year = countryname + "_" + string(year_num)
xtset country_id year_num

* ===================================================================
* REGRESSION ANALYSIS
* ===================================================================

display "=========================================="
display "Regression: Impact of Health Expenditure on Infant Mortality"
display "=========================================="

* Model 1: Simple OLS regression (cross-sectional average)
display "Model 1: OLS Regression (Basic Model)"
reg infant_mortality health_exp_gdp

* Store results
estimates store model1

* Model 2: With country fixed effects (if panel data available)
* Uncomment if using panel structure
* display "Model 2: Fixed Effects Model"
* xtreg infant_mortality health_exp_gdp, fe

* Display regression results summary
display "=========================================="
display "Regression Results Summary"
display "=========================================="
estimates table model1, b se t p

* Generate predicted values
predict pred_mortality, xb
predict residuals, residuals

* Create diagnostic plots
scatter infant_mortality health_exp_gdp || lfit infant_mortality health_exp_gdp, ///
    title("Infant Mortality vs Health Expenditure (% of GDP)") ///
    xtitle("Health Expenditure (% of GDP)") ///
    ytitle("Infant Mortality Rate (per 1,000 live births)") ///
    legend(order(1 "Actual" 2 "Fitted line"))

graph export regression_plot.png, replace

* Summary statistics table
display "=========================================="
display "Summary Statistics"
display "=========================================="
summarize infant_mortality health_exp_gdp

* End of script
display "Regression analysis complete."
