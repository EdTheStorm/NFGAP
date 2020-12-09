
clear all
***Version festlegen
version 12
***Bildschirmausgabe steuern
set more off
set logtype text
set linesize 255



** Makros für Pfade
global datenpfad "C:\Users\estorm\Google Drive\BIBB data\BIBB-Erwerbstaetige_1-6\BIBB_ALLE\"
global outputpfad "C:\Users\estorm\Google Drive\BIBB data\Log Files\BIBB_log\"

*** Makros für Datei- und Outputnamen

global bibb_all BIBB_ALL.dta
global bibb_all_adj BIBB_ALL_ADJ.dta
global bibb_all_adj_task BIBB_ALL_ADJ_TASK.dta

global bibb_all_data_final BIBB_ALL_DATA_FINAL.dta
global BIBB_Decomp_Full BIBB_Decomp_Full.dta

global key_kldb_88_92 key_kldb_88_92.dta
global key_kldb_88_92_2st key_kldb_88_92_2st.dta
global key_kldb_88_92_3st key_kldb_88_92_3st.dta

global soep_occ_inc_lang_full soep_occ_inc_lang_full.dta
global soep_st_inc_lang_full soep_st_inc_lang_full.dta

global immishare_state immishare_state.dta
global foreign_share_st foreign_share_st.dta
global foreign_share_nat foreign_share_nat.dta

global bibb_iv bibb_iv.dta

global soep_wage_sd_st soep_wage_sd_st.dta
global soep_wage_sd_occ soep_wage_sd_occ.dta

global siab_occs siab_occs.dta
global siab_states siab_states.dta
global siab_occs_nat siab_occs_nat.dta
global siab_states_nat siab_states_nat.dta

global immi_occ_lag immi_occ_lag.dta
global immi_st_lag immi_st_lag.dta

global siab_occshares siab_occshares.dta

global natfor_totals_by_year natfor_totals_by_year.dta

global occ_yr_shares_siab occ_yr_shares_siab.dta
global occ_yr_shares_siab_bibbyrs occ_yr_shares_siab_bibbyrs.dta


global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\bibb_descriptives", replace


**************************************************************************************
**************************************************************************************

use "$datenpfad\$bibb_all_adj_task", clear

**************************************
*** 1. Merge with SIAB
**************************************

rename occup_siab occup
**Merge with occupation-level data from SIAB 
cd "$datenpfad"
merge m:1 occup year using $siab_occs

drop if _merge==2
drop _merge
drop if id==.

rename occup occup_siab 


rename occup_siab occup
**Merge with occupation-level data from SIAB, distinction between foreigners and natives
cd "$datenpfad"
merge m:1 occup year citizen_dummy using $siab_occs_nat

drop if _merge==2
drop _merge
drop if id==.

rename occup occup_siab 



**Merge with state-level data from SIAB 
cd "$datenpfad"
merge m:1 state year using $siab_states

*keep if _merge==3
drop _merge
drop if id==.


**Merge with state-level data from SIAB, distinction between foreigners and natives 
cd "$datenpfad"
merge m:1 state year citizen_dummy using $siab_states_nat

*keep if _merge==3
drop _merge
drop if id==.


**Merge with lagged occupation-level data from SIAB 
cd "$datenpfad"
merge m:1 occup_siab year using $immi_occ_lag

*keep if _merge==3
drop _merge
drop if id==.


**Merge with lagged state-level data from SIAB 
cd "$datenpfad"
merge m:1 state year using $immi_st_lag

*keep if _merge==3
drop _merge
drop if id==.


rename year year_orig
gen year = year_orig-occup_tenure


rename immishare_occ immishare_occ_orig

rename occup_siab occup
**Merge with employment growth in occups over previous 6 years
cd "$datenpfad"
merge m:1 occup year using $siab_occshares

drop if _merge==2
drop _merge
drop if id==.

rename occup occup_siab


**************************************
*** 2. Merge with SOEP
**************************************

**Merge with occupation-level data from SOEP on language skills and info on arrival to GER
cd "$datenpfad"
merge m:1 occup_siab using $soep_occ_inc_lang_full
*keep if _merge==3
drop _merge
drop if id==.


**Merge with state-level data from SOEP on language skills and info on arrival to GER
cd "$datenpfad"
merge m:1 state using $soep_st_inc_lang_full
*keep if _merge==3
drop _merge
drop if id==.

/*
**Merge with state-level share of foreigners
cd "$datenpfad"
merge m:1 year state using $immishare_state
drop if _merge==2
drop _merge
*/

**Merge with national share of foreigners
cd "$datenpfad"
merge m:1 year state using $foreign_share_st
drop if _merge==2
drop _merge


**************************************
*** 3. Merge with MIXED/OTHERS
**************************************

**Merge with instruments
cd "$datenpfad"
merge m:1 year state using $bibb_iv
drop if _merge==2
drop _merge


**Merge with wage variability measures
cd "$datenpfad"
merge m:1 year state using $soep_wage_sd_st
drop if _merge==2
drop _merge

cd "$datenpfad"
merge m:1 year occup_siab using $soep_wage_sd_occ
drop if _merge==2
drop _merge

*======================================================================


**Rescale key variables
replace cognitive = cognitive*100
replace routine = routine*100
replace non_routine = non_routine*100

replace cognitive_occ_w = cognitive_occ_w*100
replace routine_occ_w = routine_occ_w*100
replace non_routine_occ_w = non_routine_occ_w*100

*replace cognitive_occ_w_nat = cognitive_occ_w_nat*100
*replace routine_occ_w_nat = routine_occ_w_nat*100
*replace non_routine_occ_w_nat = non_routine_occ_w_nat*100

replace n_rout_anal_an = n_rout_anal_an*100
replace n_rout_int_an = n_rout_int_an*100
replace rout_cog_an = rout_cog_an*100
replace rout_man_an = rout_man_an*100
replace n_rout_man_an = n_rout_man_an*100

replace n_rout_anal_an_occ_w = n_rout_anal_an_occ_w*100
replace n_rout_int_an_occ_w = n_rout_int_an_occ_w*100
replace rout_cog_an_occ_w = rout_cog_an_occ_w*100
replace rout_man_an_occ_w = rout_man_an_occ_w*100
replace n_rout_man_an_occ_w = n_rout_man_an_occ_w*100

*replace n_rout_anal_an_occ_w_nat = n_rout_anal_an_occ_w_nat*100
*replace n_rout_int_an_occ_w_nat = n_rout_int_an_occ_w_nat*100
*replace rout_cog_an_occ_w_nat = rout_cog_an_occ_w_nat*100
*replace rout_man_an_occ_w_nat = rout_man_an_occ_w_nat*100
*replace n_rout_man_an_occ_w_nat = n_rout_man_an_occ_w_nat*100



**round working hours and remove extreme observations, i.e. cap at 100 hours
replace occup_hours_w = round(occup_hours_w)
replace occup_hours_w = occup_hours_w2 if occup_hours_w==.
replace occup_hours_w = 100 if (occup_hours_w > 100 & occup_hours_w!=.)

**drop occupational tenure with unreasonably large values, i.e. > 50 
drop if (occup_tenure > 50 & occup_tenure !=.)


**Label key variables
label variable occup_tenure "Tenure (Occ.)"
label variable occup_hours_w "Working Hours" 
label variable sex "Female" 
label variable state "State" 
label variable age "Age" 
label variable educ_high "College degree"
label variable educ_low "No Vocational Degree"
label variable educ_med "Vocational degree" 
label variable firm_tenure "Tenure (Firm)" 
label variable for_lang_ex "Foreign Language" 
label variable for_lang "Foreign Language" 
label variable citizen_dummy "Foreign" 
label variable urban "Urban Area" 
label variable firm_large "Large Firm" 
label variable hier_lower "Hierarchy Low" 
label variable hier_middle "Hierarchy Middle" 
label variable hier_upper "Hierarchy Upper" 
label variable hier_exec "Hierarchy Exec."

label variable cognitive "Abstract" 
label variable routine "Routine" 
label variable non_routine "Manual"

label variable cognitive_occ_w "Abstract (Occ.)" 
label variable routine_occ_w "Routine (Occ.)" 
label variable non_routine_occ_w "Manual (Occ.)" 

label variable immishare_st "Foreign Workers (\%, state)" 
label variable age_arrival_st "Age at arrivel in GER (Occ.)" 

label variable occ_change "Changed Job Sometime"

label variable n_rout_anal_an "Non-routine Analytic"
label variable n_rout_int_an "Non-routine Interactive"
label variable rout_cog_an "Routine Cognitive"
label variable rout_man_an "Routine Manual"
label variable n_rout_man_an "Non-routine Manual"

label variable n_rout_anal_an_occ_w "Non-routine Analytic (Occ.)" 
label variable n_rout_int_an_occ_w "Non-routine Interactive (Occ.)"
label variable rout_cog_an_occ_w "Routine Cognitive (Occ.)" 
label variable rout_man_an_occ_w "Routine Manual (Occ.)"
label variable n_rout_man_an_occ_w "Non-routine Manual (Occ.)"

label variable w_occ "Average Wage (Occ.)"
label variable age_occ "Average Age (Occ.)"
label variable w_st "Average Wage (State)"
label variable age_st "Average Age (State)"
label variable immishare_occ_lag "Foreign Workers t-1 (\%, Occ.)" 
label variable immishare_st_lag "Foreign Workers t-1 (\%, State)"
label variable voca_foreign "Voca. Schooling abroad"

label variable agesq "Age Sq./100"
label variable occup_tenure_sq "Occup. Tenure Sq./100"
label variable firm_tenure_sq "Firm Tenure Sq./100"

label variable occup_share_empl_gro "Employment Growth (Occ.),t-6 until t"



***Keep only data with full observations

reg wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
n_rout_anal_an n_rout_int_an rout_cog_an n_rout_man_an ///
	year2-year5 state2-state11 sector1-sector32 citizen_dummy [pw=weight]

predict phat, xb	

**remove observation with missing info
drop if phat == .
drop if wage_hlog == .

drop phat

**correct year variable
drop year
rename year_orig year

**
drop if occup_siab==.

save "$datenpfad\$BIBB_Decomp_Full", replace

	
	
**************************************************************************************
***IV Construction

*************************
**I. Use SIAB to calc group-specific employment shares for each occupation & year
*************************

**A) only year 1975 (for instrument)
clear
use "C:\Users\estorm\Documents\PhD\Research\siab\siab_r_7514_v1_adj", clear

**create immishares by year and occup
keep year occup nati occup

bysort year occup: egen L_all = count(occup)
bysort year occup: egen L_nat= total(nati == 0)
bysort year occup: egen L_for= total(nati == 1)

gen occ_nat = L_nat/L_all
gen occ_for = L_for/L_all

**remove duplicates
drop nati
duplicates drop

**save 
rename occup occup_siab

keep if year ==1975
drop if occup_siab ==.z


keep occup_siab occ_nat occ_for 

rename occ_nat occ_nat_base
rename occ_for occ_for_base


save "$datenpfad\$occ_yr_shares_siab", replace
	
**B) immishares for each BIBB year
**************FIX THAT

/*
clear
use "C:\Users\estorm\Documents\PhD\Research\siab\siab_r_7514_v1_adj", clear

**create immishares by year and occup
keep year occup nati occup

bysort year occup: egen L_all = count(occup)
bysort year occup: egen L_nat= total(nati == 0)
bysort year occup: egen L_for= total(nati == 1)

gen occ_nat = L_nat/L_all
gen occ_for = L_for/L_all

**remove duplicates
drop nati
duplicates drop

**save 
rename occup occup_siab

keep if year ==1992 | year==1999 | year==2006 | year==2012 | year==2014
drop if occup_siab ==.z
replace year=2018 if year==2014

keep occup_siab year occ_nat occ_for 

rename occ_nat occ_nat_bibbyrs
rename occ_for occ_for_bibbyrs

save "$datenpfad\$occ_yr_shares_siab_bibbyrs", replace
	*/
*************************
**II. Merge BIBB data with immi shares
*************************

use "$datenpfad\$BIBB_Decomp_Full", clear

**merge with year=1975 (instrument)
cd "$datenpfad"
merge m:1 occup_siab using $occ_yr_shares_siab

keep if _merge==3
drop _merge

**merge with all SIAB years
cd "$datenpfad"
merge m:1 occup_siab year using $occ_yr_shares_siab_bibbyrs

*keep if _merge==3
drop _merge

*************************
**III. Merge BIBB data with total # of Germans & Foreigners by year
*************************

cd "$datenpfad"
merge m:1 year using $natfor_totals_by_year

*keep if _merge==3
drop _merge

*************************
**IV. Predict total $ of immi by occup and year based on shares and total numbers
*************************
*immishare by year basedon SIAB
*gen foreign_share=foreigners/(foreigners+germans)

*predicted immishare (SIAB shares * total foreigners in GER workforce at year t)
gen immi_occ_yr_hat = occ_for_base*foreigners

*predicted natishare (SIAB shares * total foreigners in GER workforce at year t)
gen nat_occ_yr_hat = occ_nat_base*germans


**create IV based on #foreigners in BIBB
bysort year: egen foreigners_bibb = total(citizen_dummy==1)
gen immi_occ_yr_hat_bibb = occ_for*foreigners_bibb

save "$datenpfad\$BIBB_Decomp_Full", replace


log close
exit



asdf

***delta IV calc
keep occup_siab year germans foreigners immi_occ_yr_hat nat_occ_yr_hat
duplicates drop

sort occup_siab year

gen iv_num = immi_occ_yr_hat[_n]-immi_occ_yr_hat[_n-1]
gen iv_den = immi_occ_yr_hat[_n-1]+nat_occ_yr_hat[_n-1]

gen iv=iv_num/iv_den

keep year occup_siab iv_num iv_den iv
drop if year==1986

save "C:\Users\estorm\Google Drive\BIBB data\BIBB-Erwerbstaetige_1-6\BIBB_ALLE\BIBB_Decomp_Full_IV.dta"




