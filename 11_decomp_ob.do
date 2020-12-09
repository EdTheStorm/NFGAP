

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
global bibb_all_data_final BIBB_ALL_DATA_FINAL.dta
global bibb_all_data_final_immi10 bibb_all_data_final_immi10.dta


global BIBB_Decomp_Full BIBB_Decomp_Full.dta

global occs_partitioned occs_partitioned.dta
global occupations_string occupations_string.dta

global occ_for5 occ_for5.dta

global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
*log using "$outputpfad\bibb_descriptives", replace


**************************************************************************************
**************************************************************************************


use "$datenpfad\$BIBB_Decomp_Full", clear

set matsize 8000

/*
oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
	year2-year5 state2-state11 sector1-sector32 occup_siab1-occup_siab117 [pw=weight], ///
	by(citizen_dummy) cluster(id) weight(1) ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	Occupation: occup_siab1-occup_siab117) relax 

**1. No Tasks (full)
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
	year2-year5 state2-state11 sector1-sector32 occup_siab1-occup_siab117 [pw=weight], ///
	by(citizen_dummy) cluster(id) weight(1) ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	Occupation: occup_siab1-occup_siab117) relax 

**2 occ.task fine (full)
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt ///
	year2-year5 state2-state11 sector1-sector32  [pw=weight], ///
	by(citizen_dummy) cluster(id) weight(1) ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	NR_Analytic_Occ: n_rout_anal_an_occ_wt, ///
	NR_Interactive_Occ: n_rout_int_an_occ_wt, ///
	R_Manual_Occ: rout_man_an_occ_wt, ///
	NR_Manual_Occ: n_rout_man_an_occ_wt) relax 

**3 indiv.task fine	(full)	
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
n_rout_anal_an n_rout_int_an rout_man_an n_rout_man_an ///
	year2-year5 state2-state11 sector1-sector32 [pw=weight], ///
	by(citizen_dummy) cluster(id) weight(1) ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	NR_Analytic_Ind: n_rout_anal_an, ///
	NR_Interactive_Ind: n_rout_int_an, ///
	R_Manual_Ind: rout_man_an, ///
	NR_Manual_Ind: n_rout_man_an) relax 
	
**4. occ. task fine & indiv.task fine (full)
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt ///
n_rout_anal_an n_rout_int_an rout_man_an n_rout_man_an ///
	year2-year5 state2-state11 sector1-sector32 [pw=weight], ///
	by(citizen_dummy) cluster(id) pooled ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	NR_Analytic_Occ: n_rout_anal_an_occ_wt, ///
	NR_Interactive_Occ: n_rout_int_an_occ_wt, ///
	R_Manual_Occ: rout_man_an_occ_wt, ///
	NR_Manual_Occ: n_rout_man_an_occ_wt, ///
	NR_Analytic_Ind: n_rout_anal_an, ///
	NR_Interactive_Ind: n_rout_int_an, ///
	R_Manual_Ind: rout_man_an, ///
	NR_Manual_Ind: n_rout_man_an) relax 
	

*5. indiv.task broad & occ. dumies (full)
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
n_rout_anal_an n_rout_int_an rout_man_an n_rout_man_an ///
	year2-year5 state2-state11 sector1-sector32 occup_siab1-occup_siab117 [pw=weight], ///
	by(citizen_dummy) cluster(id) pooled ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	NR_Analytic_Ind: n_rout_anal_an, ///
	NR_Interactive_Ind: n_rout_int_an, ///
	R_Manual_Ind: rout_man_an, ///
	NR_Manual_Ind: n_rout_man_an, ///
	Occupation: occup_siab1-occup_siab117) relax 


*/
*****************************************************************
/*
**NOW RESTRICTED SAMPLE


cd "$datenpfad"
merge m:1 occup_siab using $occ_for5

keep if _merge==3
drop _merge

*keep restricted sample
keep if sample==1

**6. No Tasks (restricted)
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
	year2-year5 state2-state11 sector1-sector32 occup_siab1-occup_siab89 [pw=weight], ///
	by(citizen_dummy) cluster(id) weight(1) ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	Occupation: occup_siab1-occup_siab89) relax 
	
**7 occ.task fine (restricted)
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt ///
	year2-year5 state2-state11 sector1-sector32  [pw=weight], ///
	by(citizen_dummy) cluster(id) weight(1) ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	NR_Analytic_Occ: n_rout_anal_an_occ_wt, ///
	NR_Interactive_Occ: n_rout_int_an_occ_wt, ///
	R_Manual_Occ: rout_man_an_occ_wt, ///
	NR_Manual_Occ: n_rout_man_an_occ_wt) relax 

**8 indiv.task fine	(restricted)	
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
n_rout_anal_an n_rout_int_an rout_man_an n_rout_man_an ///
	year2-year5 state2-state11 sector1-sector32 [pw=weight], ///
	by(citizen_dummy) cluster(id) weight(1) ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	NR_Analytic_Ind: n_rout_anal_an, ///
	NR_Interactive_Ind: n_rout_int_an, ///
	R_Manual_Ind: rout_man_an, ///
	NR_Manual_Ind: n_rout_man_an) relax 
 
 
**9. occ. task broad & indiv.task broad (restricted)
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt ///
n_rout_anal_an n_rout_int_an rout_man_an n_rout_man_an ///
	year2-year5 state2-state11 sector1-sector32 [pw=weight], ///
	by(citizen_dummy) cluster(id) pooled ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	NR_Analytic_Occ: n_rout_anal_an_occ_wt, ///
	NR_Interactive_Occ: n_rout_int_an_occ_wt, ///
	R_Manual_Occ: rout_man_an_occ_wt, ///
	NR_Manual_Occ: n_rout_man_an_occ_wt, ///
	NR_Analytic_Ind: n_rout_anal_an, ///
	NR_Interactive_Ind: n_rout_int_an, ///
	R_Manual_Ind: rout_man_an, ///
	NR_Manual_Ind: n_rout_man_an) relax 

*10. indiv.task broad & occ. dumies (restricted)
eststo: xi: qui oaxaca wage_hlog age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
n_rout_anal_an n_rout_int_an rout_man_an n_rout_man_an ///
	year2-year5 state2-state11 sector1-sector32 occup_siab1-occup_siab89 [pw=weight], ///
	by(citizen_dummy) cluster(id) pooled ///
	detail(Socio: age agesq sex urban, ///
	Foreign: for_lang_ex voca_foreign, ///
	Education: educ_high educ_med, ///
	Experience: occup_tenure occup_tenure_sq firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector1-sector32, ///
	NR_Analytic_Ind: n_rout_anal_an, ///
	NR_Interactive_Ind: n_rout_int_an, ///
	R_Manual_Ind: rout_man_an, ///
	NR_Manual_Ind: n_rout_man_an, ///
	Occupation: occup_siab1-occup_siab89) relax 


*esttab est6 est7 est8 est9 est10 est1 est2 est3 est4 est5 using reg_wage_oaxaca_fullsample.tex, label replace ///
*drop (Socio Foreign Education Experience Year State Industry) ///
*star(* 0.10 ** 0.05 *** 0.01) b(%5.3f) se(%5.3f) nobase noomit ///

esttab est1 est2 est3 est4 est5 using reg_wage_oaxaca_fullsample.tex, label replace ///
drop (Socio Foreign Education Experience Year State Industry) ///
star(* 0.10 ** 0.05 *** 0.01) b(%5.3f) se(%5.3f) nobase noomit ///



