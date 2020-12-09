
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

global bibb_92_clean BIBB_1992_clean.dta
global bibb_92_tasks BIBB_1992_TASKS.dta
global bibb_92_career BIBB_1992_CAREER.dta

global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\bibb_92_rename_log", replace


**************************************************************************************
**************************************************************************************

**Import 1979
clear
use "$datenpfad\$bibb_92", clear

*******************************************
*******************************************
**I. Data cleaning
*******************************************
*******************************************

*******************************************
**a: Keeping relevant variables and renaming them
*******************************************
 
*--------------------------------------------
gen year = 1992

order year, b(v2)
label variable year "Jahr"
*--------------------------------------------

local school_career v2 v4 v15 v16 v17 v19 v20 v21 v22 v23 v25 v30 v35 v36 v37 v202 v203 v205 v209 v210 v215 v224 v227 v228 v229 v230 v231 v232 v233 v234 v235 v236 v242 v281 v282 v283 v286

local tasks v38 v39 v40 v41 v42 v43 v44 v45 v46 v46 v47 v48 v49 v50 v51 v52 v53 v54 v55 v56 v57 v58 v59 v60 v61 v62 v63 v64 v65 v66 v67 v185

local tools v123 v124 v125 v126 v127 v128 v128 v129 v130 v131 v132 v133 v134 v135 v136 v137 v138 v139 v140 v141 v142 v142 v143 v144 v145 v146 v147 v148 v149 v150 v151 v152 v153 v154 v155 v156 v157 v158 v158 v159 v160 v161 v162 v162 v163 v164 v165 v166 v167

local socioecon v204 v292 v298 v300 v301 v313 v314 v316

local besonders_skills v77 v79 v80 v81 v82 v83 v84 v85 v86 v87 v88  v89 v90 v91 v92 v93 v94 v95 v96 v97 v98 v99 v171 v172 v190

local weights v318 v319

local misc v176 v184 
*skip spezielle Kenntnise fuer Taetigkeit like mathe, edv, accounting, typewriter etc
*skip specific machines way to operate

local lang v274 v275 v276 v277 v278 v279

keep `school_career' `dept_dums' `tools' `tasks' `socioecon' `besonders_skills' `weights' `misc' year `lang'

**lang 

rename v274 lang_eng
rename v275 lang_fre
rename v276 lang_it
rename v277 lang_esp
rename v278 lang_rus 
rename v279 lang_other

gen for_lang_ex = (lang_it ==1 | lang_esp ==1 | lang_rus ==1 | lang_other ==1)
gen for_lang = (lang_it ==1 | lang_esp ==1 | lang_rus ==1 | lang_other ==1 | lang_eng ==1 | lang_fre ==1)

**socioecon
rename v292 sex
rename v298 birthyear
*---
rename v300 birthcountry
**dummy if birthcountry german (=0) or not (=1)
gen birthcountry_d = (birthcountry==4 | birthcountry==5 | birthcountry==6)
*---
rename v301 citizen
rename v313 state
rename v314 population
rename v316 east_west_dummy

rename v318 weighting_factor
rename v319 projecting_factor

replace birthyear = 1900+birthyear
gen age = year-birthyear

keep if age > 17 & age < 66

*Drop foreigners and people from East Germany
*drop if citizen_dummy==2
*drop if east_west_dummy==2

**Recode citizenship dummy
gen citizen_dummy = 0 if citizen==1
replace citizen_dummy = 1 if citizen==2

**Drop East Germany
drop if state > 11

**school/ career
rename v2 id
rename v4 lf
rename v15 occup_hours_w
**Konvertier Arbeitsstunden in Stunden pro Woche
replace occup_hours_w = occup_hours_w/10
rename v16 occup
rename v17 occup_3st
rename v19 industry
rename v20 occup_branch
rename v21 occup_firmsize
rename v22 self_employed
rename v23 self_employed_year
rename v25 occup_pos
rename v30 firm_tenure
rename v35 income
rename v36 income_east
rename v37 income_west
rename v202 degree
rename v203 degree_year
replace degree_year = degree_year + 1900

*---
rename v281 voc_foreign
rename v282 family_foreign

gen voca_foreign = (birthcountry_d==1 & (voc_foreign==1))

rename v283 occup_change
rename v286 occup_ch_last_yr

gen occ_change = 0 if occup_change==3
replace occ_change = 1 if occup_change==2 | occup_change==1
*---

rename v204 degree_age

rename v205 school_appren
rename v209 app_occup
*---
rename v210 app_occup_3st
*---
rename v215 app_occup_age
rename v224 school_master_tech_yr
rename v227 school_voc1yr_yr
rename v228 school_vocfach_yr
rename v229 school_health_yr 
rename v230 school_engineer_yr
rename v231 school_vocac_yr
rename v232 school_coll_only_yr
rename v233 school_uni_yr
rename v234 school_clerk_yr
rename v235 school_civil_yr
rename v236 degree_voca_year

rename v242 occup_tenure
replace occup_tenure=79 if occup_tenure==1979
replace occup_tenure = occup_tenure + 1900


replace degree_voca_year =1 if degree_voca_year > 0 & degree_voca_year !=.

gen school_appren2 = 0 if school_appren==2
replace school_appren2 = 1  if school_appren==1
replace school_appren2 = .  if school_appren==.

drop school_appren
rename school_appren2 school_appren

gen master_tech_dummy = 0
replace master_tech_dummy = 1 if (school_master_tech_yr==1 | school_master_tech_yr==2 | school_master_tech_yr==3 | school_master_tech_yr==4)
replace master_tech_dummy =. if school_master_tech_yr==. 

drop school_master_tech_yr
rename master_tech_dummy school_master_tech_yr

**(Vocational) Schooling aggregates
gen school_spec_prof = (school_health_yr==1 | school_civil_yr==1 | school_clerk_yr==1)
replace school_spec_prof=. if (school_health_yr==. & school_civil_yr==. & school_clerk_yr==.)

gen school_coll_yr = (school_coll_only_yr==1 | school_engineer_yr==1)
replace school_coll_yr=. if school_coll_only_yr==. & school_engineer_yr==. 

drop school_health_yr school_civil_yr school_clerk_yr
drop school_coll_only_yr school_engineer_yr

/*
gen school_voc_yr2 = 0 
replace school_voc_yr2 = 1 if school_voc_yr==1

drop school_voc_yr
rename school_voc_yr2 school_voc_yr
*/




*--------------------------------------
gen educ_high = (school_uni_yr==1 | school_coll_yr==1 | school_vocac_yr==1)

gen educ_med = (school_vocfach_yr==1 | school_appren==1 | school_spec_prof==1 | school_master_tech_yr==1) & educ_high==0
*gen educ_med = (school_appren==1) & educ_high==0

gen educ_low = (school_appren==0) & educ_high==0 & educ_med==0

**high bissl inflated, aber ansonsten ganz gut

**evtl. mit grad_yr ausprobieren (speziell low) oder v207 lehrabbruch furer die die keinen lehrabschluss haben


**Create table with educational shares
reg educ_high
est store ehigh
reg educ_med
est store emed
reg educ_low
est store elow

esttab ehigh emed elow , not nostar title("Educational groups - 1992")
*---------------------


**work tools
rename v123 transport_simple
rename v124 car
rename v125 tractor
rename v126 forklift
rename v127 crane
rename v128 bulldozer_harvester
rename v129 railcar_plane
rename v130 basic_tools
rename v131 instruments_med
rename v132 optical
rename v133 meter
rename v134 others_plow_welder_oven
rename v135 driven_tools
rename v136 machines_manual
rename v137 machines_semiauto
rename v138 winding_eq
rename v139 mach_prog_controlled
rename v140 computer_term
rename v141 machines_medtech
rename v142 energy_gen
rename v143 chemical_plant
rename v144 prod_plant
rename v145 writing
rename v146 phone
rename v147 calculator
rename v148 file
rename v149 EDV_documents
rename v150 teaching_materials
rename v151 copy_machine
rename v152 dictaphone
rename v153 typewriter_standard
rename v154 teletypewriter
rename v155 registry
rename v156 drawing_table
rename v157 tabulator
rename v158 microfilm_reader
rename v159 audio_video_equip
rename v160 pc
rename v161 computer_edv
rename v162 terminal
rename v163 auto_typewriter
rename v164 teletex
rename v165 cash_register_elec
rename v166 graph_system

rename v167 tool_mvp
*--------------------------------------------
**tool categories
gen crane_forklift = (forklift==1 | crane==1)
gen computer = (computer_term==1 | computer_edv==1 | terminal==1 | microfilm_reader==1 | teletex==1 | pc==1)
gen vehicle = (bulldozer_harvester==1 | car==1 | tractor==1)
gen typewriter = (typewriter_standard==1 | teletypewriter==1)
gen documents = (EDV_documents==1 | file==1)


*******************************************
**b: Create task categories
*******************************************

*keep `tasks' `besonders_skills' occup_pos year

*---------------------------------
**tasks NOT (!) categorized below
*---------------------------------
**tasks
rename v185 routine_tasks

rename v41 drive

rename v43 grow_breeding
rename v44 extract_materials

rename v50 pack_shipping
rename v51 sort_archive

rename v65 task_other
rename v66 tasks_total
rename v67 task_mvp1

**besondere skills
rename v80 comp_hardware
rename v93 materials
rename v94 security_measures
rename v98 medicine
rename v99 skills_total


gen pack_ship = (pack_shipping==1 | drive==1)
gen grow_breed = (grow_breeding==1)

drop drive pack_shipping grow_breeding 

local not_categ_92 pack_ship grow_breed comp_hardware materials security_measures medicine skills_total
*---------------------------------
**tasks that are categorized below
*---------------------------------
rename v52 measure_examine
rename v53 plan_construct
rename v92 construction
rename v57 program_it
rename v81 comp_software
rename v59 apply_law_certify
rename v95 law_labor_civil
rename v96 law_other
rename v64 coordinate
rename v86 manage_organize_personnel_plan
rename v190 negotiate_multi
gen negotiate = (negotiate_multi==1 | negotiate_multi==2)
*evtl mal auch mit negotiate_multi==3 probieren
rename v83 finance_taxes
rename v60 teaching
rename v97 nurture
rename v54 buy_sell_ad_negotiate
rename v84 purchasing
rename v85 sales
rename v62 publish_entertain
gen self_empl = (self_employed==3)
rename v63 oversee
rename v56 accounting_booking
rename v77 math
rename v82 bookkeeping
rename v55 write
rename v79 typewrite
rename v45 process
rename v87 chemistry
rename v88 mechanics
rename v89 electrotechnics
*rename v90 measuring
rename v91 physics
rename v39 machines_operate
rename v171 machines_operate2
rename v38 machines_equip
rename v46 build_install
rename v172 machines_equip2
rename v40 repair 
rename v42 maintenance
rename v47 host
rename v48 cleaning
rename v49 disposal
rename v58 safeguard
rename v61 caretake_doctor

gen caretake = (caretake_doctor==1)
gen clean = (cleaning==1 | disposal==1)

drop cleaning disposal caretake_doctor
drop *_multi

*******************************************
**c: Task Categories a la Spitz-Oener (2006)
*******************************************

************
**PCA

**cogntive
pca coordinate measure_examine plan_construct program_it teaching buy_sell_ad_negotiate publish_entertain [aw=weighting_factor], comp(1)
predict cognitive_pca
*comp_software
**routine
pca machines_operate machines_equip build_install extract_materials process pack_ship sort_archive write accounting_booking [aw=weighting_factor], comp(1)
predict routine_pca
**manual
pca repair maintenance host clean caretake safeguard [aw=weighting_factor], comp(1)
predict manual_pca

**non_routine analytic
pca coordinate measure_examine plan_construct program_it [aw=weighting_factor], comp(1) 
predict n_rout_anal_pca
**non_routine interactive
pca teaching buy_sell_ad_negotiate publish_entertain [aw=weighting_factor], comp(1)
predict n_rout_int_pca
**routine cognitive
pca write accounting_booking [aw=weighting_factor], comp(1)
predict rout_cog_pca
**routine manual
pca machines_operate machines_equip build_install extract_materials process pack_ship sort_archive [aw=weighting_factor], comp(1)
predict rout_man_pca
**non_routine manual
pca repair maintenance host clean caretake safeguard [aw=weighting_factor], comp(1)
predict n_rout_man_pca


**standardize pca scores with mean 0 (already have that mean) and std. dev. = 1
egen cognitive_pca_st = std(cognitive_pca)
egen routine_pca_st = std(routine_pca)
egen manual_pca_st = std(manual_pca)

egen n_rout_anal_pca_st = std(n_rout_anal_pca)
egen n_rout_int_pca_st = std(n_rout_int_pca)
egen rout_cog_pca_st = std(rout_cog_pca)
egen rout_man_pca_st = std(rout_man_pca)
egen n_rout_man_pca_st = std(n_rout_man_pca)

************

*----------------------------------
*----------------------------------
**Task categories (SpitzOener)
*----------------
*Non-routine ANALYTIC
gen investigating = .
gen organizing = (coordinate==1)
gen researching = (measure_examine==1 | plan_construct==1)
gen programming = (program_it==1 | comp_software==1)
**may wanna take comp_software out for robustness

rename measure_examine research
rename coordinate organize
rename plan_construct construct_rd
*----------------
*Non-routine INTERACTIVE
rename teaching teach

gen teaching = (teach==1)
gen consulting = (buy_sell_ad_negotiate==1)
gen buying = (buy_sell_ad_negotiate==1)
**kinda doppelt gemobbelt
gen promoting = (publish_entertain==1)
*gen managing = ()
*gen negotiating = ()

gen consult_inform = (consulting ==1)
gen buy_sell = (buy_sell_ad_negotiate==1)
gen ad_pr = (buy_sell_ad_negotiate==1)
*manage_organize_personnel_plan==1
*buy_sell_ad_negotiate==1 |
*oversee==1


*----------------
*Routine Cognitive
gen measuring = (write==1 | accounting_booking==1)
**use writing and calculationg here as there is no indicator for measuring for 92, then use only measuring for subsequent years

*----------------
*ROUTINE MANUAL
rename v176 lift_heavy
rename v184 work_presc

gen operating = (machines_operate==1 | machines_equip==1 | build_install==1)
gen manufacturing = (extract_materials==1 | process==1)
**grow breeding evtl mal reinnehmen
gen storing = (pack_ship==1 | sort_archive==1)
*maybe add "drive" to storing

*----------------
*NON-ROUTINE MANUAL
gen repairing = (repair==1 | maintenance==1)
gen accomodating = (host==1)
gen caring = (caretake==1)
gen cleaning = (clean==1)
gen protecting = (safeguard==1)

rename repair repair_general
rename safeguard guard
*----------------


*******************************************
**d: Save data (All & tasks only)
*******************************************

**Keep only people from Western Germany
drop if (year==1992 & east_west_dummy==2 & state==0) | (year==1992 &  east_west_dummy==2 & state==11)

**drop civil servants
drop if occup_pos==30 | occup_pos==31 | occup_pos==32 | occup_pos==33

save "$datenpfad\$bibb_92_clean", replace


**Keep subsamples for subsequent analysis
local tasks_final_92 id year ///
organize research construct_rd program_it comp_software teaching publish_entertain machines_operate machines_equip build_install consult_inform buy_sell ad_pr /// 
extract_materials process pack_ship sort_archive repair_general maintenance host clean caretake guard measuring write accounting_booking /// 
investigating organizing researching programming teaching consulting  buying promoting operating manufacturing storing repairing accomodating caring cleaning protecting 

keep `tasks_final_92' `not_categ_92' task_mvp1
save "$datenpfad\$bibb_92_tasks", replace

*******************************************
**e: Save data on Career/ schooling/ socioecon background/ weights
*******************************************

use "$datenpfad\$bibb_92_clean", clear

keep year id voca_foreign occ_change app_occup_3st age lf occup_hours_w industry for_lang_ex for_lang occup occup_3st occup_branch occup_firmsize occup_pos /// 
self_employed self_employed_year firm_tenure occup_tenure income income_east income_west degree degree_year degree_voca_year degree_age app_occup app_occup_3st  ///
sex birthyear age birthcountry citizen_dummy state population east_west_dummy weighting_factor projecting_factor educ_* ///
cognitive_pca_st routine_pca_st manual_pca_st n_rout_anal_pca_st n_rout_int_pca_st rout_man_pca_st n_rout_man_pca_st rout_cog_pca_st ///
cognitive_pca routine_pca manual_pca n_rout_anal_pca n_rout_int_pca rout_man_pca n_rout_man_pca rout_cog_pca


*school* school_voc_yr

save "$datenpfad\$bibb_92_career", replace

/*
**Varlist umbenennen

label variable occup_first "Erster Ausbildungsberuf 4ST"
label variable occup "Derzeitiger Ausbildungsberuf 4ST"
label variable job_before "Beruf vor Wechsel 4ST"
*/

log close
exit
