


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
global bibb_79 BIBB_1979.dta
global bibb_86 BIBB_1986.dta
global bibb_92 BIBB_1992.dta
global bibb_99 BIBB_1999.dta
global bibb_06 BIBB_2006.dta
global bibb_12 BIBB_2012.dta

global bibb_06_clean BIBB_2006_clean.dta
global bibb_06_tasks BIBB_2006_TASKS.dta
global bibb_06_career BIBB_2006_CAREER.dta

global key8892 key_kldb_88_92_3st.dta

global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\bibb_06_rename_log", replace


**************************************************************************************
**************************************************************************************

**Import 1979
clear
use "$datenpfad\$bibb_06", clear

*******************************************
*******************************************
**I. Data cleaning
*******************************************
*******************************************

*******************************************
**a: Keeping relevant variables and renaming them
*******************************************
rename idnum id
*--------------------------------------------
gen year = 2006
order year, b(inttag)
label variable year "Jahr"
*--------------------------------------------
/*

*/


  
 /*
local school_career stib f103 f200 f203 f400 f510 f511j f1101 f1102 f1104 f1105 f1106 f1107 f1109 f1110 f1200 f1201 f1202 g1202 f512 f512_neu f513nace f515 f100stba f100_ba f1401stb bildungr maxbild5 max1202 berufsfeld f1202_korr g1202_korr h1202_korr i1202_korr j1202_korr 

local tasks  f303 f304 f305 f306 f307 f308 f309 f310 f311 f312 f313 f314 f315 f316 f317 f318 f319a f314b_01 f314b_02 f314b_07 f320 f321 f322_01 f322_02 f322_03 f322_04 f322_05 f322_06 f323_01 f323_02 f323_03 f324 f325_01 f325_02 f325_03 f325_04 f325_05 f325_06 f325_07 f325_08 f325_09

local besonders_skills f403_01 f403_02 f403_03 f403_04 f403_05 f403_06 f403_07 f403_08 f403_09 f403_10 f403_11 f404a f403_12 f403_13

local jobanforderungen  f411_01 f411_02 f411_03 f411_04 f411_05 f411_06 f411_07 f411_08 f411_09 f411_11 f411_12 f411_13

*local tools 


local socioecon gkpolf s1 s2j bula ost f518 f1607_01 

local weights gew_d_ew gew3_05 gew3_05_hr

local misc  exp_wage_imp_miss wage_imp_gruppe exp_wage_imp_extr

keep `school_career' `besonders_skills' `jobanforderungen' `comp_specifics' `tools' `tasks' `socioecon' `weights' `misc' idnum year
*/

local socioecon gkpolf s1 s2j bula ost f518 f1607_01 f1607_02 f1607_03 f1607_04 f1607_05 f1607_06 f1607_07 f1607_08 f1607_09 f1607_10 f1607_11 f1607_12 f1607_13 f1607_14 f1607_15

local weights gew_d_ew gew3_05 gew3_05_hr

local tasks  f411_03 f301 f303 f304 f305 f306 f307 f308 f309 f310 f311 f312 f313 f314 f315 f316 f317 f319a f314b_02 f314b_07 f321 f322_01 f322_03 f325_06 f403_04 f405_03 f403_04 f403_07 f325_03 f403_09 f403_10 f405_02 f405_06 f411_02 f408_09 f408_10

local school_career maxbild5 bildungr max1202 m1202 f500 f501 f502 f503 f504 f505 f510 f515 stib f200 f203 f100stba f100_ba f513nace f512_neu f1104 f1216ej f1400 f510 f1203stb g1203stb h1203stb i1203stb j1203stb f1103 f1102 f1204 g1204 h1204 i1204 j1204 f1401stb f1409

local lang  f1606_02 f1606_03 f1606_04 f1606_05 f1606_06 f1606_07 f1606_08 f1606_09 f1606_10 f1606_11 f1606_12 f1606_13 f1606_17
*--------------------------------------------

keep `tasks' `school_career' `socioecon' `weights' stib id year `lang'


**language 
rename f1606_02 lang_eng
rename f1606_03 lang_fre
rename f1606_04 lang_rus
rename f1606_05 lang_esp
rename f1606_06 lang_tur
rename f1606_07 lang_it
rename f1606_08 lang_gre
rename f1606_09 lang_port
rename f1606_10 lang_pol
rename f1606_11 lang_arab
rename f1606_12 lang_jap
rename f1606_13 lang_chi
rename f1606_17 lang_other

gen for_lang_ex = (lang_it ==1 | lang_esp ==1 | lang_rus ==1 | lang_other ==1 | lang_gre ==1 | lang_port ==1 | lang_tur ==1 | lang_other ==1 | lang_pol ==1  | lang_arab ==1  | lang_jap ==1  | lang_chi ==1 | lang_other ==1)
gen for_lang = (lang_it ==1 | lang_esp ==1 | lang_rus ==1 | lang_other ==1 | lang_gre ==1 | lang_port ==1 | lang_tur ==1 | lang_other ==1 | lang_pol ==1  | lang_arab ==1  | lang_jap ==1  | lang_chi ==1 | lang_other ==1| lang_eng ==1 | lang_fre ==1)


**socioecon & weights
rename gkpolf population
rename s1 sex
rename s2j birthyear
rename bula state 
rename ost east_west_dummy
rename f518 income

**nationality
*---
rename f1607_01 nat_german
rename f1607_02 nat_it
rename f1607_03 nat_turk
rename f1607_04 nat_aus
rename f1607_05 nat_benelux
rename f1607_06 nat_scan
rename f1607_07 nat_fr
rename f1607_08 nat_uk
rename f1607_09 nat_gree
rename f1607_10 nat_iberia
rename f1607_11 nat_pl
rename f1607_12 nat_east
rename f1607_13 nat_rus
rename f1607_14 nat_other
rename f1607_15 nat_none
*---

**citzen dummy: Germans=0 / Foreigners=1
gen citizen_dummy=1
replace citizen_dummy=0 if nat_german==1

rename gew_d_ew weight_desing
rename gew3_05  weight_mz05
rename gew3_05_hr hochm_z05

**generate age variable
gen age = year - birthyear
keep if age > 17 & age < 66
*--------------------------------------------

**school/career

rename maxbild5 degree
rename bildungr degree_narrow
rename max1202 degree_voca
rename m1202 degree_voca_raw
rename f515 occup_firmsize
rename stib occup_pos
rename f200 occup_hours_w
rename f203 occup_hours_m_extra
rename f100stba occup_92_4st
rename f100_ba occup_88_4st

rename f500 worker
rename f501 employee
rename f502 master_employee
rename f503 employee_tasks
rename f504 civil
rename f505 instructions

*---
rename f1203stb voca1

rename g1203stb voca2
rename h1203stb voca3
rename i1203stb voca4
rename j1203stb voca5
*---

*---
rename f1103 educ_where
rename f1102 educ_foreign

rename f1204 voca1_where
rename g1204 voca2_where
rename h1204 voca3_where
rename i1204 voca4_where
rename j1204 voca5_where

gen voca_foreign = (voca1_where==20 | voca2_where==20 | voca3_where==20 | voca4_where==20 | voca5_where==20)

drop voca1_where voca2_where voca3_where voca4_where voca5_where 

*---

*---
rename f1401stb app_occup_kldb92_4st

gen app_occup_kldb92_3st = int(app_occup_kldb92_4st/10)
drop app_occup_kldb92_4st

**merge with key to get kldb88

rename app_occup_kldb92_3st occup_kldb92

cd "$datenpfad"
merge m:m occup_kldb92 using $key8892
drop if _merge==2
drop _merge
drop if id==.

drop kldb2010
duplicates drop id occup_kldb92 kldb1988, force

rename kldb1988 app_occup_3st
rename occup_kldb92 app_occup_kldb92_3st

*---

*---
*rename v281 voca_foreign
rename f1409 occup_change


gen occ_change = 0 if occup_change==97
replace occ_change = 1 if occup_change < 97

*rename v286 occup_ch_last_yr
*---


rename f513nace industry_narrow
rename f512_neu industry


rename f1104 degree_year
*drop if degree_year==9999

rename f1216ej degree_voca_year
rename f1400 occup_tenure
drop if occup_tenure==9997 | occup_tenure==9999

rename f510 firm_tenure
drop if firm_tenure==9997 | firm_tenure==9999
*--------------------------------------------

**tasks 


rename f301 manage_pers 
 
rename f303 process_multi
rename f304 measure_evaluate_multi
rename f305 machines_operate_multi
rename f306 repair_general_multi
rename f307 buy_sell_multi
rename f308 pack_ship_multi
rename f309 ad_pr_multi
rename f310 organize_multi
rename f311 construct_rd_multi
rename f312 teaching_multi
rename f313 research_multi
rename f314 consult_inform_multi
rename f315 host_multi
rename f316 caretake_doctor_multi
rename f317 guard_multi
*rename f318 
rename f319a clean_multi
*rename f314b_01 
rename f314b_02 consult_inform_multi2
rename f314b_07 consult_inform_multi3
*rename f320 
rename f321 comp_macro
rename f322_01 comp_program
*rename f322_02 
rename f322_03 software_database
*rename f322_04 
*rename f322_05 
*rename f322_06 
*rename f323_01 
*rename f323_02 
*rename f323_03 
*rename f324 
*rename f325_01 
*rename f325_02 
rename f325_03 negotiate
*rename f325_04 
*rename f325_05 
rename f325_06 present
*rename f325_07 
*rename f325_08 
*rename f325_09

rename f403_04 law_skills
rename f405_03 tax_skills

rename f403_07 shape_design
rename f403_09 german_multi
gen german = (german_multi==3)
rename f403_10 pc_app

rename f405_02 accounting
replace accounting = 0 if accounting==.
rename f405_06 controlling
replace controlling = 0 if controlling==.

rename f411_03 routine_tasks_multi
gen routine_tasks = (routine_tasks_multi==1)
rename f408_09 grammar_qual_multi
gen grammar_qual = (grammar_qual_multi==1)
rename f408_10 pc_app_qual_multi
gen pc_app_qual = (pc_app_qual_multi==1)

gen process = (process_multi==1)
gen measure_evaluate = (measure_evaluate_multi==1)
gen machines_operate = (machines_operate_multi==1)
gen repair_general = (repair_general_multi==1)
gen buy_sell = (buy_sell_multi==1)
gen pack_ship = (pack_ship_multi==1)
gen ad_pr = (ad_pr_multi==1)
gen organize = (organize_multi==1)
gen construct_rd = (construct_rd_multi==1)
gen teaching = (teaching_multi==1)
gen research = (research_multi==1)
gen consult_inform = (consult_inform_multi==1 | consult_inform_multi2==1 | consult_inform_multi3==1)
gen host = (host_multi==1 | host_multi==2)
gen caretake = (caretake_doctor_multi==1)
gen guard = (guard_multi==1)
gen clean = (clean_multi==1)
gen program_it = (comp_program==1 | comp_macro==1)



*******************************************
**c: Task Categories a la Spitz-Oener (2006)
*******************************************

************
**PCA

**cogntive
pca research organize construct_rd program_it teaching consult_inform buy_sell present ad_pr [aw=weight_desing], comp(1)
predict cognitive_pca
**routine
pca machines_operate process pack_ship [aw=weight_desing], comp(1)
predict routine_pca
**manual
pca repair_general host caretake guard clean [aw=weight_desing], comp(1)
predict manual_pca

**non_routine analytic
pca research organize construct_rd program_it [aw=weight_desing], comp(1) 
predict n_rout_anal_pca
**non_routine interactive
pca teaching consult_inform buy_sell present ad_pr [aw=weight_desing], comp(1)
predict n_rout_int_pca
**routine cognitive
egen rout_cog_pca = std(measure_evaluate)
*german
**routine manual
pca machines_operate process pack_ship [aw=weight_desing], comp(1)
predict rout_man_pca
**non_routine manual
pca repair_general host caretake guard clean [aw=weight_desing], comp(1)
predict n_rout_man_pca


**standardize pca scores with mean 0 (already have that mean) and std. dev. = 1
egen cognitive_pca_st = std(cognitive_pca)
egen routine_pca_st = std(routine_pca)
egen manual_pca_st = std(manual_pca)

egen n_rout_anal_pca_st = std(n_rout_anal_pca)
egen n_rout_int_pca_st = std(n_rout_int_pca)
gen rout_cog_pca_st = rout_cog_pca
egen rout_man_pca_st = std(rout_man_pca)
egen n_rout_man_pca_st = std(n_rout_man_pca)

************

*----------------------------------
*----------------------------------
**Task categories (SpitzOener)
*----------------
*Non-routine ANALYTIC
gen investigating = (research==1)
gen organizing = (organize==1)
gen researching = (construct_rd==1)
gen programming = (program_it==1)
**may wanna take comp_software out for robustness


*----------------
*Non-routine INTERACTIVE
rename teaching teach

gen teaching = (teach==1)
gen consulting = (consult_inform==1)
gen buying = (buy_sell==1)
gen promoting = (present==1 | ad_pr==1)

rename present publish_entertain
*----------------
*Routine Cognitive
gen measuring = (measure_evaluate==1)


*----------------
*ROUTINE MANUAL

gen operating = (machines_operate==1)
gen manufacturing = (process==1)
gen storing = (pack_ship==1)

*----------------
*NON-ROUTINE MANUAL
gen repairing = (repair_general==1 )
gen accomodating = (host==1)
gen caring = (caretake==1)
gen cleaning = (clean==1)
gen protecting = (guard==1)

*----------------

/*
1: Betriebliche Berufsausbildung oder Lehre
2: Schulische Berufsausbildung
3: Fachhochschulabschluss (Ingenieurhochschule)
4: Universitätsabschluss (Pädagogische, technische Hochschule, Pädagogisches Institut (DDR))
5: Beamtenausbildung für die Laufbahn des öffentlichen Dienstes
6: Anderer Ausbildungsabschluss
***7:Fortbildungsabschluss zum Meister, Techniker, Betriebs-, Fachwirt, Fachkaufmann
(in der Regel nicht als Erstausbildung möglich)
***8:Referendariat, 2. Staatsexamen, 3. Staatsexamen
***9:K.A..
*.

*/
*******************************************
**categorize career info

*gen educ_high = (degree==4) 3: Fachhochschulabschluss (Ingenieurhochschule)  4: Universitätsabschluss (Pädagogische, technische Hochschule, Pädagogisches Institut (DDR)) 
*gen educ_med = (degree==3)   1: Betriebliche Berufsausbildung oder Lehre  2: Schulische Berufsausbildung  5: Beamtenausbildung für die Laufbahn des öffentlichen Dienstes
*gen educ_low = (degree==1 | degree==2)

gen educ_high = (degree_voca==4 | degree_voca==3)
gen educ_med = (degree_voca==2 | degree_voca==6) 
gen educ_low = (degree_voca==1) & educ_high==0 & educ_med==0

**categorize socioecon info

**Drop East Germany
drop if state > 11
*******************************************



*******************************************
**d: Save data (All & tasks only)
*******************************************

save "$datenpfad\$bibb_06_clean", replace

**Keep subsamples for subsequent analysis
local tasks_final_06 id year research organize construct_rd program_it teaching consult_inform buy_sell publish_entertain ad_pr machines_operate process pack_ship repair_general host caretake guard clean investigating organizing researching programming teaching consulting buying promoting operating manufacturing storing repairing accomodating caring cleaning protecting measuring measure_evaluate

*grow_breed pack_ship repair_renovate mach_equip

keep `tasks_final_06' 

save "$datenpfad\$bibb_06_tasks", replace


*******************************************
**e: Save data on Career/ schooling/ socioecon background/ weights
*******************************************

use "$datenpfad\$bibb_06_clean", clear

**modify occupation
rename occup_88_4st occup
**remove civil servants
drop if civil !=.

rename industry_narrow occup_branch

keep id year voca_foreign occup_branch occ_change app_occup_3st population occup_pos sex birthyear occup_hours_w occup_hours_m_extra for_lang_ex for_lang /// 
occup_tenure firm_tenure degree_year degree_voca_year occup_firmsize income state weight_desing east_west_dummy weight_mz05 hochm_z05 occup occup_92_4st degree ///
degree_voca citizen_dummy age industry educ_high educ_med educ_low worker employee master_employee employee_tasks instructions /// 
cognitive_pca_st routine_pca_st manual_pca_st n_rout_anal_pca_st n_rout_int_pca_st rout_man_pca_st n_rout_man_pca_st rout_cog_pca_st ///
cognitive_pca routine_pca manual_pca n_rout_anal_pca n_rout_int_pca rout_man_pca n_rout_man_pca rout_cog_pca
*rout_cog_pca_st



*school*
save "$datenpfad\$bibb_06_career", replace

/*
*--------------------------------------------
/*
keep `jobanforderungen'

 v266 v267
 
local jobanforderungen_merge

*/
*--------------------------------------------


optical_med bei anderen anpassen


**Computer specifics
keep software_table software_graph software_database software_science software_other software_analysis software_operate_devices

local comp_specifics tabulator software_graph software_database software_science software_other software_analysis software_operate_devices
*/

log close
exit
