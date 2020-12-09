


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
global bibb_18 BIBB_2018.dta

global bibb_18_clean BIBB_2018_clean.dta
global bibb_18_tasks BIBB_2018_TASKS.dta
global bibb_18_career BIBB_2018_CAREER.dta

global key8892 key_kldb_88_92_3st.dta

global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\bibb_18_rename_log", replace


**************************************************************************************
**************************************************************************************

**Import 1979
clear
use "$datenpfad\$bibb_18", clear

*****************
**************************
*******************************************
**I. Data cleaning
*******************************************
*******************************************

*******************************************
**a: Keeping relevant variables and renaming them
*******************************************
rename intnr id
*--------------------------------------------
gen year = 2018
order year, a(id)
label variable year "Jahr"

drop int_jahr int_mon mobil
*--------------------------------------------
/*

*/


local socioecon gkpol zpalter S1 S2_j Bula F233_Bula F518_SUF F1607_01 F1607_02 F1607_03 F1607_04 F1607_05 F1607_06 F1607_07 F1607_08 F1607_09 F1607_10 F1607_11 F1607_12 F1607_13 F1607_14 F1607_99n

local weights des2018 gew2018 gew2018_hr17

local tasks F411_02 F411_03 F411_08 F411_09 F301 F303 F304 F305 F306 F307 F308 F309 F310 F311 F312 F313 F314 F315 F316 F317 F318 F319 F320 F325_01 F325_03 F325_05 F327_05 F403_01 F403_05 F403_06 F411_02 F403_05 F403_06

local school_career max1202 S3 S4 max1202 m1202 F500 F501 F502 F503 F504 F505 F510 F511_j F512 F512_neu F515 Stib F200 F206 F100_kldb92_2d F100_kldb92_3d F1401_kldb92_2d F1401_kldb92_3d F1203_kldb92_2d WZ2003 F512_neu F1104 F1216_ej F1400 F510 S4 F1204 G1204 H1204 I1204 J1204 F1401_kldb92_2d F1401_kldb92_3d F1207 F1208
**S3 Schulabschluss, S4 Schulsabschluss im Ausland

*f1203stb g1203stb h1203stb i1203stb j1203stb omitted for now
*1. ... 5. Ausbildung

*f1103 gibts nicht : bland abschl gemacht ------- auch nicht f1409: wie viele Berufe seit 1. Taetigkeit

local lang F1606_02 F1606_03 F1606_04 F1606_05 F1606_06 F1606_07 F1606_08 F1606_09 F1606_10 F1606_11 F1606_12 F1606_13 F1606_17

*--------------------------------------------

keep `tasks' `school_career' `socioecon' `weights' Stib id year `lang'


**language 
rename F1606_02 lang_eng
rename F1606_03 lang_fre
rename F1606_04 lang_rus
rename F1606_05 lang_esp
rename F1606_06 lang_tur
rename F1606_07 lang_it
rename F1606_08 lang_gre
rename F1606_09 lang_port
rename F1606_10 lang_pol
rename F1606_11 lang_arab
rename F1606_12 lang_jap
rename F1606_13 lang_chi
rename F1606_17 lang_other

gen for_lang_ex = (lang_it ==1 | lang_esp ==1 | lang_rus ==1 | lang_other ==1 | lang_gre ==1 | lang_port ==1 | lang_tur ==1 | lang_other ==1 | lang_pol ==1  | lang_arab ==1  | lang_jap ==1  | lang_chi ==1 | lang_other ==1)
gen for_lang = (lang_it ==1 | lang_esp ==1 | lang_rus ==1 | lang_other ==1 | lang_gre ==1 | lang_port ==1 | lang_tur ==1 | lang_other ==1 | lang_pol ==1  | lang_arab ==1  | lang_jap ==1  | lang_chi ==1 | lang_other ==1| lang_eng ==1 | lang_fre ==1)



**socioecon & weights
rename S1 sex
rename S2_j birthyear
rename zpalter age
rename F233 state_firm 
rename Bula state 
rename F518_SUF income
rename gkpol population

**nationality
*---
rename F1607_01 nat_german
rename F1607_02 nat_it
rename F1607_03 nat_turk
rename F1607_04 nat_aus
rename F1607_05 nat_benelux
rename F1607_06 nat_scan
rename F1607_07 nat_fr
rename F1607_08 nat_uk
rename F1607_09 nat_gree
rename F1607_10 nat_iberia
rename F1607_11 nat_pl
rename F1607_12 nat_east
rename F1607_13 nat_rus
rename F1607_14 nat_other
rename F1607_99n nat_none
*---

**citzen dummy: Germans=0 / Foreigners=1
gen citizen_dummy=1
replace citizen_dummy=0 if nat_german==1


rename des2018 weight_desing
rename gew2018 weight_18
rename gew2018_hr17 weight_18_hr

*--------------------------------------------

rename F301 manage_pers 
**technically is multi as well (k.A.)

rename F303 process_multi
rename F304 measure_evaluate_multi
rename F305 machines_operate_multi
rename F306 repair_general_multi
rename F307 buy_sell_multi
rename F308 pack_ship_multi
rename F309 ad_pr_multi
rename F310 organize_multi
rename F311 construct_rd_multi
rename F312 teaching_multi
rename F313 research_multi
rename F314 consult_inform_multi
rename F315 host_multi
rename F316 caretake_doctor_multi
rename F317 guard_multi
**rename F318 
rename F319 correct_email_multi
rename F320 clean_multi
rename F325_01 comp_program
rename F325_03 software_database
rename F325_05 consult_inform_multi2
rename F327_05 negotiate
**present missing in 2012 apparently or included in another task
*rename f325_06 present


**skipped fields of knowledge for now



rename F403_01 law_skills
*rename f403_07 shape_design
rename F403_05 german_multi
gen german = (german_multi==3)

rename F403_06 pc_app

rename F411_03 routine_tasks
 
**rename f405_02 accounting
**rename f405_06 controlling


 
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
gen consult_inform = (consult_inform_multi==1 | consult_inform_multi2==1)
gen host = (host_multi==1 | host_multi==2)
gen caretake = (caretake_doctor_multi==1)
gen guard = (guard_multi==1)
gen clean = (clean_multi==1)
gen program_it = (comp_program==1)

gen correct_email = (correct_email_multi==3)


**school/career

rename S3 degree
rename max1202 degree_voca
drop if degree_voca > 4

rename F1207 school_type
rename F1208 school_type2

*rename F100_kldb2010_3d occup_10_3st
*rename F100_kldb2010_2d occup_10_2st

rename F100_kldb92_3d occup_92_3st
rename F100_kldb92_2d occup_92_2st
 
rename F200 occup_hours_w
rename F206 occup_hours_w_tats

replace occup_hours_w = occup_hours_w_tats if occup_hours_w==99
replace occup_hours_w = occup_hours_w_tats if occup_hours_w==97
replace occup_hours_w = occup_hours_w_tats if occup_hours_w==.

drop if occup_hours_w > 150


rename F515 occup_firmsize
rename Stib occup_pos

rename F512_neu industry
rename WZ2003 occup_branch




rename F1104 degree_year
*drop if degree_year==9999

rename F1216_ej degree_voca_year
rename F1400 occup_tenure
drop if occup_tenure==9997 | occup_tenure==9999

rename F510 firm_tenure
drop if firm_tenure==9997 | firm_tenure==9999


rename F500 worker
rename F501 employee
rename F502 master_employee
rename F503 employee_tasks
rename F504 civil
rename F505 instructions


*---
*rename AB1_92g voca1
*rename AB2_92g voca2
*rename AB3_92g voca3
*rename AB4_92g voca4
*rename AB5_92g voca5
   
*---

*---
*rename F1103 educ_where
rename S4 educ_foreign

rename F1204 voca1_where
rename G1204 voca2_where
rename H1204 voca3_where
rename I1204 voca4_where
rename J1204 voca5_where

gen voca_foreign = (voca1_where==20 | voca2_where==20 | voca3_where==20 | voca4_where==20 | voca5_where==20)

drop voca1_where voca2_where voca3_where voca4_where voca5_where 
*---

*---

/*
**apprentice specifics:

rename EB1_92o app_occup_kldb92_4st

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
*/

*---
*rename F1403 occup_change

*gen occ_change = 0 if occup_change==1
*replace occ_change = 1 if occup_change < 97 & occup_change > 1 

*rename v286 occup_ch_last_yr
*---

*rename f203 occup_hours_extra_m
*rename f513nace occup_branch


*------------------------------------------------------------------------

*******************************************
**c: Task Categories a la Spitz-Oener (2006)
*******************************************

************
**PCA

**cogntive
pca research organize construct_rd program_it teaching consult_inform buy_sell ad_pr [aw=weight_desing], comp(1)
*present
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
pca teaching consult_inform buy_sell ad_pr [aw=weight_desing], comp(1)
*present
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
gen promoting = (ad_pr==1)
*present==1 |  not included in 2012


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
3: Fachhochschulabschluss (auch Ingenieur-, Verwaltungshochschule)
4: Universitätsabschluss (auch Pädagogische, technische Hochschule, Pädagogisches Institut
(DDR))
5: Beamtenausbildung für die Laufbahn des öffentlichen Dienstes
6: Anderer Ausbildungsabschluss
***7:Fortbildungsabschluss zum Meister, Techniker, Betriebs-, Fachwirt, Fachkaufmann
(in der Regel nicht als Erstausbildung möglich)
***8:Referendariat, 2. Staatsexamen, 3. Staatsexamen, Promotion
(in der Regel nicht als Erstausbildung möglich)
***9: keine Angabe.
*/
*******************************************
**categorize career info

gen educ_high = (degree_voca==4)
gen educ_med = (degree_voca==3 | degree_voca==2) 
gen educ_low = educ_high==0 & educ_med==0

**categorize socioecon info

**Drop East Germany
drop if state > 11

*******************************************

*******************************************
**d: Save data (All & tasks only)
*******************************************

save "$datenpfad\$bibb_18_clean", replace


**Keep subsamples for subsequent analysis
local tasks_final_18 id year research organize construct_rd program_it teaching consult_inform buy_sell ad_pr machines_operate process pack_ship repair_general host caretake guard clean investigating organizing researching programming teaching consulting buying promoting operating manufacturing storing repairing accomodating caring cleaning protecting measuring measure_evaluate
*present

*grow_breed pack_ship repair_renovate entertain_pres calc_bookkeeping mach_equip

keep `tasks_final_18' 
save "$datenpfad\$bibb_18_tasks", replace


*******************************************
**e: Save data on Career/ schooling/ socioecon background/ weights
*******************************************

use "$datenpfad\$bibb_18_clean", clear

**modify occupation (based on 92 classification)
rename occup_92_3st occup_kldb92

cd "$datenpfad"
merge m:m occup_kldb92 using $key8892

duplicates drop id, force
duplicates drop id occup_kldb92 kldb1988, force

tab _merge
drop if _merge==2
drop _merge

rename occup_kldb92 occup_92_3st 
rename kldb1988 occup


**remove civil servants
drop if civil !=.



keep id year voca_foreign occup_pos age state population weight_desing weight_18 weight_18_hr sex birthyear degree /// 
educ_foreign for_lang_ex for_lang occup occup_hours_w state_firm occup_tenure firm_tenure degree_year degree_voca_year occup_firmsize income /// 
degree_voca school_type school_type2 industry occup_branch citizen_dummy educ_high educ_med educ_low worker employee master_employee employee_tasks instructions /// 
cognitive_pca_st routine_pca_st manual_pca_st n_rout_anal_pca_st n_rout_int_pca_st rout_man_pca_st n_rout_man_pca_st rout_cog_pca_st ///
cognitive_pca routine_pca manual_pca n_rout_anal_pca n_rout_int_pca rout_man_pca n_rout_man_pca rout_cog_pca
*rout_cog_pca_st

*school*
save "$datenpfad\$bibb_18_career", replace


*--------------------------------------------
/*
keep `jobanforderungen'

 v266 v267
 
local jobanforderungen_merge

*/
*--------------------------------------------

/*
optical_med bei anderen anpassen


**Computer specifics
keep software_table software_graph software_database software_science software_other software_analysis software_operate_devices

local comp_specifics tabulator software_graph software_database software_science software_other software_analysis software_operate_devices
*/

log close
exit
