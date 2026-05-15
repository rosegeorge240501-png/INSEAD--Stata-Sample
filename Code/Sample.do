* ----------------------------------------------------------------------
* Project: INSEAD Stone Centre Pre-Doc Stata Sample
* Topic: Impact of Health Spending on Infant Mortality 
* ----------------------------------------------------------------------

clear all
set more off

* 1. Setup Directories
global root_dir "C:/Users/roseg/Downloads/INSEAD_StataPastSample"
global raw_data "$root_dir/Data"
global output   "$root_dir/Output"

* 2. Import the Data
import delimited "$raw_data/clean_panel_data.csv", clear

* 3. Prepare for Panel Regression
* Drop rows missing an ID, encode the string ID to numeric, and set the panel
drop if missing(iso3)
encode iso3, gen(country_id)
xtset country_id year

* Create log-transformed variables 
gen ln_gdp = ln(gdp_pc)
gen ln_mortality = ln(infant_mortality)

* 4. The TWFE Regression
* Research Question: Does increased health spending reduce infant mortality?
eststo model1: xtreg ln_mortality health_spend ln_gdp i.year, fe vce(cluster country_id)

* 5. Export Table
esttab model1 using "$output/Health_Results.rtf", replace ///
    label b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    title("Table 1: Public Health Spend and Infant Mortality")

