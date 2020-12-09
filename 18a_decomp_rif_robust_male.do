
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

global key_kldb_88_92 key_kldb_88_92.dta
global key_kldb_88_92_2st key_kldb_88_92_2st.dta
global key_kldb_88_92_3st key_kldb_88_92_3st.dta

global occup_routine_heavy occup_routine_heavy.dta
global occup_routine_heavy92 occup_routine_heavy_92.dta
global occup_routine_heavy79 occup_routine_heavy_79.dta

global occup_cognitive_heavy occup_cognitive_heavy.dta
global occup_cognitive_heavy92 occup_cognitive_heavy_92.dta
global occup_cognitive_heavy79 occup_cognitive_heavy_79.dta

global occup_non_routine_heavy occup_non_routine_heavy.dta
global occup_non_routine_heavy92 occup_non_routine_heavy_92.dta
global occup_non_routine_heavy79 occup_non_routine_heavy_79.dta

global BIBB_Decomp_Full BIBB_Decomp_Full.dta
global BIBB_Decomp_Full_Allocc BIBB_Decomp_Full_Allocc.dta

global BIBB_Decomp_Full_Allocc_lessrest BIBB_Decomp_Full_Allocc_lessrest.dta
global BIBB_Decomp_Full_Allocc_lr_eger BIBB_Decomp_Full_Allocc_lr_eger.dta

global occ_for5 occ_for5.dta

global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\RIF_Decomp_rif_ind_occ_task_restricted_immi3_male", replace

cd "$datenpfad"
set matsize 8000

**************************************************************************************
**************************************************************************************

/*

********************************
**I** Individidual and Occupation-level tasks
********************************

*4. occ + indiv task

set more off
save tempcf2, replace emptyok  

**Create RIFs
*foreach q of num 10 25 50 75 90 {
forvalues q = 10(10)90 {
  use "$datenpfad\$BIBB_Decomp_Full", clear
  
**only occupations with at least 5 observations on foreigners
merge m:1 occup_siab using $occ_for5
keep if _merge==3
drop _merge

*exclude females
keep if sex==1

  *foreach qt of num 10 25 50 75 90 {
  forvalues qt = 10(10)90 {
   gen rif_`qt'=.
}

*foreigners
pctile eval1=wage_hlog if citizen_dummy==1 , nq(100) 
kdensity wage_hlog if citizen_dummy==1, at(eval1) gen(evalf_perc densf_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)90 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evalf_perc[`qt']+`qc'/densf_perc[`qt'] if wage_hlog>=evalf_perc[`qt'] & citizen_dummy==1
 replace rif_`qt'=evalf_perc[`qt']-(1-`qc')/densf_perc[`qt'] if wage_hlog<evalf_perc[`qt']& citizen_dummy==1
}

*natives
pctile eval2=wage_hlog if citizen_dummy==0, nq(100) 
kdensity wage_hlog if citizen_dummy==0, at(eval2) gen(evaln_perc densn_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)90 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evaln_perc[`qt']+`qc'/densn_perc[`qt'] if wage_hlog>=evaln_perc[`qt'] & citizen_dummy==0
 replace rif_`qt'=evaln_perc[`qt']-(1-`qc')/densn_perc[`qt'] if wage_hlog<evaln_perc[`qt']& citizen_dummy==0
}


**Run Decompositions on RIFs

*4. occ. task broad & indiv.task broad		
eststo: xi: bootstrap, reps(100): oaxaca rif_`q' age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
	year2-year5 state2-state11 sector2-sector33 ///
	n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt /// 
	n_rout_anal_an n_rout_int_an rout_man_an n_rout_man_an, ///
	by(citizen_dummy) cluster(id) pooled ///
	detail( ///
	Age: age agesq, /// 
	Gender: sex, ///
	Urban: urban, ///
	Foreign_Language: for_lang_ex, ///
	Foreign_Education: voca_foreign, ///
	College: educ_high, ///
	Vocational_Degree: educ_med, ///
	Tenure_Occup: occup_tenure occup_tenure_sq, ///
	Tenure_Firm: firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector2-sector33, ///
	NRA_Occ: n_rout_anal_an_occ_wt, ///
	NRI_Occ: n_rout_int_an_occ_wt, ///
	RM_Occ: rout_man_an_occ_wt, ///
	NRM_Occ: n_rout_man_an_occ_wt, ///	
	NRA_Ind: n_rout_anal_an, ///
	NRI_Ind: n_rout_int_an, /// 
	RM_Ind: rout_man_an, ///
	NRM_Ind: n_rout_man_an) relax

	
*retrive coefficients
  matrix B=e(b)
  svmat double B, name(coef)
  
  *retrive std errors
  *--------------------------------------------------------------*
  matrix S_diff = _se[overall: difference]
  svmat double S_diff, name(se_diff)
  *--------------------------------------------------------------*
  matrix S_age = _se[explained: Age]
  svmat double S_age, name(se_age)
  
  matrix S_sex = _se[explained: Gender]
  svmat double S_sex, name(se_sex)
  
  matrix S_urban = _se[explained: Urban]
  svmat double S_urban, name(se_urban)
  *-----------------
  matrix S_forlang = _se[explained: Foreign_Language]
  svmat double S_forlang, name(se_forlang)
  
  matrix S_vocfor = _se[explained: Foreign_Education]
  svmat double S_vocfor, name(se_vocfor)
  *-----------------
  matrix S_edhi = _se[explained: College]
  svmat double S_edhi, name(se_edhi)
  
  matrix S_edmed = _se[explained: Vocational_Degree]
  svmat double S_edmed, name(se_edmed)
  *-----------------
  matrix S_tenocc= _se[explained: Tenure_Occup]
  svmat double S_tenocc, name(se_tenocc)
  
  matrix S_tenfirm = _se[explained: Tenure_Firm]
  svmat double S_tenfirm, name(se_tenfirm)
  *-----------------
  matrix S_yr = _se[explained: Year]
  svmat double S_yr, name(se_yr)
  
  matrix S_st = _se[explained: State]
  svmat double S_st, name(se_st)
  
  matrix S_ind = _se[explained: Industry]
  svmat double S_ind, name(se_ind)
  *-----------------
  matrix S_nra_occ = _se[explained: NRA_Occ]
  svmat double S_nra_occ, name(se_nra_occ)
  
  matrix S_nri_occ = _se[explained: NRI_Occ]
  svmat double S_nri_occ, name(se_nri_occ)
  
  matrix S_rm_occ = _se[explained: RM_Occ]
  svmat double S_rm_occ, name(se_rm_occ)
  
  matrix S_nrm_occ = _se[explained: NRM_Occ]
  svmat double S_nrm_occ, name(se_nrm_occ)
  *-----------------------------------------*
  
  matrix S_nra_ind = _se[explained: NRA_Ind]
  svmat double S_nra_ind, name(se_nra_ind)
  
  matrix S_nri_ind = _se[explained: NRI_Ind]
  svmat double S_nri_ind, name(se_nri_ind)
  
  matrix S_rm_ind= _se[explained: RM_Ind]
  svmat double S_rm_ind, name(se_rm_ind)
  
  matrix S_nrm_ind = _se[explained: NRM_Ind]
  svmat double S_nrm_ind, name(se_nrm_ind)
    *-----------------------------------------*
  
  matrix S_nra_tot = _se[explained: NRA_Ind]+ _se[explained: NRA_Occ]
  svmat double S_nra_tot, name(se_nra_tot)
  
  matrix S_nri_tot = _se[explained: NRI_Ind]+ _se[explained: NRI_Occ]
  svmat double S_nri_tot, name(se_nri_tot)
  
  matrix S_rm_tot= _se[explained: RM_Ind] + _se[explained: RM_Occ]
  svmat double S_rm_tot, name(se_rm_tot)
  
  matrix S_nrm_tot = _se[explained: NRM_Ind] + _se[explained: NRM_Occ]
  svmat double S_nrm_tot, name(se_nrm_tot)
 
  *--------------------------------------------------------------*
  
  gen quant=`q'
  gen model = 4
  keep quant model coef*  se_*
  keep if _n==1  
  append using tempcf2
  save tempcf2, replace
 } 
 
sort quant

*rename coefficients
rename coef1 native
rename coef2 foreign
rename coef3 natfor_diff

rename coef6 age_exp
rename coef7 gender_exp
rename coef8 urban_exp
rename coef9 forlang_exp
rename coef10 foreduc_exp
rename coef11 college_exp
rename coef12 voca_exp
rename coef13 tenocc_exp
rename coef14 tenfirm_exp

rename coef15 year_exp
rename coef16 state_exp
rename coef17 ind_exp


rename coef18 nra_occ_exp
rename coef19 nri_occ_exp
rename coef20 rm_occ_exp
rename coef21 nrm_occ_exp

rename coef22 nra_ind_exp
rename coef23 nri_ind_exp
rename coef24 rm_ind_exp
rename coef25 nrm_ind_exp

rename coef4 diff_exp

rename coef26 age_unexp
rename coef27 gender_unexp
rename coef28 urban_unexp
rename coef29 forlang_unexp
rename coef30 foreduc_unexp
rename coef31 college_unexp
rename coef32 voca_unexp
rename coef33 tenocc_unexp
rename coef34 tenfirm_unexp

rename coef35 year_unexp
rename coef36 state_unexp
rename coef37 ind_unexp

rename coef38 nra_occ_unexp
rename coef39 nri_occ_unexp
rename coef40 rm_occ_unexp
rename coef41 nrm_occ_unexp

rename coef42 nra_ind_unexp
rename coef43 nri_ind_unexp
rename coef44 rm_ind_unexp
rename coef45 nrm_ind_unexp

rename coef46 constant
rename coef5 diff_unexp


**relative contributions
gen age_rel = age_exp / diff_exp
gen gender_rel = gender_exp / diff_exp
gen urban_rel = urban_exp / diff_exp

gen forlang_rel = forlang_exp / diff_exp
gen foreduc_rel = foreduc_exp / diff_exp
gen college_rel = college_exp / diff_exp
gen voca_rel = voca_exp / diff_exp
gen tenocc_rel = tenocc_exp / diff_exp
gen tenfirm_rel = tenfirm_exp / diff_exp

gen year_rel = year_exp / diff_exp
gen state_rel = state_exp / diff_exp
gen ind_rel = ind_exp / diff_exp

gen nra_occ_rel = nra_occ_exp / diff_exp
gen nri_occ_rel = nri_occ_exp / diff_exp
gen rm_occ_rel = rm_occ_exp / diff_exp
gen nrm_occ_rel = nrm_occ_exp / diff_exp

gen nra_ind_rel = nra_ind_exp / diff_exp
gen nri_ind_rel = nri_ind_exp / diff_exp
gen rm_ind_rel = rm_ind_exp / diff_exp
gen nrm_ind_rel = nrm_ind_exp / diff_exp

************************************************
**total contribution from tasks
gen nra_total_exp = nra_occ_exp + nra_ind_exp
gen nri_total_exp = nri_occ_exp + nri_ind_exp
gen rm_total_exp = rm_occ_exp + rm_ind_exp
gen nrm_total_exp = nrm_occ_exp + nrm_ind_exp

**RELATIVE contribution from tasks
gen nra_total_rel = nra_occ_rel + nra_ind_rel
gen nri_total_rel = nri_occ_rel + nri_ind_rel
gen rm_total_rel = rm_occ_rel + rm_ind_rel
gen nrm_total_rel = nrm_occ_rel + nrm_ind_rel

************************************************

label var age_rel "Age"
label var gender_rel "Gender"
label var urban_rel "Urban"
label var forlang_rel "Foreign Language"
label var foreduc_rel "Foreign Education"

label var college_rel "College Degree"
label var voca_rel "Vocational Degree"
label var tenocc_rel "Tenure (Occup.)"
label var tenfirm_rel "Tenure (Firm)"

label var year_rel "Year"
label var state_rel "State"
label var ind_rel "Industry"

************************************************
label var nra_occ_rel "NR Analytic (Occup.)"
label var nri_occ_rel "NR Interactive (Occup.)"
label var rm_occ_rel "Rout. Man. (Occup.)"
label var nrm_occ_rel "NR Manual (Occup.)"

label var nra_ind_rel "NR Analytic (Indiv.)"
label var nri_ind_rel "NR Interactive (Indiv.)"
label var rm_ind_rel "Rout. Man. (Indiv.)"
label var nrm_ind_rel "NR Manual (Indiv.)"

************************************************
label var nra_total_exp "NR Analytic (Total)"
label var nri_total_exp "NR Interactive (Total)"
label var rm_total_exp "Rout. Man. (Total)"
label var nrm_total_exp "NR Manual (Total)"

label var nra_total_rel "NR Analytic (Relative)"
label var nri_total_rel "NR Interactive (Relative)"
label var rm_total_rel "Rout. Man. (Relative)"
label var nrm_total_rel "NR Manual (Relative)"

************************************************


replace quant = quant/100

*********-----------------------------**********************-----------------------------**********************

***Gen CPIs
*-------------------------------------------------------------------------------
**Wage Gap
gen lb_gap = natfor_diff - invttail(_N - 1,0.025)* se_diff1 
gen ub_gap = natfor_diff + invttail(_N - 1,0.025)* se_diff1
*-------------------------------------------------------------------------------
**Socio
gen lb_age = age_exp - invttail(_N - 1,0.025)* se_age1 
gen ub_age = age_exp + invttail(_N - 1,0.025)* se_age1

gen lb_age_rel = lb_age/diff_exp
gen ub_age_rel = ub_age/diff_exp
*-------------------------------------------------------------------------------

gen lb_gender = gender_exp - invttail(_N - 1,0.025)* se_sex1 
gen ub_gender = gender_exp + invttail(_N - 1,0.025)* se_sex1

gen lb_gender_rel = lb_gender/diff_exp
gen ub_gender_rel = ub_gender/diff_exp
*-------------------------------------------------------------------------------

gen lb_urban = urban_exp - invttail(_N - 1,0.025)* se_urban1 
gen ub_urban = urban_exp + invttail(_N - 1,0.025)* se_urban1

gen lb_urban_rel = lb_urban/diff_exp
gen ub_urban_rel = ub_urban/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Foreign
gen lb_forlang = forlang_exp - invttail(_N - 1,0.025)* se_forlang1 
gen ub_forlang = forlang_exp + invttail(_N - 1,0.025)* se_forlang1

gen lb_forlang_rel = lb_forlang/diff_exp
gen ub_forlang_rel = ub_forlang/diff_exp
*-------------------------------------------------------------------------------

gen lb_foreduc = foreduc_exp - invttail(_N - 1,0.025)* se_vocfor1 
gen ub_foreduc = foreduc_exp + invttail(_N - 1,0.025)* se_vocfor1

gen lb_foreduc_rel = lb_foreduc/diff_exp
gen ub_foreduc_rel = ub_foreduc/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Education
gen lb_college = college_exp - invttail(_N - 1,0.025)* se_edhi1 
gen ub_college = college_exp + invttail(_N - 1,0.025)* se_edhi1

gen lb_college_rel = lb_college/diff_exp
gen ub_college_rel = ub_college/diff_exp
*-------------------------------------------------------------------------------

gen lb_voca = voca_exp - invttail(_N - 1,0.025)* se_edmed1 
gen ub_voca = voca_exp + invttail(_N - 1,0.025)* se_edmed1

gen lb_voca_rel = lb_voca/diff_exp
gen ub_voca_rel = ub_voca/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Experience
gen lb_tenocc = tenocc_exp - invttail(_N - 1,0.025)* se_tenocc1 
gen ub_tenocc = tenocc_exp + invttail(_N - 1,0.025)* se_tenocc1

gen lb_tenocc_rel = lb_tenocc/diff_exp
gen ub_tenocc_rel = ub_tenocc/diff_exp
*-------------------------------------------------------------------------------

gen lb_tenfirm = tenfirm_exp - invttail(_N - 1,0.025)* se_tenfirm1 
gen ub_tenfirm = tenfirm_exp + invttail(_N - 1,0.025)* se_tenfirm1

gen lb_tenfirm_rel = lb_tenfirm/diff_exp
gen ub_tenfirm_rel = ub_tenfirm/diff_exp
*-------------------------------------------------------------------------------
*------------------------------------------------------------------------------- 
**Dummies
gen lb_year = year_exp - invttail(_N - 1,0.025)* se_yr1 
gen ub_year = year_exp + invttail(_N - 1,0.025)* se_yr1

gen lb_year_rel = lb_year/diff_exp
gen ub_year_rel = ub_year/diff_exp
*-------------------------------------------------------------------------------

gen lb_state = state_exp - invttail(_N - 1,0.025)* se_st1 
gen ub_state = state_exp + invttail(_N - 1,0.025)* se_st1

gen lb_state_rel = lb_state/diff_exp
gen ub_state_rel = ub_state/diff_exp
*-------------------------------------------------------------------------------

gen lb_ind = ind_exp - invttail(_N - 1,0.025)* se_ind1 
gen ub_ind = ind_exp + invttail(_N - 1,0.025)* se_ind1

gen lb_ind_rel = lb_ind/diff_exp
gen ub_ind_rel = ub_ind/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Tasks (Occ.)
gen lb_nra_occ = nra_occ_exp - invttail(_N - 1,0.025)* se_nra_occ1 
gen ub_nra_occ = nra_occ_exp + invttail(_N - 1,0.025)* se_nra_occ1

gen lb_nra_occ_rel = lb_nra_occ/diff_exp
gen ub_nra_occ_rel = ub_nra_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_occ = nri_occ_exp - invttail(_N - 1,0.025)* se_nri_occ1 
gen ub_nri_occ = nri_occ_exp + invttail(_N - 1,0.025)* se_nri_occ1

gen lb_nri_occ_rel = lb_nri_occ/diff_exp
gen ub_nri_occ_rel = ub_nri_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_occ = rm_occ_exp - invttail(_N - 1,0.025)* se_rm_occ1 
gen ub_rm_occ = rm_occ_exp + invttail(_N - 1,0.025)* se_rm_occ1

gen lb_rm_occ_rel = lb_rm_occ/diff_exp
gen ub_rm_occ_rel = ub_rm_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_occ = nrm_occ_exp - invttail(_N - 1,0.025)* se_nrm_occ1 
gen ub_nrm_occ = nrm_occ_exp + invttail(_N - 1,0.025)* se_nrm_occ1

gen lb_nrm_occ_rel = lb_nrm_occ/diff_exp
gen ub_nrm_occ_rel = ub_nrm_occ/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Tasks (Ind.)
gen lb_nra_ind = nra_ind_exp - invttail(_N - 1,0.025)* se_nra_ind1 
gen ub_nra_ind = nra_ind_exp + invttail(_N - 1,0.025)* se_nra_ind1

gen lb_nra_ind_rel = lb_nra_ind/diff_exp
gen ub_nra_ind_rel = ub_nra_ind/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_ind = nri_ind_exp - invttail(_N - 1,0.025)* se_nri_ind1 
gen ub_nri_ind = nri_ind_exp + invttail(_N - 1,0.025)* se_nri_ind1

gen lb_nri_ind_rel = lb_nri_ind/diff_exp
gen ub_nri_ind_rel = ub_nri_ind/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_ind = rm_ind_exp - invttail(_N - 1,0.025)* se_rm_ind1 
gen ub_rm_ind = rm_ind_exp + invttail(_N - 1,0.025)* se_rm_ind1

gen lb_rm_ind_rel = lb_rm_ind/diff_exp
gen ub_rm_ind_rel = ub_rm_ind/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_ind = nrm_ind_exp - invttail(_N - 1,0.025)* se_nrm_ind1 
gen ub_nrm_ind = nrm_ind_exp + invttail(_N - 1,0.025)* se_nrm_ind1

gen lb_nrm_ind_rel = lb_nrm_ind/diff_exp
gen ub_nrm_ind_rel = ub_nrm_ind/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 

**Tasks (Total)
gen lb_nra_tot = nra_total_exp - invttail(_N - 1,0.025)* se_nra_tot1 
gen ub_nra_tot = nra_total_exp + invttail(_N - 1,0.025)* se_nra_tot1

gen lb_nra_tot_rel = lb_nra_tot/diff_exp
gen ub_nra_tot_rel = ub_nra_tot/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_tot = nri_total_exp - invttail(_N - 1,0.025)* se_nri_tot1 
gen ub_nri_tot = nri_total_exp + invttail(_N - 1,0.025)* se_nri_tot1

gen lb_nri_tot_rel = lb_nri_tot/diff_exp
gen ub_nri_tot_rel = ub_nri_tot/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_tot = rm_total_exp - invttail(_N - 1,0.025)* se_rm_tot1 
gen ub_rm_tot = rm_total_exp + invttail(_N - 1,0.025)* se_rm_tot1

gen lb_rm_tot_rel = lb_rm_tot/diff_exp
gen ub_rm_tot_rel = ub_rm_tot/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_tot = nrm_total_exp - invttail(_N - 1,0.025)* se_nrm_tot1 
gen ub_nrm_tot = nrm_total_exp + invttail(_N - 1,0.025)* se_nrm_tot1

gen lb_nrm_tot_rel = lb_nrm_tot/diff_exp
gen ub_nrm_tot_rel = ub_nrm_tot/diff_exp

*********-----------------------------**********************-----------------------------**********************

**Graph RIF-Decompositions - Conditional Wage Gap
graph twoway connected natfor_diff quant ||  /*
   */  rarea lb_gap ub_gap quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(0(0.05)0.2) title("Native-Foreign Wage Gap", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Wage Gap" 2 "95% CI"))
graph export RIF_4_wgap_all_male.png, replace

**Graph RIF-Decompositions - Socio
graph twoway (connected age_rel gender_rel urban_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_age_rel ub_age_rel quant, color(gray%20)  ||      /*
   */  rarea lb_gender_rel ub_gender_rel quant, color(gray%40)  ||      /*
   */  rarea lb_urban_rel ub_urban_rel quant, color(gray%60)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Demographics", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Age" 2 "Sex" 3 "Urban" 4 "95% CI"))
graph export RIF_4_socio_all_male.png, replace
   
**Graph RIF-Decompositions - Foreign
graph twoway (connected forlang_rel foreduc_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_forlang_rel ub_forlang_rel quant, color(gray%50)  ||      /*
   */  rarea lb_foreduc_rel ub_foreduc_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Foreign Characteristics", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Foreign Language" 2 "Foreign Education" 3 "95% CI"))
graph export RIF_4_foreign_all_male.png, replace

**Graph RIF-Decompositions - Education
graph twoway (connected college_rel voca_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_college_rel ub_college_rel quant, color(gray%20)  ||      /*
   */  rarea lb_voca_rel ub_voca_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Education", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "College Degree" 2 "Vocational Degree" 3 "95% CI"))
graph export RIF_4_educ_all_male.png, replace

**Graph RIF-Decompositions - Experience
graph twoway (connected tenocc_rel tenfirm_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_tenocc_rel ub_tenocc_rel quant, color(gray%20)  ||      /*
   */  rarea lb_tenfirm_rel ub_tenfirm_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Experience", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Tenure (Occup.)" 2 "Tenure (Firm.)" 3 "95% CI"))
graph export RIF_4_exp_all_male.png, replace

**Graph RIF-Decompositions - Tasks - occ level only
graph twoway (connected nra_occ_rel nri_occ_rel rm_occ_rel nrm_occ_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%50)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Occupational", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_4_tasks_occ_all_male.png, replace 

**Graph RIF-Decompositions - Tasks - indiv level only
graph twoway (connected nra_ind_rel nri_ind_rel rm_ind_rel nrm_ind_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_nra_ind_rel ub_nra_ind_rel quant, color(gray%50)  ||      /*
   */  rarea lb_nri_ind_rel ub_nri_ind_rel quant, color(gray%70)  ||      /*
   */  rarea lb_rm_ind_rel ub_rm_ind_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nrm_ind_rel ub_nrm_ind_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Indiv.)" 2 "NR Interactive (Indiv.)" 3 "Rout. Man. (Indiv.)" 4 "NR Manual (Indiv.)" 5 "95% CI"))
graph export RIF_4_tasks_ind_all_male.png, replace

**Graph RIF-Decompositions - Dummies
graph twoway (connected year_rel state_rel ind_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_year_rel ub_year_rel quant, color(gray%70)  ||      /*
   */  rarea lb_state_rel ub_state_rel quant, color(gray%50)  ||      /*
   */  rarea lb_ind_rel ub_ind_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Other Controls", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Year" 2 "State" 3 "Industry" 4 "95% CI"))
graph export RIF_4_dummies_all_male.png, replace 
   

   
**Graph RIF-Decompositions - Tasks NRA with CI - ind level only - relative to total task contribution
graph twoway (connected nra_ind_rel nra_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_nra_ind_rel ub_nra_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_nra_tot_rel ub_nra_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Indiv.)" 2 "NR Analytic (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_nra_ci_rel_male.png, replace  


**Graph RIF-Decompositions - Tasks NRI with CI - ind level only - relative to total task contribution
graph twoway (connected nri_ind_rel nri_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_nri_ind_rel ub_nri_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_nri_tot_rel ub_nri_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Interactive (Indiv.)" 2 "NR Interactive (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_nri_ci_rel_male.png, replace  


**Graph RIF-Decompositions - Tasks RM with CI - ind level only - relative to total task contribution
graph twoway (connected rm_ind_rel rm_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_rm_ind_rel ub_rm_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_rm_tot_rel ub_rm_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Rout. Manual (Indiv.)" 2 "Rout. Manual (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_rm_ci_rel_male.png, replace  


**Graph RIF-Decompositions - Tasks NRM with CI - ind level only - relative to total task contribution
graph twoway (connected nrm_ind_rel nrm_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_nrm_ind_rel ub_nrm_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_nrm_tot_rel ub_nrm_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Manual (Indiv.)" 2 "NRM Manual (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_nrm_ci_rel_male.png, replace  


est clear

drop native foreign natfor_diff ///
constant quant model

drop *_exp
drop *_unexp 
drop *_rel 

drop lb_* 
drop ub_* 
*********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------
 
   *****1990s
 
*********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------
 
*4. occ + indiv task

set more off
save tempcf2, replace emptyok  

**Create RIFs
*foreach q of num 10 25 50 75 90 {
forvalues q = 10(10)80 {
  use "$datenpfad\$BIBB_Decomp_Full", clear
  
**only occupations with at least 5 observations on foreigners
merge m:1 occup_siab using $occ_for5
keep if _merge==3
drop _merge

keep if year < 2000

*exclude females
keep if sex==1
  
  *foreach qt of num 10 25 50 75 90 {
  forvalues qt = 10(10)80 {
   gen rif_`qt'=.
}

*foreigners
pctile eval1=wage_hlog if citizen_dummy==1 , nq(100) 
kdensity wage_hlog if citizen_dummy==1, at(eval1) gen(evalf_perc densf_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)80 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evalf_perc[`qt']+`qc'/densf_perc[`qt'] if wage_hlog>=evalf_perc[`qt'] & citizen_dummy==1
 replace rif_`qt'=evalf_perc[`qt']-(1-`qc')/densf_perc[`qt'] if wage_hlog<evalf_perc[`qt']& citizen_dummy==1
}

*natives
pctile eval2=wage_hlog if citizen_dummy==0, nq(100) 
kdensity wage_hlog if citizen_dummy==0, at(eval2) gen(evaln_perc densn_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)80 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evaln_perc[`qt']+`qc'/densn_perc[`qt'] if wage_hlog>=evaln_perc[`qt'] & citizen_dummy==0
 replace rif_`qt'=evaln_perc[`qt']-(1-`qc')/densn_perc[`qt'] if wage_hlog<evaln_perc[`qt']& citizen_dummy==0
}


**Run Decompositions on RIFs

*4. occ. task broad & indiv.task broad		
eststo: xi: bootstrap, reps(100): oaxaca rif_`q' age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
	year2-year5 state2-state11 sector2-sector33 ///
	n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt /// 
	n_rout_anal_an n_rout_int_an rout_man_an n_rout_man_an, ///
	by(citizen_dummy) cluster(id) pooled ///
	detail( ///
	Age: age agesq, /// 
	Gender: sex, ///
	Urban: urban, ///
	Foreign_Language: for_lang_ex, ///
	Foreign_Education: voca_foreign, ///
	College: educ_high, ///
	Vocational_Degree: educ_med, ///
	Tenure_Occup: occup_tenure occup_tenure_sq, ///
	Tenure_Firm: firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector2-sector33, ///
	NRA_Occ: n_rout_anal_an_occ_wt, ///
	NRI_Occ: n_rout_int_an_occ_wt, ///
	RM_Occ: rout_man_an_occ_wt, ///
	NRM_Occ: n_rout_man_an_occ_wt, ///	
	NRA_Ind: n_rout_anal_an, ///
	NRI_Ind: n_rout_int_an, /// 
	RM_Ind: rout_man_an, ///
	NRM_Ind: n_rout_man_an)  relax 

	
*retrive coefficients
  matrix B=e(b)
  svmat double B, name(coef)
  
  *retrive std errors
  *--------------------------------------------------------------*
  matrix S_diff = _se[overall: difference]
  svmat double S_diff, name(se_diff)
  *--------------------------------------------------------------*
  matrix S_age = _se[explained: Age]
  svmat double S_age, name(se_age)
  
  matrix S_sex = _se[explained: Gender]
  svmat double S_sex, name(se_sex)
  
  matrix S_urban = _se[explained: Urban]
  svmat double S_urban, name(se_urban)
  *-----------------
  matrix S_forlang = _se[explained: Foreign_Language]
  svmat double S_forlang, name(se_forlang)
  
  matrix S_vocfor = _se[explained: Foreign_Education]
  svmat double S_vocfor, name(se_vocfor)
  *-----------------
  matrix S_edhi = _se[explained: College]
  svmat double S_edhi, name(se_edhi)
  
  matrix S_edmed = _se[explained: Vocational_Degree]
  svmat double S_edmed, name(se_edmed)
  *-----------------
  matrix S_tenocc= _se[explained: Tenure_Occup]
  svmat double S_tenocc, name(se_tenocc)
  
  matrix S_tenfirm = _se[explained: Tenure_Firm]
  svmat double S_tenfirm, name(se_tenfirm)
  *-----------------
  matrix S_yr = _se[explained: Year]
  svmat double S_yr, name(se_yr)
  
  matrix S_st = _se[explained: State]
  svmat double S_st, name(se_st)
  
  matrix S_ind = _se[explained: Industry]
  svmat double S_ind, name(se_ind)
  *-----------------
  matrix S_nra_occ = _se[explained: NRA_Occ]
  svmat double S_nra_occ, name(se_nra_occ)
  
  matrix S_nri_occ = _se[explained: NRI_Occ]
  svmat double S_nri_occ, name(se_nri_occ)
  
  matrix S_rm_occ = _se[explained: RM_Occ]
  svmat double S_rm_occ, name(se_rm_occ)
  
  matrix S_nrm_occ = _se[explained: NRM_Occ]
  svmat double S_nrm_occ, name(se_nrm_occ)
  *-----------------------------------------*
  
  matrix S_nra_ind = _se[explained: NRA_Ind]
  svmat double S_nra_ind, name(se_nra_ind)
  
  matrix S_nri_ind = _se[explained: NRI_Ind]
  svmat double S_nri_ind, name(se_nri_ind)
  
  matrix S_rm_ind= _se[explained: RM_Ind]
  svmat double S_rm_ind, name(se_rm_ind)
  
  matrix S_nrm_ind = _se[explained: NRM_Ind]
  svmat double S_nrm_ind, name(se_nrm_ind)
    *-----------------------------------------*
  
  matrix S_nra_tot = _se[explained: NRA_Ind]+ _se[explained: NRA_Occ]
  svmat double S_nra_tot, name(se_nra_tot)
  
  matrix S_nri_tot = _se[explained: NRI_Ind]+ _se[explained: NRI_Occ]
  svmat double S_nri_tot, name(se_nri_tot)
  
  matrix S_rm_tot= _se[explained: RM_Ind] + _se[explained: RM_Occ]
  svmat double S_rm_tot, name(se_rm_tot)
  
  matrix S_nrm_tot = _se[explained: NRM_Ind] + _se[explained: NRM_Occ]
  svmat double S_nrm_tot, name(se_nrm_tot)
 
  *--------------------------------------------------------------*
  
  gen quant=`q'
  gen model = 4
  keep quant model coef*  se_*
  keep if _n==1  
  append using tempcf2
  save tempcf2, replace
 } 
 
sort quant

*rename coefficients
rename coef1 native
rename coef2 foreign
rename coef3 natfor_diff

rename coef6 age_exp
rename coef7 gender_exp
rename coef8 urban_exp
rename coef9 forlang_exp
rename coef10 foreduc_exp
rename coef11 college_exp
rename coef12 voca_exp
rename coef13 tenocc_exp
rename coef14 tenfirm_exp

rename coef15 year_exp
rename coef16 state_exp
rename coef17 ind_exp


rename coef18 nra_occ_exp
rename coef19 nri_occ_exp
rename coef20 rm_occ_exp
rename coef21 nrm_occ_exp

rename coef22 nra_ind_exp
rename coef23 nri_ind_exp
rename coef24 rm_ind_exp
rename coef25 nrm_ind_exp

rename coef4 diff_exp

rename coef26 age_unexp
rename coef27 gender_unexp
rename coef28 urban_unexp
rename coef29 forlang_unexp
rename coef30 foreduc_unexp
rename coef31 college_unexp
rename coef32 voca_unexp
rename coef33 tenocc_unexp
rename coef34 tenfirm_unexp

rename coef35 year_unexp
rename coef36 state_unexp
rename coef37 ind_unexp

rename coef38 nra_occ_unexp
rename coef39 nri_occ_unexp
rename coef40 rm_occ_unexp
rename coef41 nrm_occ_unexp

rename coef42 nra_ind_unexp
rename coef43 nri_ind_unexp
rename coef44 rm_ind_unexp
rename coef45 nrm_ind_unexp

rename coef46 constant
rename coef5 diff_unexp


**relative contributions
gen age_rel = age_exp / diff_exp
gen gender_rel = gender_exp / diff_exp
gen urban_rel = urban_exp / diff_exp

gen forlang_rel = forlang_exp / diff_exp
gen foreduc_rel = foreduc_exp / diff_exp
gen college_rel = college_exp / diff_exp
gen voca_rel = voca_exp / diff_exp
gen tenocc_rel = tenocc_exp / diff_exp
gen tenfirm_rel = tenfirm_exp / diff_exp

gen year_rel = year_exp / diff_exp
gen state_rel = state_exp / diff_exp
gen ind_rel = ind_exp / diff_exp

gen nra_occ_rel = nra_occ_exp / diff_exp
gen nri_occ_rel = nri_occ_exp / diff_exp
gen rm_occ_rel = rm_occ_exp / diff_exp
gen nrm_occ_rel = nrm_occ_exp / diff_exp

gen nra_ind_rel = nra_ind_exp / diff_exp
gen nri_ind_rel = nri_ind_exp / diff_exp
gen rm_ind_rel = rm_ind_exp / diff_exp
gen nrm_ind_rel = nrm_ind_exp / diff_exp

************************************************
**total contribution from tasks
gen nra_total_exp = nra_occ_exp + nra_ind_exp
gen nri_total_exp = nri_occ_exp + nri_ind_exp
gen rm_total_exp = rm_occ_exp + rm_ind_exp
gen nrm_total_exp = nrm_occ_exp + nrm_ind_exp

**RELATIVE contribution from tasks
gen nra_total_rel = nra_occ_rel + nra_ind_rel
gen nri_total_rel = nri_occ_rel + nri_ind_rel
gen rm_total_rel = rm_occ_rel + rm_ind_rel
gen nrm_total_rel = nrm_occ_rel + nrm_ind_rel

************************************************

label var age_rel "Age"
label var gender_rel "Gender"
label var urban_rel "Urban"
label var forlang_rel "Foreign Language"
label var foreduc_rel "Foreign Education"

label var college_rel "College Degree"
label var voca_rel "Vocational Degree"
label var tenocc_rel "Tenure (Occup.)"
label var tenfirm_rel "Tenure (Firm)"

label var year_rel "Year"
label var state_rel "State"
label var ind_rel "Industry"

************************************************
label var nra_occ_rel "NR Analytic (Occup.)"
label var nri_occ_rel "NR Interactive (Occup.)"
label var rm_occ_rel "Rout. Man. (Occup.)"
label var nrm_occ_rel "NR Manual (Occup.)"

label var nra_ind_rel "NR Analytic (Indiv.)"
label var nri_ind_rel "NR Interactive (Indiv.)"
label var rm_ind_rel "Rout. Man. (Indiv.)"
label var nrm_ind_rel "NR Manual (Indiv.)"

************************************************
label var nra_total_exp "NR Analytic (Total)"
label var nri_total_exp "NR Interactive (Total)"
label var rm_total_exp "Rout. Man. (Total)"
label var nrm_total_exp "NR Manual (Total)"

label var nra_total_rel "NR Analytic (Relative)"
label var nri_total_rel "NR Interactive (Relative)"
label var rm_total_rel "Rout. Man. (Relative)"
label var nrm_total_rel "NR Manual (Relative)"

************************************************


replace quant = quant/100

*********-----------------------------**********************-----------------------------**********************

***Gen CPIs
*-------------------------------------------------------------------------------
**Wage Gap
gen lb_gap = natfor_diff - invttail(_N - 1,0.025)* se_diff1 
gen ub_gap = natfor_diff + invttail(_N - 1,0.025)* se_diff1
*-------------------------------------------------------------------------------
**Socio
gen lb_age = age_exp - invttail(_N - 1,0.025)* se_age1 
gen ub_age = age_exp + invttail(_N - 1,0.025)* se_age1

gen lb_age_rel = lb_age/diff_exp
gen ub_age_rel = ub_age/diff_exp
*-------------------------------------------------------------------------------

gen lb_gender = gender_exp - invttail(_N - 1,0.025)* se_sex1 
gen ub_gender = gender_exp + invttail(_N - 1,0.025)* se_sex1

gen lb_gender_rel = lb_gender/diff_exp
gen ub_gender_rel = ub_gender/diff_exp
*-------------------------------------------------------------------------------

gen lb_urban = urban_exp - invttail(_N - 1,0.025)* se_urban1 
gen ub_urban = urban_exp + invttail(_N - 1,0.025)* se_urban1

gen lb_urban_rel = lb_urban/diff_exp
gen ub_urban_rel = ub_urban/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Foreign
gen lb_forlang = forlang_exp - invttail(_N - 1,0.025)* se_forlang1 
gen ub_forlang = forlang_exp + invttail(_N - 1,0.025)* se_forlang1

gen lb_forlang_rel = lb_forlang/diff_exp
gen ub_forlang_rel = ub_forlang/diff_exp
*-------------------------------------------------------------------------------

gen lb_foreduc = foreduc_exp - invttail(_N - 1,0.025)* se_vocfor1 
gen ub_foreduc = foreduc_exp + invttail(_N - 1,0.025)* se_vocfor1

gen lb_foreduc_rel = lb_foreduc/diff_exp
gen ub_foreduc_rel = ub_foreduc/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Education
gen lb_college = college_exp - invttail(_N - 1,0.025)* se_edhi1 
gen ub_college = college_exp + invttail(_N - 1,0.025)* se_edhi1

gen lb_college_rel = lb_college/diff_exp
gen ub_college_rel = ub_college/diff_exp
*-------------------------------------------------------------------------------

gen lb_voca = voca_exp - invttail(_N - 1,0.025)* se_edmed1 
gen ub_voca = voca_exp + invttail(_N - 1,0.025)* se_edmed1

gen lb_voca_rel = lb_voca/diff_exp
gen ub_voca_rel = ub_voca/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Experience
gen lb_tenocc = tenocc_exp - invttail(_N - 1,0.025)* se_tenocc1 
gen ub_tenocc = tenocc_exp + invttail(_N - 1,0.025)* se_tenocc1

gen lb_tenocc_rel = lb_tenocc/diff_exp
gen ub_tenocc_rel = ub_tenocc/diff_exp
*-------------------------------------------------------------------------------

gen lb_tenfirm = tenfirm_exp - invttail(_N - 1,0.025)* se_tenfirm1 
gen ub_tenfirm = tenfirm_exp + invttail(_N - 1,0.025)* se_tenfirm1

gen lb_tenfirm_rel = lb_tenfirm/diff_exp
gen ub_tenfirm_rel = ub_tenfirm/diff_exp
*-------------------------------------------------------------------------------
*------------------------------------------------------------------------------- 
**Dummies
gen lb_year = year_exp - invttail(_N - 1,0.025)* se_yr1 
gen ub_year = year_exp + invttail(_N - 1,0.025)* se_yr1

gen lb_year_rel = lb_year/diff_exp
gen ub_year_rel = ub_year/diff_exp
*-------------------------------------------------------------------------------

gen lb_state = state_exp - invttail(_N - 1,0.025)* se_st1 
gen ub_state = state_exp + invttail(_N - 1,0.025)* se_st1

gen lb_state_rel = lb_state/diff_exp
gen ub_state_rel = ub_state/diff_exp
*-------------------------------------------------------------------------------

gen lb_ind = ind_exp - invttail(_N - 1,0.025)* se_ind1 
gen ub_ind = ind_exp + invttail(_N - 1,0.025)* se_ind1

gen lb_ind_rel = lb_ind/diff_exp
gen ub_ind_rel = ub_ind/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Tasks (Occ.)
gen lb_nra_occ = nra_occ_exp - invttail(_N - 1,0.025)* se_nra_occ1 
gen ub_nra_occ = nra_occ_exp + invttail(_N - 1,0.025)* se_nra_occ1

gen lb_nra_occ_rel = lb_nra_occ/diff_exp
gen ub_nra_occ_rel = ub_nra_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_occ = nri_occ_exp - invttail(_N - 1,0.025)* se_nri_occ1 
gen ub_nri_occ = nri_occ_exp + invttail(_N - 1,0.025)* se_nri_occ1

gen lb_nri_occ_rel = lb_nri_occ/diff_exp
gen ub_nri_occ_rel = ub_nri_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_occ = rm_occ_exp - invttail(_N - 1,0.025)* se_rm_occ1 
gen ub_rm_occ = rm_occ_exp + invttail(_N - 1,0.025)* se_rm_occ1

gen lb_rm_occ_rel = lb_rm_occ/diff_exp
gen ub_rm_occ_rel = ub_rm_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_occ = nrm_occ_exp - invttail(_N - 1,0.025)* se_nrm_occ1 
gen ub_nrm_occ = nrm_occ_exp + invttail(_N - 1,0.025)* se_nrm_occ1

gen lb_nrm_occ_rel = lb_nrm_occ/diff_exp
gen ub_nrm_occ_rel = ub_nrm_occ/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Tasks (Ind.)
gen lb_nra_ind = nra_ind_exp - invttail(_N - 1,0.025)* se_nra_ind1 
gen ub_nra_ind = nra_ind_exp + invttail(_N - 1,0.025)* se_nra_ind1

gen lb_nra_ind_rel = lb_nra_ind/diff_exp
gen ub_nra_ind_rel = ub_nra_ind/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_ind = nri_ind_exp - invttail(_N - 1,0.025)* se_nri_ind1 
gen ub_nri_ind = nri_ind_exp + invttail(_N - 1,0.025)* se_nri_ind1

gen lb_nri_ind_rel = lb_nri_ind/diff_exp
gen ub_nri_ind_rel = ub_nri_ind/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_ind = rm_ind_exp - invttail(_N - 1,0.025)* se_rm_ind1 
gen ub_rm_ind = rm_ind_exp + invttail(_N - 1,0.025)* se_rm_ind1

gen lb_rm_ind_rel = lb_rm_ind/diff_exp
gen ub_rm_ind_rel = ub_rm_ind/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_ind = nrm_ind_exp - invttail(_N - 1,0.025)* se_nrm_ind1 
gen ub_nrm_ind = nrm_ind_exp + invttail(_N - 1,0.025)* se_nrm_ind1

gen lb_nrm_ind_rel = lb_nrm_ind/diff_exp
gen ub_nrm_ind_rel = ub_nrm_ind/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 

**Tasks (Total)
gen lb_nra_tot = nra_total_exp - invttail(_N - 1,0.025)* se_nra_tot1 
gen ub_nra_tot = nra_total_exp + invttail(_N - 1,0.025)* se_nra_tot1

gen lb_nra_tot_rel = lb_nra_tot/diff_exp
gen ub_nra_tot_rel = ub_nra_tot/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_tot = nri_total_exp - invttail(_N - 1,0.025)* se_nri_tot1 
gen ub_nri_tot = nri_total_exp + invttail(_N - 1,0.025)* se_nri_tot1

gen lb_nri_tot_rel = lb_nri_tot/diff_exp
gen ub_nri_tot_rel = ub_nri_tot/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_tot = rm_total_exp - invttail(_N - 1,0.025)* se_rm_tot1 
gen ub_rm_tot = rm_total_exp + invttail(_N - 1,0.025)* se_rm_tot1

gen lb_rm_tot_rel = lb_rm_tot/diff_exp
gen ub_rm_tot_rel = ub_rm_tot/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_tot = nrm_total_exp - invttail(_N - 1,0.025)* se_nrm_tot1 
gen ub_nrm_tot = nrm_total_exp + invttail(_N - 1,0.025)* se_nrm_tot1

gen lb_nrm_tot_rel = lb_nrm_tot/diff_exp
gen ub_nrm_tot_rel = ub_nrm_tot/diff_exp

*********-----------------------------**********************-----------------------------**********************

**Graph RIF-Decompositions - Conditional Wage Gap
graph twoway connected natfor_diff quant ||  /*
   */  rarea lb_gap ub_gap quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(0(0.05)0.2) title("Native-Foreign Wage Gap: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Wage Gap" 2 "95% CI"))
graph export RIF_4_wgap90_male.png, replace

**Graph RIF-Decompositions - Socio
graph twoway (connected age_rel gender_rel urban_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_age_rel ub_age_rel quant, color(gray%20)  ||      /*
   */  rarea lb_gender_rel ub_gender_rel quant, color(gray%40)  ||      /*
   */  rarea lb_urban_rel ub_urban_rel quant, color(gray%60)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Demographics: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Age" 2 "Sex" 3 "Urban" 4 "95% CI"))
graph export RIF_4_socio90_male.png, replace
   
**Graph RIF-Decompositions - Foreign
graph twoway (connected forlang_rel foreduc_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_forlang_rel ub_forlang_rel quant, color(gray%50)  ||      /*
   */  rarea lb_foreduc_rel ub_foreduc_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Foreign Characteristics: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Foreign Language" 2 "Foreign Education" 3 "95% CI"))
graph export RIF_4_foreign90_male.png, replace

**Graph RIF-Decompositions - Education
graph twoway (connected college_rel voca_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_college_rel ub_college_rel quant, color(gray%20)  ||      /*
   */  rarea lb_voca_rel ub_voca_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Education: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "College Degree" 2 "Vocational Degree" 3 "95% CI"))
graph export RIF_4_educ90_male.png, replace

**Graph RIF-Decompositions - Experience
graph twoway (connected tenocc_rel tenfirm_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_tenocc_rel ub_tenocc_rel quant, color(gray%20)  ||      /*
   */  rarea lb_tenfirm_rel ub_tenfirm_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Experience: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Tenure (Occup.)" 2 "Tenure (Firm.)" 3 "95% CI"))
graph export RIF_4_exp90_male.png, replace

**Graph RIF-Decompositions - Dummies
graph twoway (connected year_rel state_rel ind_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_year_rel ub_year_rel quant, color(gray%70)  ||      /*
   */  rarea lb_state_rel ub_state_rel quant, color(gray%50)  ||      /*
   */  rarea lb_ind_rel ub_ind_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Other Controls: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Year" 2 "State" 3 "Industry" 4 "95% CI"))
graph export RIF_4_dummies90_male.png, replace 
   

**Graph RIF-Decompositions - Tasks NRA with CI - ind level only - relative to total task contribution
graph twoway (connected nra_ind_rel nra_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_nra_ind_rel ub_nra_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_nra_tot_rel ub_nra_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(0(0.25)2) title("Tasks - Individual: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Indiv.)" 2 "NR Analytic (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_nra_ci_rel90_male.png, replace  


**Graph RIF-Decompositions - Tasks NRI with CI - ind level only - relative to total task contribution
graph twoway (connected nri_ind_rel nri_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_nri_ind_rel ub_nri_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_nri_tot_rel ub_nri_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Interactive (Indiv.)" 2 "NR Interactive (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_nri_ci_rel90_male.png, replace  


**Graph RIF-Decompositions - Tasks RM with CI - ind level only - relative to total task contribution
graph twoway (connected rm_ind_rel rm_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_rm_ind_rel ub_rm_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_rm_tot_rel ub_rm_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-1(0.25)0.5) title("Tasks - Individual: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Rout. Manual (Indiv.)" 2 "Rout. Manual (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_rm_ci_rel90_male.png, replace  


**Graph RIF-Decompositions - Tasks NRM with CI - ind level only - relative to total task contribution
graph twoway (connected nrm_ind_rel nrm_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_nrm_ind_rel ub_nrm_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_nrm_tot_rel ub_nrm_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-1(0.25)0.5) title("Tasks - Individual: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Manual (Indiv.)" 2 "NRM Manual (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_nrm_ci_rel90_male.png, replace   


est clear

drop native foreign natfor_diff ///
constant quant model

drop *_exp
drop *_unexp 
drop *_rel 

drop lb_* 
drop ub_* 
*********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------

   *****2000s

*********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------


*4. occ + indiv task

set more off
save tempcf2, replace emptyok  

**Create RIFs
*foreach q of num 10 25 50 75 90 {
forvalues q = 10(10)90 {
  use "$datenpfad\$BIBB_Decomp_Full", clear
 
**only occupations with at least 5 observations on foreigners
merge m:1 occup_siab using $occ_for5
keep if _merge==3
drop _merge
 
keep if year > 2000

 *exclude females
keep if sex==1
 
  *foreach qt of num 10 25 50 75 90 {
  forvalues qt = 10(10)90 {
   gen rif_`qt'=.
}

*foreigners
pctile eval1=wage_hlog if citizen_dummy==1 , nq(100) 
kdensity wage_hlog if citizen_dummy==1, at(eval1) gen(evalf_perc densf_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)90 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evalf_perc[`qt']+`qc'/densf_perc[`qt'] if wage_hlog>=evalf_perc[`qt'] & citizen_dummy==1
 replace rif_`qt'=evalf_perc[`qt']-(1-`qc')/densf_perc[`qt'] if wage_hlog<evalf_perc[`qt']& citizen_dummy==1
}

*natives
pctile eval2=wage_hlog if citizen_dummy==0, nq(100) 
kdensity wage_hlog if citizen_dummy==0, at(eval2) gen(evaln_perc densn_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)90 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evaln_perc[`qt']+`qc'/densn_perc[`qt'] if wage_hlog>=evaln_perc[`qt'] & citizen_dummy==0
 replace rif_`qt'=evaln_perc[`qt']-(1-`qc')/densn_perc[`qt'] if wage_hlog<evaln_perc[`qt']& citizen_dummy==0
}


**Run Decompositions on RIFs

*4. occ. task broad & indiv.task broad		
eststo: xi: bootstrap, reps(100): oaxaca rif_`q' age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
	year2-year5 state2-state11 sector2-sector33 ///
	n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt /// 
	n_rout_anal_an n_rout_int_an rout_man_an n_rout_man_an, ///
	by(citizen_dummy) cluster(id) pooled ///
	detail( ///
	Age: age agesq, /// 
	Gender: sex, ///
	Urban: urban, ///
	Foreign_Language: for_lang_ex, ///
	Foreign_Education: voca_foreign, ///
	College: educ_high, ///
	Vocational_Degree: educ_med, ///
	Tenure_Occup: occup_tenure occup_tenure_sq, ///
	Tenure_Firm: firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector2-sector33, ///
	NRA_Occ: n_rout_anal_an_occ_wt, ///
	NRI_Occ: n_rout_int_an_occ_wt, ///
	RM_Occ: rout_man_an_occ_wt, ///
	NRM_Occ: n_rout_man_an_occ_wt, ///	
	NRA_Ind: n_rout_anal_an, ///
	NRI_Ind: n_rout_int_an, /// 
	RM_Ind: rout_man_an, ///
	NRM_Ind: n_rout_man_an)  relax 

	
*retrive coefficients
  matrix B=e(b)
  svmat double B, name(coef)
  
  *retrive std errors
  *--------------------------------------------------------------*
  matrix S_diff = _se[overall: difference]
  svmat double S_diff, name(se_diff)
  *--------------------------------------------------------------*
  matrix S_age = _se[explained: Age]
  svmat double S_age, name(se_age)
  
  matrix S_sex = _se[explained: Gender]
  svmat double S_sex, name(se_sex)
  
  matrix S_urban = _se[explained: Urban]
  svmat double S_urban, name(se_urban)
  *-----------------
  matrix S_forlang = _se[explained: Foreign_Language]
  svmat double S_forlang, name(se_forlang)
  
  matrix S_vocfor = _se[explained: Foreign_Education]
  svmat double S_vocfor, name(se_vocfor)
  *-----------------
  matrix S_edhi = _se[explained: College]
  svmat double S_edhi, name(se_edhi)
  
  matrix S_edmed = _se[explained: Vocational_Degree]
  svmat double S_edmed, name(se_edmed)
  *-----------------
  matrix S_tenocc= _se[explained: Tenure_Occup]
  svmat double S_tenocc, name(se_tenocc)
  
  matrix S_tenfirm = _se[explained: Tenure_Firm]
  svmat double S_tenfirm, name(se_tenfirm)
  *-----------------
  matrix S_yr = _se[explained: Year]
  svmat double S_yr, name(se_yr)
  
  matrix S_st = _se[explained: State]
  svmat double S_st, name(se_st)
  
  matrix S_ind = _se[explained: Industry]
  svmat double S_ind, name(se_ind)
  *-----------------
  matrix S_nra_occ = _se[explained: NRA_Occ]
  svmat double S_nra_occ, name(se_nra_occ)
  
  matrix S_nri_occ = _se[explained: NRI_Occ]
  svmat double S_nri_occ, name(se_nri_occ)
  
  matrix S_rm_occ = _se[explained: RM_Occ]
  svmat double S_rm_occ, name(se_rm_occ)
  
  matrix S_nrm_occ = _se[explained: NRM_Occ]
  svmat double S_nrm_occ, name(se_nrm_occ)
  *-----------------------------------------*
  
  matrix S_nra_ind = _se[explained: NRA_Ind]
  svmat double S_nra_ind, name(se_nra_ind)
  
  matrix S_nri_ind = _se[explained: NRI_Ind]
  svmat double S_nri_ind, name(se_nri_ind)
  
  matrix S_rm_ind= _se[explained: RM_Ind]
  svmat double S_rm_ind, name(se_rm_ind)
  
  matrix S_nrm_ind = _se[explained: NRM_Ind]
  svmat double S_nrm_ind, name(se_nrm_ind)
    *-----------------------------------------*
  
  matrix S_nra_tot = _se[explained: NRA_Ind]+ _se[explained: NRA_Occ]
  svmat double S_nra_tot, name(se_nra_tot)
  
  matrix S_nri_tot = _se[explained: NRI_Ind]+ _se[explained: NRI_Occ]
  svmat double S_nri_tot, name(se_nri_tot)
  
  matrix S_rm_tot= _se[explained: RM_Ind] + _se[explained: RM_Occ]
  svmat double S_rm_tot, name(se_rm_tot)
  
  matrix S_nrm_tot = _se[explained: NRM_Ind] + _se[explained: NRM_Occ]
  svmat double S_nrm_tot, name(se_nrm_tot)
 
  *--------------------------------------------------------------*
  
  gen quant=`q'
  gen model = 4
  keep quant model coef*  se_*
  keep if _n==1  
  append using tempcf2
  save tempcf2, replace
 } 
 
sort quant

*rename coefficients
rename coef1 native
rename coef2 foreign
rename coef3 natfor_diff

rename coef6 age_exp
rename coef7 gender_exp
rename coef8 urban_exp
rename coef9 forlang_exp
rename coef10 foreduc_exp
rename coef11 college_exp
rename coef12 voca_exp
rename coef13 tenocc_exp
rename coef14 tenfirm_exp

rename coef15 year_exp
rename coef16 state_exp
rename coef17 ind_exp


rename coef18 nra_occ_exp
rename coef19 nri_occ_exp
rename coef20 rm_occ_exp
rename coef21 nrm_occ_exp

rename coef22 nra_ind_exp
rename coef23 nri_ind_exp
rename coef24 rm_ind_exp
rename coef25 nrm_ind_exp

rename coef4 diff_exp

rename coef26 age_unexp
rename coef27 gender_unexp
rename coef28 urban_unexp
rename coef29 forlang_unexp
rename coef30 foreduc_unexp
rename coef31 college_unexp
rename coef32 voca_unexp
rename coef33 tenocc_unexp
rename coef34 tenfirm_unexp

rename coef35 year_unexp
rename coef36 state_unexp
rename coef37 ind_unexp

rename coef38 nra_occ_unexp
rename coef39 nri_occ_unexp
rename coef40 rm_occ_unexp
rename coef41 nrm_occ_unexp

rename coef42 nra_ind_unexp
rename coef43 nri_ind_unexp
rename coef44 rm_ind_unexp
rename coef45 nrm_ind_unexp

rename coef46 constant
rename coef5 diff_unexp


**relative contributions
gen age_rel = age_exp / diff_exp
gen gender_rel = gender_exp / diff_exp
gen urban_rel = urban_exp / diff_exp

gen forlang_rel = forlang_exp / diff_exp
gen foreduc_rel = foreduc_exp / diff_exp
gen college_rel = college_exp / diff_exp
gen voca_rel = voca_exp / diff_exp
gen tenocc_rel = tenocc_exp / diff_exp
gen tenfirm_rel = tenfirm_exp / diff_exp

gen year_rel = year_exp / diff_exp
gen state_rel = state_exp / diff_exp
gen ind_rel = ind_exp / diff_exp

gen nra_occ_rel = nra_occ_exp / diff_exp
gen nri_occ_rel = nri_occ_exp / diff_exp
gen rm_occ_rel = rm_occ_exp / diff_exp
gen nrm_occ_rel = nrm_occ_exp / diff_exp

gen nra_ind_rel = nra_ind_exp / diff_exp
gen nri_ind_rel = nri_ind_exp / diff_exp
gen rm_ind_rel = rm_ind_exp / diff_exp
gen nrm_ind_rel = nrm_ind_exp / diff_exp

************************************************
**total contribution from tasks
gen nra_total_exp = nra_occ_exp + nra_ind_exp
gen nri_total_exp = nri_occ_exp + nri_ind_exp
gen rm_total_exp = rm_occ_exp + rm_ind_exp
gen nrm_total_exp = nrm_occ_exp + nrm_ind_exp

**RELATIVE contribution from tasks
gen nra_total_rel = nra_occ_rel + nra_ind_rel
gen nri_total_rel = nri_occ_rel + nri_ind_rel
gen rm_total_rel = rm_occ_rel + rm_ind_rel
gen nrm_total_rel = nrm_occ_rel + nrm_ind_rel

************************************************

label var age_rel "Age"
label var gender_rel "Gender"
label var urban_rel "Urban"
label var forlang_rel "Foreign Language"
label var foreduc_rel "Foreign Education"

label var college_rel "College Degree"
label var voca_rel "Vocational Degree"
label var tenocc_rel "Tenure (Occup.)"
label var tenfirm_rel "Tenure (Firm)"

label var year_rel "Year"
label var state_rel "State"
label var ind_rel "Industry"

************************************************
label var nra_occ_rel "NR Analytic (Occup.)"
label var nri_occ_rel "NR Interactive (Occup.)"
label var rm_occ_rel "Rout. Man. (Occup.)"
label var nrm_occ_rel "NR Manual (Occup.)"

label var nra_ind_rel "NR Analytic (Indiv.)"
label var nri_ind_rel "NR Interactive (Indiv.)"
label var rm_ind_rel "Rout. Man. (Indiv.)"
label var nrm_ind_rel "NR Manual (Indiv.)"

************************************************
label var nra_total_exp "NR Analytic (Total)"
label var nri_total_exp "NR Interactive (Total)"
label var rm_total_exp "Rout. Man. (Total)"
label var nrm_total_exp "NR Manual (Total)"

label var nra_total_rel "NR Analytic (Relative)"
label var nri_total_rel "NR Interactive (Relative)"
label var rm_total_rel "Rout. Man. (Relative)"
label var nrm_total_rel "NR Manual (Relative)"

************************************************


replace quant = quant/100

*********-----------------------------**********************-----------------------------**********************

***Gen CPIs
*-------------------------------------------------------------------------------
**Wage Gap
gen lb_gap = natfor_diff - invttail(_N - 1,0.025)* se_diff1 
gen ub_gap = natfor_diff + invttail(_N - 1,0.025)* se_diff1
*-------------------------------------------------------------------------------
**Socio
gen lb_age = age_exp - invttail(_N - 1,0.025)* se_age1 
gen ub_age = age_exp + invttail(_N - 1,0.025)* se_age1

gen lb_age_rel = lb_age/diff_exp
gen ub_age_rel = ub_age/diff_exp
*-------------------------------------------------------------------------------

gen lb_gender = gender_exp - invttail(_N - 1,0.025)* se_sex1 
gen ub_gender = gender_exp + invttail(_N - 1,0.025)* se_sex1

gen lb_gender_rel = lb_gender/diff_exp
gen ub_gender_rel = ub_gender/diff_exp
*-------------------------------------------------------------------------------

gen lb_urban = urban_exp - invttail(_N - 1,0.025)* se_urban1 
gen ub_urban = urban_exp + invttail(_N - 1,0.025)* se_urban1

gen lb_urban_rel = lb_urban/diff_exp
gen ub_urban_rel = ub_urban/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Foreign
gen lb_forlang = forlang_exp - invttail(_N - 1,0.025)* se_forlang1 
gen ub_forlang = forlang_exp + invttail(_N - 1,0.025)* se_forlang1

gen lb_forlang_rel = lb_forlang/diff_exp
gen ub_forlang_rel = ub_forlang/diff_exp
*-------------------------------------------------------------------------------

gen lb_foreduc = foreduc_exp - invttail(_N - 1,0.025)* se_vocfor1 
gen ub_foreduc = foreduc_exp + invttail(_N - 1,0.025)* se_vocfor1

gen lb_foreduc_rel = lb_foreduc/diff_exp
gen ub_foreduc_rel = ub_foreduc/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Education
gen lb_college = college_exp - invttail(_N - 1,0.025)* se_edhi1 
gen ub_college = college_exp + invttail(_N - 1,0.025)* se_edhi1

gen lb_college_rel = lb_college/diff_exp
gen ub_college_rel = ub_college/diff_exp
*-------------------------------------------------------------------------------

gen lb_voca = voca_exp - invttail(_N - 1,0.025)* se_edmed1 
gen ub_voca = voca_exp + invttail(_N - 1,0.025)* se_edmed1

gen lb_voca_rel = lb_voca/diff_exp
gen ub_voca_rel = ub_voca/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Experience
gen lb_tenocc = tenocc_exp - invttail(_N - 1,0.025)* se_tenocc1 
gen ub_tenocc = tenocc_exp + invttail(_N - 1,0.025)* se_tenocc1

gen lb_tenocc_rel = lb_tenocc/diff_exp
gen ub_tenocc_rel = ub_tenocc/diff_exp
*-------------------------------------------------------------------------------

gen lb_tenfirm = tenfirm_exp - invttail(_N - 1,0.025)* se_tenfirm1 
gen ub_tenfirm = tenfirm_exp + invttail(_N - 1,0.025)* se_tenfirm1

gen lb_tenfirm_rel = lb_tenfirm/diff_exp
gen ub_tenfirm_rel = ub_tenfirm/diff_exp
*-------------------------------------------------------------------------------
*------------------------------------------------------------------------------- 
**Dummies
gen lb_year = year_exp - invttail(_N - 1,0.025)* se_yr1 
gen ub_year = year_exp + invttail(_N - 1,0.025)* se_yr1

gen lb_year_rel = lb_year/diff_exp
gen ub_year_rel = ub_year/diff_exp
*-------------------------------------------------------------------------------

gen lb_state = state_exp - invttail(_N - 1,0.025)* se_st1 
gen ub_state = state_exp + invttail(_N - 1,0.025)* se_st1

gen lb_state_rel = lb_state/diff_exp
gen ub_state_rel = ub_state/diff_exp
*-------------------------------------------------------------------------------

gen lb_ind = ind_exp - invttail(_N - 1,0.025)* se_ind1 
gen ub_ind = ind_exp + invttail(_N - 1,0.025)* se_ind1

gen lb_ind_rel = lb_ind/diff_exp
gen ub_ind_rel = ub_ind/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Tasks (Occ.)
gen lb_nra_occ = nra_occ_exp - invttail(_N - 1,0.025)* se_nra_occ1 
gen ub_nra_occ = nra_occ_exp + invttail(_N - 1,0.025)* se_nra_occ1

gen lb_nra_occ_rel = lb_nra_occ/diff_exp
gen ub_nra_occ_rel = ub_nra_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_occ = nri_occ_exp - invttail(_N - 1,0.025)* se_nri_occ1 
gen ub_nri_occ = nri_occ_exp + invttail(_N - 1,0.025)* se_nri_occ1

gen lb_nri_occ_rel = lb_nri_occ/diff_exp
gen ub_nri_occ_rel = ub_nri_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_occ = rm_occ_exp - invttail(_N - 1,0.025)* se_rm_occ1 
gen ub_rm_occ = rm_occ_exp + invttail(_N - 1,0.025)* se_rm_occ1

gen lb_rm_occ_rel = lb_rm_occ/diff_exp
gen ub_rm_occ_rel = ub_rm_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_occ = nrm_occ_exp - invttail(_N - 1,0.025)* se_nrm_occ1 
gen ub_nrm_occ = nrm_occ_exp + invttail(_N - 1,0.025)* se_nrm_occ1

gen lb_nrm_occ_rel = lb_nrm_occ/diff_exp
gen ub_nrm_occ_rel = ub_nrm_occ/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Tasks (Ind.)
gen lb_nra_ind = nra_ind_exp - invttail(_N - 1,0.025)* se_nra_ind1 
gen ub_nra_ind = nra_ind_exp + invttail(_N - 1,0.025)* se_nra_ind1

gen lb_nra_ind_rel = lb_nra_ind/diff_exp
gen ub_nra_ind_rel = ub_nra_ind/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_ind = nri_ind_exp - invttail(_N - 1,0.025)* se_nri_ind1 
gen ub_nri_ind = nri_ind_exp + invttail(_N - 1,0.025)* se_nri_ind1

gen lb_nri_ind_rel = lb_nri_ind/diff_exp
gen ub_nri_ind_rel = ub_nri_ind/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_ind = rm_ind_exp - invttail(_N - 1,0.025)* se_rm_ind1 
gen ub_rm_ind = rm_ind_exp + invttail(_N - 1,0.025)* se_rm_ind1

gen lb_rm_ind_rel = lb_rm_ind/diff_exp
gen ub_rm_ind_rel = ub_rm_ind/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_ind = nrm_ind_exp - invttail(_N - 1,0.025)* se_nrm_ind1 
gen ub_nrm_ind = nrm_ind_exp + invttail(_N - 1,0.025)* se_nrm_ind1

gen lb_nrm_ind_rel = lb_nrm_ind/diff_exp
gen ub_nrm_ind_rel = ub_nrm_ind/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 

**Tasks (Total)
gen lb_nra_tot = nra_total_exp - invttail(_N - 1,0.025)* se_nra_tot1 
gen ub_nra_tot = nra_total_exp + invttail(_N - 1,0.025)* se_nra_tot1

gen lb_nra_tot_rel = lb_nra_tot/diff_exp
gen ub_nra_tot_rel = ub_nra_tot/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_tot = nri_total_exp - invttail(_N - 1,0.025)* se_nri_tot1 
gen ub_nri_tot = nri_total_exp + invttail(_N - 1,0.025)* se_nri_tot1

gen lb_nri_tot_rel = lb_nri_tot/diff_exp
gen ub_nri_tot_rel = ub_nri_tot/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_tot = rm_total_exp - invttail(_N - 1,0.025)* se_rm_tot1 
gen ub_rm_tot = rm_total_exp + invttail(_N - 1,0.025)* se_rm_tot1

gen lb_rm_tot_rel = lb_rm_tot/diff_exp
gen ub_rm_tot_rel = ub_rm_tot/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_tot = nrm_total_exp - invttail(_N - 1,0.025)* se_nrm_tot1 
gen ub_nrm_tot = nrm_total_exp + invttail(_N - 1,0.025)* se_nrm_tot1

gen lb_nrm_tot_rel = lb_nrm_tot/diff_exp
gen ub_nrm_tot_rel = ub_nrm_tot/diff_exp

*********-----------------------------**********************-----------------------------**********************

**Graph RIF-Decompositions - Conditional Wage Gap
graph twoway connected natfor_diff quant ||  /*
   */  rarea lb_gap ub_gap quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(0(0.05)0.2) title("Native-Foreign Wage Gap: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Wage Gap" 2 "95% CI"))
graph export RIF_4_wgap00_male.png, replace

**Graph RIF-Decompositions - Socio
graph twoway (connected age_rel gender_rel urban_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_age_rel ub_age_rel quant, color(gray%20)  ||      /*
   */  rarea lb_gender_rel ub_gender_rel quant, color(gray%40)  ||      /*
   */  rarea lb_urban_rel ub_urban_rel quant, color(gray%60)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Demographics: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Age" 2 "Sex" 3 "Urban" 4 "95% CI"))
graph export RIF_4_socio00_male.png, replace
   
**Graph RIF-Decompositions - Foreign
graph twoway (connected forlang_rel foreduc_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_forlang_rel ub_forlang_rel quant, color(gray%50)  ||      /*
   */  rarea lb_foreduc_rel ub_foreduc_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Foreign Characteristics: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Foreign Language" 2 "Foreign Education" 3 "95% CI"))
graph export RIF_4_foreign00_male.png, replace

**Graph RIF-Decompositions - Education
graph twoway (connected college_rel voca_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_college_rel ub_college_rel quant, color(gray%20)  ||      /*
   */  rarea lb_voca_rel ub_voca_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Education: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "College Degree" 2 "Vocational Degree" 3 "95% CI"))
graph export RIF_4_educ00_male.png, replace

**Graph RIF-Decompositions - Experience
graph twoway (connected tenocc_rel tenfirm_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_tenocc_rel ub_tenocc_rel quant, color(gray%20)  ||      /*
   */  rarea lb_tenfirm_rel ub_tenfirm_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Experience: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Tenure (Occup.)" 2 "Tenure (Firm.)" 3 "95% CI"))
graph export RIF_4_exp00_male.png, replace

**Graph RIF-Decompositions - Dummies
graph twoway (connected year_rel state_rel ind_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_year_rel ub_year_rel quant, color(gray%70)  ||      /*
   */  rarea lb_state_rel ub_state_rel quant, color(gray%50)  ||      /*
   */  rarea lb_ind_rel ub_ind_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Other Controls: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Year" 2 "State" 3 "Industry" 4 "95% CI"))
graph export RIF_4_dummies00_male.png, replace 
   

**Graph RIF-Decompositions - Tasks NRA with CI - ind level only - relative to total task contribution
graph twoway (connected nra_ind_rel nra_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_nra_ind_rel ub_nra_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_nra_tot_rel ub_nra_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Indiv.)" 2 "NR Analytic (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_nra_ci_rel00_male.png, replace  


**Graph RIF-Decompositions - Tasks NRI with CI - ind level only - relative to total task contribution
graph twoway (connected nri_ind_rel nri_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_nri_ind_rel ub_nri_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_nri_tot_rel ub_nri_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Interactive (Indiv.)" 2 "NR Interactive (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_nri_ci_rel00_male.png, replace  


**Graph RIF-Decompositions - Tasks RM with CI - ind level only - relative to total task contribution
graph twoway (connected rm_ind_rel rm_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_rm_ind_rel ub_rm_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_rm_tot_rel ub_rm_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Rout. Manual (Indiv.)" 2 "Rout. Manual (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_rm_ci_rel00_male.png, replace  


**Graph RIF-Decompositions - Tasks NRM with CI - ind level only - relative to total task contribution
graph twoway (connected nrm_ind_rel nrm_total_rel quant, msymbol(T S) lpattern(dash solid) ) || /*
   */  rarea lb_nrm_ind_rel ub_nrm_ind_rel quant, color(gray%40)  ||      /*
   */  rarea lb_nrm_tot_rel ub_nrm_tot_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Individual: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Manual (Indiv.)" 2 "NRM Manual (Total)" 3 "95% CI"))
graph export RIF_4_tasks_ind_nrm_ci_rel00_male.png, replace  


est clear

drop native foreign natfor_diff ///
constant quant model

drop *_exp
drop *_unexp 
drop *_rel 

drop lb_* 
drop ub_* 
*********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------

********************************
**II** Occupation-level tasks only
********************************


use "$datenpfad\$BIBB_Decomp_Full", clear

set more off
save tempcf2, replace emptyok  

*******************

**Create RIFs
*foreach q of num 10 25 50 75 90 {
forvalues q = 10(10)90 {
  use "$datenpfad\$BIBB_Decomp_Full", clear

**only occupations with at least 5 observations on foreigners
merge m:1 occup_siab using $occ_for5
keep if _merge==3
drop _merge
  
 *exclude females
keep if sex==1
 
  *foreach qt of num 10 25 50 75 90 {
  forvalues qt = 10(10)90 {
   gen rif_`qt'=.
}

*foreigners
pctile eval1=wage_hlog if citizen_dummy==1 , nq(100) 
kdensity wage_hlog if citizen_dummy==1, at(eval1) gen(evalf_perc densf_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)90 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evalf_perc[`qt']+`qc'/densf_perc[`qt'] if wage_hlog>=evalf_perc[`qt'] & citizen_dummy==1
 replace rif_`qt'=evalf_perc[`qt']-(1-`qc')/densf_perc[`qt'] if wage_hlog<evalf_perc[`qt']& citizen_dummy==1
}

*natives
pctile eval2=wage_hlog if citizen_dummy==0, nq(100) 
kdensity wage_hlog if citizen_dummy==0, at(eval2) gen(evaln_perc densn_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)90 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evaln_perc[`qt']+`qc'/densn_perc[`qt'] if wage_hlog>=evaln_perc[`qt'] & citizen_dummy==0
 replace rif_`qt'=evaln_perc[`qt']-(1-`qc')/densn_perc[`qt'] if wage_hlog<evaln_perc[`qt']& citizen_dummy==0
}


**Run Decompositions on RIFs
	
eststo: xi: bootstrap, reps(100): oaxaca rif_`q' age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
	year2-year5 state2-state11 sector2-sector33 /// 
	n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt, ///
	by(citizen_dummy) cluster(id) pooled ///
	detail( ///
	Age: age agesq, /// 
	Gender: sex, ///
	Urban: urban, ///
	Foreign_Language: for_lang_ex, ///
	Foreign_Education: voca_foreign, ///
	College: educ_high, ///
	Vocational_Degree: educ_med, ///
	Tenure_Occup: occup_tenure occup_tenure_sq, ///
	Tenure_Firm: firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector2-sector33, ///
	NRA_Occ: n_rout_anal_an_occ_wt, ///
	NRI_Occ: n_rout_int_an_occ_wt, /// 
	RM_Occ: rout_man_an_occ_wt, ///
	NRM_Occ: n_rout_man_an_occ_wt) relax ///)  

  *retrive coefficients
  matrix B=e(b)
  svmat double B, name(coef)
  
  *retrive std errors
  
  matrix S_diff = _se[overall: difference]
  svmat double S_diff, name(se_diff)
  
  *-----------------
  matrix S_age = _se[explained: Age]
  svmat double S_age, name(se_age)
  
  matrix S_sex = _se[explained: Gender]
  svmat double S_sex, name(se_sex)
  
  matrix S_urban = _se[explained: Urban]
  svmat double S_urban, name(se_urban)
  *-----------------
  matrix S_forlang = _se[explained: Foreign_Language]
  svmat double S_forlang, name(se_forlang)
  
  matrix S_vocfor = _se[explained: Foreign_Education]
  svmat double S_vocfor, name(se_vocfor)
  *-----------------
  matrix S_edhi = _se[explained: College]
  svmat double S_edhi, name(se_edhi)
  
  matrix S_edmed = _se[explained: Vocational_Degree]
  svmat double S_edmed, name(se_edmed)
  *-----------------
  matrix S_tenocc= _se[explained: Tenure_Occup]
  svmat double S_tenocc, name(se_tenocc)
  
  matrix S_tenfirm = _se[explained: Tenure_Firm]
  svmat double S_tenfirm, name(se_tenfirm)
  *-----------------
  matrix S_yr = _se[explained: Year]
  svmat double S_yr, name(se_yr)
  
  matrix S_st = _se[explained: State]
  svmat double S_st, name(se_st)
  
  matrix S_ind = _se[explained: Industry]
  svmat double S_ind, name(se_ind)
  *-----------------
  matrix S_nra_occ = _se[explained: NRA_Occ]
  svmat double S_nra_occ, name(se_nra_occ)
  
  matrix S_nri_occ = _se[explained: NRI_Occ]
  svmat double S_nri_occ, name(se_nri_occ)
  
  matrix S_rm_occ = _se[explained: RM_Occ]
  svmat double S_rm_occ, name(se_rm_occ)
  
  matrix S_nrm_occ = _se[explained: NRM_Occ]
  svmat double S_nrm_occ, name(se_nrm_occ)
  *--------------------------------------------------------------*
  
  gen quant=`q'
  gen model = 2
  keep quant model coef* se_*
  keep if _n==1  
  append using tempcf2
  save tempcf2, replace
 } 
 
sort quant

**rename coefficients
rename coef1 native
rename coef2 foreign
rename coef3 natfor_diff

rename coef6 age_exp
rename coef7 gender_exp
rename coef8 urban_exp
rename coef9 forlang_exp
rename coef10 foreduc_exp
rename coef11 college_exp
rename coef12 voca_exp
rename coef13 tenocc_exp
rename coef14 tenfirm_exp

rename coef15 year_exp
rename coef16 state_exp
rename coef17 ind_exp

rename coef18 nra_exp
rename coef19 nri_exp
rename coef20 rm_exp
rename coef21 nrm_exp

rename coef4 diff_exp


rename coef22 age_unexp
rename coef23 gender_unexp
rename coef24 urban_unexp
rename coef25 forlang_unexp
rename coef26 foreduc_unexp
rename coef27 college_unexp
rename coef28 voca_unexp
rename coef29 tenocc_unexp
rename coef30 tenfirm_unexp

rename coef31 year_unexp
rename coef32 state_unexp
rename coef33 ind_unexp

rename coef34 nra_unexp
rename coef35 nri_unexp
rename coef36 rm_unexp
rename coef37 nrm_unexp

rename coef38 constant
rename coef5 diff_unexp

**relative contributions
gen age_rel = age_exp / diff_exp
gen gender_rel = gender_exp / diff_exp
gen urban_rel = urban_exp / diff_exp

gen forlang_rel = forlang_exp / diff_exp
gen foreduc_rel = foreduc_exp / diff_exp
gen college_rel = college_exp / diff_exp
gen voca_rel = voca_exp / diff_exp
gen tenocc_rel = tenocc_exp / diff_exp
gen tenfirm_rel = tenfirm_exp / diff_exp

gen year_rel = year_exp / diff_exp
gen state_rel = state_exp / diff_exp
gen ind_rel = ind_exp / diff_exp

gen nra_rel = nra_exp / diff_exp
gen nri_rel = nri_exp / diff_exp
gen rm_rel = rm_exp / diff_exp
gen nrm_rel = nrm_exp / diff_exp

label var age_rel "Age"
label var gender_rel "Gender"
label var urban_rel "Urban"
label var forlang_rel "Foreign Language"
label var foreduc_rel "Foreign Education"

label var college_rel "College Degree"
label var voca_rel "Vocational Degree"
label var tenocc_rel "Tenure (Occup.)"
label var tenfirm_rel "Tenure (Firm)"

label var year_rel "Year"
label var state_rel "State"
label var ind_rel "Industry"

label var nra_rel "NR Analytic (Occup.)"
label var nri_rel "NR Interactive (Occup.)"
label var rm_rel "Rout. Man. (Occup.)"
label var nrm_rel "NR Manual (Occup.)"

replace quant = quant/100

*********-----------------------------**********************-----------------------------**********************

***Gen CPIs
*-------------------------------------------------------------------------------
**Wage Gap
gen lb_gap = natfor_diff - invttail(_N - 1,0.025)* se_diff1 
gen ub_gap = natfor_diff + invttail(_N - 1,0.025)* se_diff1
*-------------------------------------------------------------------------------
**Socio
gen lb_age = age_exp - invttail(_N - 1,0.025)* se_age1 
gen ub_age = age_exp + invttail(_N - 1,0.025)* se_age1

gen lb_age_rel = lb_age/diff_exp
gen ub_age_rel = ub_age/diff_exp
*-------------------------------------------------------------------------------

gen lb_gender = gender_exp - invttail(_N - 1,0.025)* se_sex1 
gen ub_gender = gender_exp + invttail(_N - 1,0.025)* se_sex1

gen lb_gender_rel = lb_gender/diff_exp
gen ub_gender_rel = ub_gender/diff_exp
*-------------------------------------------------------------------------------

gen lb_urban = urban_exp - invttail(_N - 1,0.025)* se_urban1 
gen ub_urban = urban_exp + invttail(_N - 1,0.025)* se_urban1

gen lb_urban_rel = lb_urban/diff_exp
gen ub_urban_rel = ub_urban/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Foreign
gen lb_forlang = forlang_exp - invttail(_N - 1,0.025)* se_forlang1 
gen ub_forlang = forlang_exp + invttail(_N - 1,0.025)* se_forlang1

gen lb_forlang_rel = lb_forlang/diff_exp
gen ub_forlang_rel = ub_forlang/diff_exp
*-------------------------------------------------------------------------------

gen lb_foreduc = foreduc_exp - invttail(_N - 1,0.025)* se_vocfor1 
gen ub_foreduc = foreduc_exp + invttail(_N - 1,0.025)* se_vocfor1

gen lb_foreduc_rel = lb_foreduc/diff_exp
gen ub_foreduc_rel = ub_foreduc/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Education
gen lb_college = college_exp - invttail(_N - 1,0.025)* se_edhi1 
gen ub_college = college_exp + invttail(_N - 1,0.025)* se_edhi1

gen lb_college_rel = lb_college/diff_exp
gen ub_college_rel = ub_college/diff_exp
*-------------------------------------------------------------------------------

gen lb_voca = voca_exp - invttail(_N - 1,0.025)* se_edmed1 
gen ub_voca = voca_exp + invttail(_N - 1,0.025)* se_edmed1

gen lb_voca_rel = lb_voca/diff_exp
gen ub_voca_rel = ub_voca/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Experience
gen lb_tenocc = tenocc_exp - invttail(_N - 1,0.025)* se_tenocc1 
gen ub_tenocc = tenocc_exp + invttail(_N - 1,0.025)* se_tenocc1

gen lb_tenocc_rel = lb_tenocc/diff_exp
gen ub_tenocc_rel = ub_tenocc/diff_exp
*-------------------------------------------------------------------------------

gen lb_tenfirm = tenfirm_exp - invttail(_N - 1,0.025)* se_tenfirm1 
gen ub_tenfirm = tenfirm_exp + invttail(_N - 1,0.025)* se_tenfirm1

gen lb_tenfirm_rel = lb_tenfirm/diff_exp
gen ub_tenfirm_rel = ub_tenfirm/diff_exp
*-------------------------------------------------------------------------------
*------------------------------------------------------------------------------- 
**Dummies
gen lb_year = year_exp - invttail(_N - 1,0.025)* se_yr1 
gen ub_year = year_exp + invttail(_N - 1,0.025)* se_yr1

gen lb_year_rel = lb_year/diff_exp
gen ub_year_rel = ub_year/diff_exp
*-------------------------------------------------------------------------------

gen lb_state = state_exp - invttail(_N - 1,0.025)* se_st1 
gen ub_state = state_exp + invttail(_N - 1,0.025)* se_st1

gen lb_state_rel = lb_state/diff_exp
gen ub_state_rel = ub_state/diff_exp
*-------------------------------------------------------------------------------

gen lb_ind = ind_exp - invttail(_N - 1,0.025)* se_ind1 
gen ub_ind = ind_exp + invttail(_N - 1,0.025)* se_ind1

gen lb_ind_rel = lb_ind/diff_exp
gen ub_ind_rel = ub_ind/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Tasks
gen lb_nra_occ = nra_exp - invttail(_N - 1,0.025)* se_nra_occ1 
gen ub_nra_occ = nra_exp + invttail(_N - 1,0.025)* se_nra_occ1

gen lb_nra_occ_rel = lb_nra_occ/diff_exp
gen ub_nra_occ_rel = ub_nra_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_occ = nri_exp - invttail(_N - 1,0.025)* se_nri_occ1 
gen ub_nri_occ = nri_exp + invttail(_N - 1,0.025)* se_nri_occ1

gen lb_nri_occ_rel = lb_nri_occ/diff_exp
gen ub_nri_occ_rel = ub_nri_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_occ = rm_exp - invttail(_N - 1,0.025)* se_rm_occ1 
gen ub_rm_occ = rm_exp + invttail(_N - 1,0.025)* se_rm_occ1

gen lb_rm_occ_rel = lb_rm_occ/diff_exp
gen ub_rm_occ_rel = ub_rm_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_occ = nrm_exp - invttail(_N - 1,0.025)* se_nrm_occ1 
gen ub_nrm_occ = nrm_exp + invttail(_N - 1,0.025)* se_nrm_occ1

gen lb_nrm_occ_rel = lb_nrm_occ/diff_exp
gen ub_nrm_occ_rel = ub_nrm_occ/diff_exp

*********-----------------------------**********************-----------------------------**********************

**Graph RIF-Decompositions - Conditional Wage Gap
graph twoway connected natfor_diff quant ||  /*
   */  rarea lb_gap ub_gap quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(0(0.05)0.2) title("Native-Foreign Wage Gap", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Wage Gap" 2 "95% CI"))
graph export RIF_2_wgap_male.png, replace

**Graph RIF-Decompositions - Socio
graph twoway (connected age_rel gender_rel urban_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_age_rel ub_age_rel quant, color(gray%20)  ||      /*
   */  rarea lb_gender_rel ub_gender_rel quant, color(gray%40)  ||      /*
   */  rarea lb_urban_rel ub_urban_rel quant, color(gray%60)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Demographics", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Age" 2 "Sex" 3 "Urban" 4 "95% CI"))
graph export RIF_2_socio_male.png, replace
 
  
**Graph RIF-Decompositions - Foreign
graph twoway (connected forlang_rel foreduc_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_forlang_rel ub_forlang_rel quant, color(gray%50)  ||      /*
   */  rarea lb_foreduc_rel ub_foreduc_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Foreign Characteristics", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Foreign Language" 2 "Foreign Education" 3 "95% CI"))
graph export RIF_2_foreign_male.png, replace


**Graph RIF-Decompositions - Education
graph twoway (connected college_rel voca_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_college_rel ub_college_rel quant, color(gray%20)  ||      /*
   */  rarea lb_voca_rel ub_voca_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Education", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "College Degree" 2 "Vocational Degree" 3 "95% CI"))
graph export RIF_2_educ_male.png, replace


**Graph RIF-Decompositions - Experience
graph twoway (connected tenocc_rel tenfirm_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_tenocc_rel ub_tenocc_rel quant, color(gray%20)  ||      /*
   */  rarea lb_tenfirm_rel ub_tenfirm_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Experience", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Tenure (Occup.)" 2 "Tenure (Firm.)" 3 "95% CI"))
graph export RIF_2_exp_male.png, replace


**Graph RIF-Decompositions - Dummies
graph twoway (connected year_rel state_rel ind_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_year_rel ub_year_rel quant, color(gray%70)  ||      /*
   */  rarea lb_state_rel ub_state_rel quant, color(gray%50)  ||      /*
   */  rarea lb_ind_rel ub_ind_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Other Controls", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Year" 2 "State" 3 "Industry" 4 "95% CI"))
graph export RIF_2_dummies_male.png, replace 
   
   
**Graph RIF-Decompositions - Tasks
graph twoway (connected nra_rel nri_rel rm_rel nrm_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%50)  ||      /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Occupational", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_2_tasks_male.png, replace 
   

  
**Graph RIF-Decompositions - Tasks NRI and NRA with CI
graph twoway (connected nra_rel nri_rel rm_rel nrm_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%00)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%00)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Occupational", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_2_tasks_cog_ci_male.png, replace   


**Graph RIF-Decompositions - Tasks Manual with CI
graph twoway (connected nra_rel nri_rel rm_rel nrm_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%00)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%00)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Occupational", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_2_tasks_man_ci_male.png, replace 



est clear

drop native foreign natfor_diff ///
quant constant model

drop *_exp
drop *_unexp 
drop *_rel 

drop lb_* 
drop ub_* 
********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------
   
*****1990s
  
*********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------

*2. occ task

set more off
save tempcf2, replace emptyok  

**Create RIFs
*foreach q of num 10 25 50 75 90 {
forvalues q = 10(10)80 {
  use "$datenpfad\$BIBB_Decomp_Full", clear

**only occupations with at least 5 observations on foreigners
merge m:1 occup_siab using $occ_for5
keep if _merge==3
drop _merge


keep if year < 2000

 *exclude females
keep if sex==1

  *foreach qt of num 10 25 50 75 90 {
  forvalues qt = 10(10)80 {
   gen rif_`qt'=.
}

*foreigners
pctile eval1=wage_hlog if citizen_dummy==1 , nq(100) 
kdensity wage_hlog if citizen_dummy==1, at(eval1) gen(evalf_perc densf_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)80 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evalf_perc[`qt']+`qc'/densf_perc[`qt'] if wage_hlog>=evalf_perc[`qt'] & citizen_dummy==1
 replace rif_`qt'=evalf_perc[`qt']-(1-`qc')/densf_perc[`qt'] if wage_hlog<evalf_perc[`qt']& citizen_dummy==1
}

*natives
pctile eval2=wage_hlog if citizen_dummy==0, nq(100) 
kdensity wage_hlog if citizen_dummy==0, at(eval2) gen(evaln_perc densn_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)80 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evaln_perc[`qt']+`qc'/densn_perc[`qt'] if wage_hlog>=evaln_perc[`qt'] & citizen_dummy==0
 replace rif_`qt'=evaln_perc[`qt']-(1-`qc')/densn_perc[`qt'] if wage_hlog<evaln_perc[`qt']& citizen_dummy==0
}


**Run Decompositions on RIFs
	
*2. occ.task broad	
eststo: xi: bootstrap, reps(100): oaxaca rif_`q' age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
	year2-year5 state2-state11 sector2-sector33 /// 
	n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt, ///
	by(citizen_dummy) cluster(id) pooled ///
	detail( ///
	Age: age agesq, /// 
	Gender: sex, ///
	Urban: urban, ///
	Foreign_Language: for_lang_ex, ///
	Foreign_Education: voca_foreign, ///
	College: educ_high, ///
	Vocational_Degree: educ_med, ///
	Tenure_Occup: occup_tenure occup_tenure_sq, ///
	Tenure_Firm: firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector2-sector33, ///
	NRA_Occ: n_rout_anal_an_occ_wt, ///
	NRI_Occ: n_rout_int_an_occ_wt, /// 
	RM_Occ: rout_man_an_occ_wt, ///
	NRM_Occ: n_rout_man_an_occ_wt) relax ///)  

  *retrive coefficients
  matrix B=e(b)
  svmat double B, name(coef)
  
  *retrive std errors
  
  matrix S_diff = _se[overall: difference]
  svmat double S_diff, name(se_diff)
  
  *-----------------
  matrix S_age = _se[explained: Age]
  svmat double S_age, name(se_age)
  
  matrix S_sex = _se[explained: Gender]
  svmat double S_sex, name(se_sex)
  
  matrix S_urban = _se[explained: Urban]
  svmat double S_urban, name(se_urban)
  *-----------------
  matrix S_forlang = _se[explained: Foreign_Language]
  svmat double S_forlang, name(se_forlang)
  
  matrix S_vocfor = _se[explained: Foreign_Education]
  svmat double S_vocfor, name(se_vocfor)
  *-----------------
  matrix S_edhi = _se[explained: College]
  svmat double S_edhi, name(se_edhi)
  
  matrix S_edmed = _se[explained: Vocational_Degree]
  svmat double S_edmed, name(se_edmed)
  *-----------------
  matrix S_tenocc= _se[explained: Tenure_Occup]
  svmat double S_tenocc, name(se_tenocc)
  
  matrix S_tenfirm = _se[explained: Tenure_Firm]
  svmat double S_tenfirm, name(se_tenfirm)
  *-----------------
  matrix S_yr = _se[explained: Year]
  svmat double S_yr, name(se_yr)
  
  matrix S_st = _se[explained: State]
  svmat double S_st, name(se_st)
  
  matrix S_ind = _se[explained: Industry]
  svmat double S_ind, name(se_ind)
  *-----------------
  matrix S_nra_occ = _se[explained: NRA_Occ]
  svmat double S_nra_occ, name(se_nra_occ)
  
  matrix S_nri_occ = _se[explained: NRI_Occ]
  svmat double S_nri_occ, name(se_nri_occ)
  
  matrix S_rm_occ = _se[explained: RM_Occ]
  svmat double S_rm_occ, name(se_rm_occ)
  
  matrix S_nrm_occ = _se[explained: NRM_Occ]
  svmat double S_nrm_occ, name(se_nrm_occ)
  *--------------------------------------------------------------*
  
  gen quant=`q'
  gen model = 2
  keep quant model coef* se_*
  keep if _n==1  
  append using tempcf2
  save tempcf2, replace
 } 
 
sort quant

**rename coefficients
rename coef1 native
rename coef2 foreign
rename coef3 natfor_diff

rename coef6 age_exp
rename coef7 gender_exp
rename coef8 urban_exp
rename coef9 forlang_exp
rename coef10 foreduc_exp
rename coef11 college_exp
rename coef12 voca_exp
rename coef13 tenocc_exp
rename coef14 tenfirm_exp

rename coef15 year_exp
rename coef16 state_exp
rename coef17 ind_exp

rename coef18 nra_exp
rename coef19 nri_exp
rename coef20 rm_exp
rename coef21 nrm_exp

rename coef4 diff_exp


rename coef22 age_unexp
rename coef23 gender_unexp
rename coef24 urban_unexp
rename coef25 forlang_unexp
rename coef26 foreduc_unexp
rename coef27 college_unexp
rename coef28 voca_unexp
rename coef29 tenocc_unexp
rename coef30 tenfirm_unexp

rename coef31 year_unexp
rename coef32 state_unexp
rename coef33 ind_unexp

rename coef34 nra_unexp
rename coef35 nri_unexp
rename coef36 rm_unexp
rename coef37 nrm_unexp

rename coef38 constant
rename coef5 diff_unexp

**relative contributions
gen age_rel = age_exp / diff_exp
gen gender_rel = gender_exp / diff_exp
gen urban_rel = urban_exp / diff_exp

gen forlang_rel = forlang_exp / diff_exp
gen foreduc_rel = foreduc_exp / diff_exp
gen college_rel = college_exp / diff_exp
gen voca_rel = voca_exp / diff_exp
gen tenocc_rel = tenocc_exp / diff_exp
gen tenfirm_rel = tenfirm_exp / diff_exp

gen year_rel = year_exp / diff_exp
gen state_rel = state_exp / diff_exp
gen ind_rel = ind_exp / diff_exp

gen nra_rel = nra_exp / diff_exp
gen nri_rel = nri_exp / diff_exp
gen rm_rel = rm_exp / diff_exp
gen nrm_rel = nrm_exp / diff_exp

label var age_rel "Age"
label var gender_rel "Gender"
label var urban_rel "Urban"
label var forlang_rel "Foreign Language"
label var foreduc_rel "Foreign Education"

label var college_rel "College Degree"
label var voca_rel "Vocational Degree"
label var tenocc_rel "Tenure (Occup.)"
label var tenfirm_rel "Tenure (Firm)"

label var year_rel "Year"
label var state_rel "State"
label var ind_rel "Industry"

label var nra_rel "NR Analytic (Occup.)"
label var nri_rel "NR Interactive (Occup.)"
label var rm_rel "Rout. Man. (Occup.)"
label var nrm_rel "NR Manual (Occup.)"

replace quant = quant/100

*********-----------------------------**********************-----------------------------**********************

***Gen CPIs
*-------------------------------------------------------------------------------
**Wage Gap
gen lb_gap = natfor_diff - invttail(_N - 1,0.025)* se_diff1 
gen ub_gap = natfor_diff + invttail(_N - 1,0.025)* se_diff1
*-------------------------------------------------------------------------------
**Socio
gen lb_age = age_exp - invttail(_N - 1,0.025)* se_age1 
gen ub_age = age_exp + invttail(_N - 1,0.025)* se_age1

gen lb_age_rel = lb_age/diff_exp
gen ub_age_rel = ub_age/diff_exp
*-------------------------------------------------------------------------------

gen lb_gender = gender_exp - invttail(_N - 1,0.025)* se_sex1 
gen ub_gender = gender_exp + invttail(_N - 1,0.025)* se_sex1

gen lb_gender_rel = lb_gender/diff_exp
gen ub_gender_rel = ub_gender/diff_exp
*-------------------------------------------------------------------------------

gen lb_urban = urban_exp - invttail(_N - 1,0.025)* se_urban1 
gen ub_urban = urban_exp + invttail(_N - 1,0.025)* se_urban1

gen lb_urban_rel = lb_urban/diff_exp
gen ub_urban_rel = ub_urban/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Foreign
gen lb_forlang = forlang_exp - invttail(_N - 1,0.025)* se_forlang1 
gen ub_forlang = forlang_exp + invttail(_N - 1,0.025)* se_forlang1

gen lb_forlang_rel = lb_forlang/diff_exp
gen ub_forlang_rel = ub_forlang/diff_exp
*-------------------------------------------------------------------------------

gen lb_foreduc = foreduc_exp - invttail(_N - 1,0.025)* se_vocfor1 
gen ub_foreduc = foreduc_exp + invttail(_N - 1,0.025)* se_vocfor1

gen lb_foreduc_rel = lb_foreduc/diff_exp
gen ub_foreduc_rel = ub_foreduc/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Education
gen lb_college = college_exp - invttail(_N - 1,0.025)* se_edhi1 
gen ub_college = college_exp + invttail(_N - 1,0.025)* se_edhi1

gen lb_college_rel = lb_college/diff_exp
gen ub_college_rel = ub_college/diff_exp
*-------------------------------------------------------------------------------

gen lb_voca = voca_exp - invttail(_N - 1,0.025)* se_edmed1 
gen ub_voca = voca_exp + invttail(_N - 1,0.025)* se_edmed1

gen lb_voca_rel = lb_voca/diff_exp
gen ub_voca_rel = ub_voca/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Experience
gen lb_tenocc = tenocc_exp - invttail(_N - 1,0.025)* se_tenocc1 
gen ub_tenocc = tenocc_exp + invttail(_N - 1,0.025)* se_tenocc1

gen lb_tenocc_rel = lb_tenocc/diff_exp
gen ub_tenocc_rel = ub_tenocc/diff_exp
*-------------------------------------------------------------------------------

gen lb_tenfirm = tenfirm_exp - invttail(_N - 1,0.025)* se_tenfirm1 
gen ub_tenfirm = tenfirm_exp + invttail(_N - 1,0.025)* se_tenfirm1

gen lb_tenfirm_rel = lb_tenfirm/diff_exp
gen ub_tenfirm_rel = ub_tenfirm/diff_exp
*-------------------------------------------------------------------------------
*------------------------------------------------------------------------------- 
**Dummies
gen lb_year = year_exp - invttail(_N - 1,0.025)* se_yr1 
gen ub_year = year_exp + invttail(_N - 1,0.025)* se_yr1

gen lb_year_rel = lb_year/diff_exp
gen ub_year_rel = ub_year/diff_exp
*-------------------------------------------------------------------------------

gen lb_state = state_exp - invttail(_N - 1,0.025)* se_st1 
gen ub_state = state_exp + invttail(_N - 1,0.025)* se_st1

gen lb_state_rel = lb_state/diff_exp
gen ub_state_rel = ub_state/diff_exp
*-------------------------------------------------------------------------------

gen lb_ind = ind_exp - invttail(_N - 1,0.025)* se_ind1 
gen ub_ind = ind_exp + invttail(_N - 1,0.025)* se_ind1

gen lb_ind_rel = lb_ind/diff_exp
gen ub_ind_rel = ub_ind/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Tasks
gen lb_nra_occ = nra_exp - invttail(_N - 1,0.025)* se_nra_occ1 
gen ub_nra_occ = nra_exp + invttail(_N - 1,0.025)* se_nra_occ1

gen lb_nra_occ_rel = lb_nra_occ/diff_exp
gen ub_nra_occ_rel = ub_nra_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_occ = nri_exp - invttail(_N - 1,0.025)* se_nri_occ1 
gen ub_nri_occ = nri_exp + invttail(_N - 1,0.025)* se_nri_occ1

gen lb_nri_occ_rel = lb_nri_occ/diff_exp
gen ub_nri_occ_rel = ub_nri_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_occ = rm_exp - invttail(_N - 1,0.025)* se_rm_occ1 
gen ub_rm_occ = rm_exp + invttail(_N - 1,0.025)* se_rm_occ1

gen lb_rm_occ_rel = lb_rm_occ/diff_exp
gen ub_rm_occ_rel = ub_rm_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_occ = nrm_exp - invttail(_N - 1,0.025)* se_nrm_occ1 
gen ub_nrm_occ = nrm_exp + invttail(_N - 1,0.025)* se_nrm_occ1

gen lb_nrm_occ_rel = lb_nrm_occ/diff_exp
gen ub_nrm_occ_rel = ub_nrm_occ/diff_exp

*********-----------------------------**********************-----------------------------**********************

**Graph RIF-Decompositions - Conditional Wage Gap
graph twoway connected natfor_diff quant ||  /*
   */  rarea lb_gap ub_gap quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(0(0.05)0.2) title("Native-Foreign Wage Gap: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Wage Gap" 2 "95% CI"))
graph export RIF_2_wgap90_male.png, replace

**Graph RIF-Decompositions - Socio
graph twoway (connected age_rel gender_rel urban_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_age_rel ub_age_rel quant, color(gray%20)  ||      /*
   */  rarea lb_gender_rel ub_gender_rel quant, color(gray%40)  ||      /*
   */  rarea lb_urban_rel ub_urban_rel quant, color(gray%60)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Demographics: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Age" 2 "Sex" 3 "Urban" 4 "95% CI"))
graph export RIF_2_socio90_male.png, replace
 
  
**Graph RIF-Decompositions - Foreign
graph twoway (connected forlang_rel foreduc_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_forlang_rel ub_forlang_rel quant, color(gray%50)  ||      /*
   */  rarea lb_foreduc_rel ub_foreduc_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Foreign Characteristics: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Foreign Language" 2 "Foreign Education" 3 "95% CI"))
graph export RIF_2_foreign90_male.png, replace


**Graph RIF-Decompositions - Education
graph twoway (connected college_rel voca_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_college_rel ub_college_rel quant, color(gray%20)  ||      /*
   */  rarea lb_voca_rel ub_voca_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Education: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "College Degree" 2 "Vocational Degree" 3 "95% CI"))
graph export RIF_2_educ90_male.png, replace


**Graph RIF-Decompositions - Experience
graph twoway (connected tenocc_rel tenfirm_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_tenocc_rel ub_tenocc_rel quant, color(gray%20)  ||      /*
   */  rarea lb_tenfirm_rel ub_tenfirm_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Experience: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Tenure (Occup.)" 2 "Tenure (Firm.)" 3 "95% CI"))
graph export RIF_2_exp90_male.png, replace


**Graph RIF-Decompositions - Dummies
graph twoway (connected year_rel state_rel ind_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_year_rel ub_year_rel quant, color(gray%70)  ||      /*
   */  rarea lb_state_rel ub_state_rel quant, color(gray%50)  ||      /*
   */  rarea lb_ind_rel ub_ind_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Other Controls: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Year" 2 "State" 3 "Industry" 4 "95% CI"))
graph export RIF_2_dummies90_male.png, replace 
   
   
**Graph RIF-Decompositions - Tasks
graph twoway (connected nra_rel nri_rel rm_rel nrm_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%50)  ||      /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Occupational: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_2_tasks90_male.png, replace 
   

  
**Graph RIF-Decompositions - Tasks NRI and NRA with CI
graph twoway (connected nra_rel nri_rel rm_rel nrm_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%00)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%00)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-1(0.5)2) title("Tasks - Occupational: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_2_tasks90_cog_ci_male.png, replace   


**Graph RIF-Decompositions - Tasks Manual with CI
graph twoway (connected nra_rel nri_rel rm_rel nrm_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%00)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%00)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-1(0.5)2) title("Tasks - Occupational: 1992-1999", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_2_tasks90_man_ci_male.png, replace 



est clear

drop native foreign natfor_diff ///
quant constant model

drop *_exp
drop *_unexp 
drop *_rel 

drop lb_* 
drop ub_* 

*********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------
 
   *****2000s

*********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------

*/

*2. occ task

set more off
save tempcf2, replace emptyok  

**Create RIFs
*foreach q of num 10 25 50 75 90 {
forvalues q = 10(10)90 {
  use "$datenpfad\$BIBB_Decomp_Full", clear

**only occupations with at least 5 observations on foreigners
merge m:1 occup_siab using $occ_for5
keep if _merge==3
drop _merge
  
keep if year > 2000
  
  *exclude females
keep if sex==1

  *foreach qt of num 10 25 50 75 90 {
  forvalues qt = 10(10)90 {
   gen rif_`qt'=.
}

*foreigners
pctile eval1=wage_hlog if citizen_dummy==1 , nq(100) 
kdensity wage_hlog if citizen_dummy==1, at(eval1) gen(evalf_perc densf_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)90 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evalf_perc[`qt']+`qc'/densf_perc[`qt'] if wage_hlog>=evalf_perc[`qt'] & citizen_dummy==1
 replace rif_`qt'=evalf_perc[`qt']-(1-`qc')/densf_perc[`qt'] if wage_hlog<evalf_perc[`qt']& citizen_dummy==1
}

*natives
pctile eval2=wage_hlog if citizen_dummy==0, nq(100) 
kdensity wage_hlog if citizen_dummy==0, at(eval2) gen(evaln_perc densn_perc) nograph 
*width(0.10)

*foreach qt of num 10 25 50 75 90 {
forvalues qt = 10(10)90 {	
 local qc = `qt'/100.0
 replace rif_`qt'=evaln_perc[`qt']+`qc'/densn_perc[`qt'] if wage_hlog>=evaln_perc[`qt'] & citizen_dummy==0
 replace rif_`qt'=evaln_perc[`qt']-(1-`qc')/densn_perc[`qt'] if wage_hlog<evaln_perc[`qt']& citizen_dummy==0
}


**Run Decompositions on RIFs
	
*2. occ.task broad	
eststo: xi: bootstrap, reps(100): oaxaca rif_`q' age agesq sex urban for_lang_ex voca_foreign educ_high educ_med occup_tenure firm_tenure occup_tenure_sq firm_tenure_sq ///
	year2-year5 state2-state11 sector2-sector33 /// 
	n_rout_anal_an_occ_wt n_rout_int_an_occ_wt rout_man_an_occ_wt n_rout_man_an_occ_wt, ///
	by(citizen_dummy) cluster(id) pooled ///
	detail( ///
	Age: age agesq, /// 
	Gender: sex, ///
	Urban: urban, ///
	Foreign_Language: for_lang_ex, ///
	Foreign_Education: voca_foreign, ///
	College: educ_high, ///
	Vocational_Degree: educ_med, ///
	Tenure_Occup: occup_tenure occup_tenure_sq, ///
	Tenure_Firm: firm_tenure firm_tenure_sq, ///
	Year: year2-year5, ///
	State: state2-state11, ///
	Industry: sector2-sector33, ///
	NRA_Occ: n_rout_anal_an_occ_wt, ///
	NRI_Occ: n_rout_int_an_occ_wt, /// 
	RM_Occ: rout_man_an_occ_wt, ///
	NRM_Occ: n_rout_man_an_occ_wt) relax ///)  

  *retrive coefficients
  matrix B=e(b)
  svmat double B, name(coef)
  
  *retrive std errors
  
  matrix S_diff = _se[overall: difference]
  svmat double S_diff, name(se_diff)
  
  *-----------------
  matrix S_age = _se[explained: Age]
  svmat double S_age, name(se_age)
  
  matrix S_sex = _se[explained: Gender]
  svmat double S_sex, name(se_sex)
  
  matrix S_urban = _se[explained: Urban]
  svmat double S_urban, name(se_urban)
  *-----------------
  matrix S_forlang = _se[explained: Foreign_Language]
  svmat double S_forlang, name(se_forlang)
  
  matrix S_vocfor = _se[explained: Foreign_Education]
  svmat double S_vocfor, name(se_vocfor)
  *-----------------
  matrix S_edhi = _se[explained: College]
  svmat double S_edhi, name(se_edhi)
  
  matrix S_edmed = _se[explained: Vocational_Degree]
  svmat double S_edmed, name(se_edmed)
  *-----------------
  matrix S_tenocc= _se[explained: Tenure_Occup]
  svmat double S_tenocc, name(se_tenocc)
  
  matrix S_tenfirm = _se[explained: Tenure_Firm]
  svmat double S_tenfirm, name(se_tenfirm)
  *-----------------
  matrix S_yr = _se[explained: Year]
  svmat double S_yr, name(se_yr)
  
  matrix S_st = _se[explained: State]
  svmat double S_st, name(se_st)
  
  matrix S_ind = _se[explained: Industry]
  svmat double S_ind, name(se_ind)
  *-----------------
  matrix S_nra_occ = _se[explained: NRA_Occ]
  svmat double S_nra_occ, name(se_nra_occ)
  
  matrix S_nri_occ = _se[explained: NRI_Occ]
  svmat double S_nri_occ, name(se_nri_occ)
  
  matrix S_rm_occ = _se[explained: RM_Occ]
  svmat double S_rm_occ, name(se_rm_occ)
  
  matrix S_nrm_occ = _se[explained: NRM_Occ]
  svmat double S_nrm_occ, name(se_nrm_occ)
  *--------------------------------------------------------------*
  
  gen quant=`q'
  gen model = 2
  keep quant model coef* se_*
  keep if _n==1  
  append using tempcf2
  save tempcf2, replace
 } 
 
sort quant

**rename coefficients
rename coef1 native
rename coef2 foreign
rename coef3 natfor_diff

rename coef6 age_exp
rename coef7 gender_exp
rename coef8 urban_exp
rename coef9 forlang_exp
rename coef10 foreduc_exp
rename coef11 college_exp
rename coef12 voca_exp
rename coef13 tenocc_exp
rename coef14 tenfirm_exp

rename coef15 year_exp
rename coef16 state_exp
rename coef17 ind_exp

rename coef18 nra_exp
rename coef19 nri_exp
rename coef20 rm_exp
rename coef21 nrm_exp

rename coef4 diff_exp


rename coef22 age_unexp
rename coef23 gender_unexp
rename coef24 urban_unexp
rename coef25 forlang_unexp
rename coef26 foreduc_unexp
rename coef27 college_unexp
rename coef28 voca_unexp
rename coef29 tenocc_unexp
rename coef30 tenfirm_unexp

rename coef31 year_unexp
rename coef32 state_unexp
rename coef33 ind_unexp

rename coef34 nra_unexp
rename coef35 nri_unexp
rename coef36 rm_unexp
rename coef37 nrm_unexp

rename coef38 constant
rename coef5 diff_unexp

**relative contributions
gen age_rel = age_exp / diff_exp
gen gender_rel = gender_exp / diff_exp
gen urban_rel = urban_exp / diff_exp

gen forlang_rel = forlang_exp / diff_exp
gen foreduc_rel = foreduc_exp / diff_exp
gen college_rel = college_exp / diff_exp
gen voca_rel = voca_exp / diff_exp
gen tenocc_rel = tenocc_exp / diff_exp
gen tenfirm_rel = tenfirm_exp / diff_exp

gen year_rel = year_exp / diff_exp
gen state_rel = state_exp / diff_exp
gen ind_rel = ind_exp / diff_exp

gen nra_rel = nra_exp / diff_exp
gen nri_rel = nri_exp / diff_exp
gen rm_rel = rm_exp / diff_exp
gen nrm_rel = nrm_exp / diff_exp

label var age_rel "Age"
label var gender_rel "Gender"
label var urban_rel "Urban"
label var forlang_rel "Foreign Language"
label var foreduc_rel "Foreign Education"

label var college_rel "College Degree"
label var voca_rel "Vocational Degree"
label var tenocc_rel "Tenure (Occup.)"
label var tenfirm_rel "Tenure (Firm)"

label var year_rel "Year"
label var state_rel "State"
label var ind_rel "Industry"

label var nra_rel "NR Analytic (Occup.)"
label var nri_rel "NR Interactive (Occup.)"
label var rm_rel "Rout. Man. (Occup.)"
label var nrm_rel "NR Manual (Occup.)"

replace quant = quant/100

*********-----------------------------**********************-----------------------------**********************

***Gen CPIs
*-------------------------------------------------------------------------------
**Wage Gap
gen lb_gap = natfor_diff - invttail(_N - 1,0.025)* se_diff1 
gen ub_gap = natfor_diff + invttail(_N - 1,0.025)* se_diff1
*-------------------------------------------------------------------------------
**Socio
gen lb_age = age_exp - invttail(_N - 1,0.025)* se_age1 
gen ub_age = age_exp + invttail(_N - 1,0.025)* se_age1

gen lb_age_rel = lb_age/diff_exp
gen ub_age_rel = ub_age/diff_exp
*-------------------------------------------------------------------------------

gen lb_gender = gender_exp - invttail(_N - 1,0.025)* se_sex1 
gen ub_gender = gender_exp + invttail(_N - 1,0.025)* se_sex1

gen lb_gender_rel = lb_gender/diff_exp
gen ub_gender_rel = ub_gender/diff_exp
*-------------------------------------------------------------------------------

gen lb_urban = urban_exp - invttail(_N - 1,0.025)* se_urban1 
gen ub_urban = urban_exp + invttail(_N - 1,0.025)* se_urban1

gen lb_urban_rel = lb_urban/diff_exp
gen ub_urban_rel = ub_urban/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Foreign
gen lb_forlang = forlang_exp - invttail(_N - 1,0.025)* se_forlang1 
gen ub_forlang = forlang_exp + invttail(_N - 1,0.025)* se_forlang1

gen lb_forlang_rel = lb_forlang/diff_exp
gen ub_forlang_rel = ub_forlang/diff_exp
*-------------------------------------------------------------------------------

gen lb_foreduc = foreduc_exp - invttail(_N - 1,0.025)* se_vocfor1 
gen ub_foreduc = foreduc_exp + invttail(_N - 1,0.025)* se_vocfor1

gen lb_foreduc_rel = lb_foreduc/diff_exp
gen ub_foreduc_rel = ub_foreduc/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Education
gen lb_college = college_exp - invttail(_N - 1,0.025)* se_edhi1 
gen ub_college = college_exp + invttail(_N - 1,0.025)* se_edhi1

gen lb_college_rel = lb_college/diff_exp
gen ub_college_rel = ub_college/diff_exp
*-------------------------------------------------------------------------------

gen lb_voca = voca_exp - invttail(_N - 1,0.025)* se_edmed1 
gen ub_voca = voca_exp + invttail(_N - 1,0.025)* se_edmed1

gen lb_voca_rel = lb_voca/diff_exp
gen ub_voca_rel = ub_voca/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Experience
gen lb_tenocc = tenocc_exp - invttail(_N - 1,0.025)* se_tenocc1 
gen ub_tenocc = tenocc_exp + invttail(_N - 1,0.025)* se_tenocc1

gen lb_tenocc_rel = lb_tenocc/diff_exp
gen ub_tenocc_rel = ub_tenocc/diff_exp
*-------------------------------------------------------------------------------

gen lb_tenfirm = tenfirm_exp - invttail(_N - 1,0.025)* se_tenfirm1 
gen ub_tenfirm = tenfirm_exp + invttail(_N - 1,0.025)* se_tenfirm1

gen lb_tenfirm_rel = lb_tenfirm/diff_exp
gen ub_tenfirm_rel = ub_tenfirm/diff_exp
*-------------------------------------------------------------------------------
*------------------------------------------------------------------------------- 
**Dummies
gen lb_year = year_exp - invttail(_N - 1,0.025)* se_yr1 
gen ub_year = year_exp + invttail(_N - 1,0.025)* se_yr1

gen lb_year_rel = lb_year/diff_exp
gen ub_year_rel = ub_year/diff_exp
*-------------------------------------------------------------------------------

gen lb_state = state_exp - invttail(_N - 1,0.025)* se_st1 
gen ub_state = state_exp + invttail(_N - 1,0.025)* se_st1

gen lb_state_rel = lb_state/diff_exp
gen ub_state_rel = ub_state/diff_exp
*-------------------------------------------------------------------------------

gen lb_ind = ind_exp - invttail(_N - 1,0.025)* se_ind1 
gen ub_ind = ind_exp + invttail(_N - 1,0.025)* se_ind1

gen lb_ind_rel = lb_ind/diff_exp
gen ub_ind_rel = ub_ind/diff_exp
*------------------------------------------------------------------------------- 
*------------------------------------------------------------------------------- 
**Tasks
gen lb_nra_occ = nra_exp - invttail(_N - 1,0.025)* se_nra_occ1 
gen ub_nra_occ = nra_exp + invttail(_N - 1,0.025)* se_nra_occ1

gen lb_nra_occ_rel = lb_nra_occ/diff_exp
gen ub_nra_occ_rel = ub_nra_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nri_occ = nri_exp - invttail(_N - 1,0.025)* se_nri_occ1 
gen ub_nri_occ = nri_exp + invttail(_N - 1,0.025)* se_nri_occ1

gen lb_nri_occ_rel = lb_nri_occ/diff_exp
gen ub_nri_occ_rel = ub_nri_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_rm_occ = rm_exp - invttail(_N - 1,0.025)* se_rm_occ1 
gen ub_rm_occ = rm_exp + invttail(_N - 1,0.025)* se_rm_occ1

gen lb_rm_occ_rel = lb_rm_occ/diff_exp
gen ub_rm_occ_rel = ub_rm_occ/diff_exp
*-------------------------------------------------------------------------------

gen lb_nrm_occ = nrm_exp - invttail(_N - 1,0.025)* se_nrm_occ1 
gen ub_nrm_occ = nrm_exp + invttail(_N - 1,0.025)* se_nrm_occ1

gen lb_nrm_occ_rel = lb_nrm_occ/diff_exp
gen ub_nrm_occ_rel = ub_nrm_occ/diff_exp

*********-----------------------------**********************-----------------------------**********************

**Graph RIF-Decompositions - Conditional Wage Gap
graph twoway connected natfor_diff quant ||  /*
   */  rarea lb_gap ub_gap quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(0(0.05)0.2) title("Native-Foreign Wage Gap: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Wage Gap" 2 "95% CI"))
graph export RIF_2_wgap00_male.png, replace

**Graph RIF-Decompositions - Socio
graph twoway (connected age_rel gender_rel urban_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_age_rel ub_age_rel quant, color(gray%20)  ||      /*
   */  rarea lb_gender_rel ub_gender_rel quant, color(gray%40)  ||      /*
   */  rarea lb_urban_rel ub_urban_rel quant, color(gray%60)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Demographics: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Age" 2 "Sex" 3 "Urban" 4 "95% CI"))
graph export RIF_2_socio00_male.png, replace
 
  
**Graph RIF-Decompositions - Foreign
graph twoway (connected forlang_rel foreduc_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_forlang_rel ub_forlang_rel quant, color(gray%50)  ||      /*
   */  rarea lb_foreduc_rel ub_foreduc_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Foreign Characteristics: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Foreign Language" 2 "Foreign Education" 3 "95% CI"))
graph export RIF_2_foreign00_male.png, replace


**Graph RIF-Decompositions - Education
graph twoway (connected college_rel voca_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_college_rel ub_college_rel quant, color(gray%20)  ||      /*
   */  rarea lb_voca_rel ub_voca_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Education: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "College Degree" 2 "Vocational Degree" 3 "95% CI"))
graph export RIF_2_educ00_male.png, replace


**Graph RIF-Decompositions - Experience
graph twoway (connected tenocc_rel tenfirm_rel quant, msymbol(D U) lpattern(solid dash) ) || /*
   */  rarea lb_tenocc_rel ub_tenocc_rel quant, color(gray%20)  ||      /*
   */  rarea lb_tenfirm_rel ub_tenfirm_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Experience: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Tenure (Occup.)" 2 "Tenure (Firm.)" 3 "95% CI"))
graph export RIF_2_exp00_male.png, replace


**Graph RIF-Decompositions - Dummies
graph twoway (connected year_rel state_rel ind_rel quant, msymbol(D U S) lpattern(solid dash dot) ) || /*
   */  rarea lb_year_rel ub_year_rel quant, color(gray%70)  ||      /*
   */  rarea lb_state_rel ub_state_rel quant, color(gray%50)  ||      /*
   */  rarea lb_ind_rel ub_ind_rel quant, color(gray%30)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Other Controls: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "Year" 2 "State" 3 "Industry" 4 "95% CI"))
graph export RIF_2_dummies00_male.png, replace 
   
   
**Graph RIF-Decompositions - Tasks
graph twoway (connected nra_rel nri_rel rm_rel nrm_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%50)  ||      /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%20)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Occupational: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_2_tasks00_male.png, replace 
   

  
**Graph RIF-Decompositions - Tasks NRI and NRA with CI
graph twoway (connected nra_rel nri_rel rm_rel nrm_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%00)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%00)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Occupational: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_2_tasks00_cog_ci_male.png, replace   


**Graph RIF-Decompositions - Tasks Manual with CI
graph twoway (connected nra_rel nri_rel rm_rel nrm_rel quant, msymbol(D U S T) lpattern(solid dash dot shortdash_dot) ) || /*
   */  rarea lb_rm_occ_rel ub_rm_occ_rel quant, color(gray%30)  ||      /*
   */  rarea lb_nrm_occ_rel ub_nrm_occ_rel quant, color(gray%70)  ||      /*
   */  rarea lb_nra_occ_rel ub_nra_occ_rel quant, color(gray%00)  ||      /*
   */  rarea lb_nri_occ_rel ub_nri_occ_rel quant, color(gray%00)  ||      /*
   */, xlabel(0.0 .2 .4 .6 .8 1) ylabel(-.5(0.25)1) title("Tasks - Occupational: 2006-2018", size(medium)) ytitle("Percent", size(small)) xtitle("Quantile", size(small)) /*
   */  yline(0.0, lw(thin) lc(black)) legend(order(1 "NR Analytic (Occup.)" 2 "NR Interactive (Occup.)" 3 "Rout. Man. (Occup.)" 4 "NR Manual (Occup.)" 5 "95% CI"))
graph export RIF_2_tasks00_man_ci_male.png, replace 


dsaf
est clear

drop native foreign natfor_diff ///
quant constant model

drop *_exp
drop *_unexp 
drop *_rel 

drop lb_* 
drop ub_* 
*********-----------------------*******************---------------------***************---------------------
*********-----------------------*******************---------------------***************---------------------


log close
exit
