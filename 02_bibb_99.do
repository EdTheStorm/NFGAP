
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

global bibb_99_clean BIBB_1999_clean.dta
global bibb_99_tasks BIBB_1999_TASKS.dta
global bibb_99_career BIBB_1999_CAREER.dta

global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\bibb_99_rename_log", replace


**************************************************************************************
**************************************************************************************

**Import 1979
clear
use "$datenpfad\$bibb_99", clear

*******************************************
*******************************************
**I. Data cleaning
*******************************************
*******************************************

*******************************************
**a: Keeping relevant variables and renaming them
*******************************************

*--------------------------------------------
gen year = 1999
order year, b(v2)
label variable year "Jahr"
*--------------------------------------------
/*

1990 task data not that straightforward, here's how to deal with that:

- synchronize 79-92 data so they're the same
- add (manually) tasks or related info to the basic framework or, if I have to, adjust the 79-92 in Einem

-fuer fehlende task infos: check Berufsgruppen (zB Gaertner, Zuechter) und schau welche Informationen zu ihnen gesammelt werden kann. 


*/

local school_career v2 v8 v9 v10 v12 v13 v29 v30 v117 v118 v131 v133 v134 v140 v154 v171 v211 v212 v342 v343 v344 v346 v347 v348 v349 v385 v405 v406 v409 v410 v412 v413 v433 v477 v478 v480 v481 v545 v546 v548 v549 v611 v612 v614 v615 v672 v673 v675 v676 v739 v744 v762 v788 v781 v737 v744 v747 v410 v434 v502 v570 v633 v687
*762 ist lf (labor force)
*occup_app 409
*406 unterteil in meisterschule, ingenieru, etc
*skip nebentaetigkeiten

local tasks v112 v113 v114 v115 v116 v189 v190 v191 v192 v193 v194 v195 v196 v197 v198 v199 v200 v201 v202

local besonders_skills v213 v214 v215 v216 v217 v218 v219 v220 v221 v223 v224 v225 v226 v227 v228 v229
*v222
local jobanforderungen v266 v264 v265 v267 v268 v269 v270 v271 v272 v273 v274 v275 v785 v786 v787

local tools v31 v32 v33 v34 v35 v36 v37 v38 v39 v40 v41 v42 v43 v44 v45 v46 v47 v48 v49 v50 v51 v52 v53 v54 v55 v56 v57 v58 v59 v60 v61 v62 v63 v64 v65 v66 v67 v68 v69 v70 v71 v72 v73 v74 v75 v76 v77 v78 v79 v80 v81 v82 v83 v84 v85 v86 v87 v88 v89 v90 v91 v92 v93 v94 v95 v96 v97 v98 v99 v100 v101 v102 v103 v104 v105 v106 v107 v108 v109
**gibt noch paar tools von aeltern samples, die nicht zugeordnet werden konnten (z.B. meter, siehe sort tools file)


local socioecon v3 v5 v6 v7 v8 v147 v777 v779 v780 v781 v782 v783 v784

local weights v789

local misc v252 v265

local lang v726 v727 v728 v729 v730 v731 v732 v733 v734

keep `school_career' `besonders_skills' `jobanforderungen' `comp_specifics' `tools' `tasks' `socioecon' `weights' `misc' year `lang'

*keep `socioecon'  year


**language
rename v726 lang_eng
rename v727 lang_fre
rename v728 lang_gre
rename v729 lang_it
rename v730 lang_port 
rename v731 lang_rus
rename v732 lang_esp
rename v733 lang_tur
rename v734 lang_other

gen for_lang_ex = (lang_it ==1 | lang_esp ==1 | lang_rus ==1 | lang_other ==1 | lang_gre ==1 | lang_port ==1 | lang_tur ==1 | lang_other ==1)
gen for_lang = (lang_it ==1 | lang_esp ==1 | lang_rus ==1 | lang_other ==1 | lang_gre ==1 | lang_port ==1 | lang_tur ==1 | lang_other ==1 | lang_eng ==1 | lang_fre ==1)


local socioecon_merge year v5 v7 v147 v782 v783 

rename v5 sex
rename v7 birthyear
rename v8 age
rename v147 income
rename v779 immiyear
rename v780 citizen
rename v782 state
rename v783 population
rename v784 population_alt
rename v789 weighting_factor
*---
rename v777 birthcountry
rename v781 citizen_for
*---

keep if age > 17 & age < 66

*Drop foreigners and people from East Germany
**drop if immiyear > 1949 & citizen_dummy==2
**drop if citizen_dummy==2 

**Recode citizenship dummy
gen citizen_dummy = 0 if citizen==1
replace citizen_dummy = 1 if citizen==2


drop if state > 10
*says "Berlin,Ost" but actually it's West
replace state=11 if state==0


*skip spezielle Kenntnise fuer Taetigkeit like mathe, edv, accounting, typewriter etc
*skip specific machines way to operate

*------------------------------------------------------------------------
**Harmonize school & career info


local school_career_merge year v2 v9 v29 v117 v134 v140 v343 v405 v406 

rename v2 id
rename v9 occup
rename v29 occup_hours_w
replace occup_hours_w = . if occup_hours_w == 9999
rename v117 occup_pos
rename v133 industry
rename v134 occup_branch
rename v140 occup_firmsize
rename v343 degree
rename v405 school_type
rename v406 school_insti

rename v346 degree_year_unemp
rename v348 degree_year
rename v131 firm_tenure
rename v171 self_employed_year
rename v433 occup_tenure
*---
rename v737 voca_foreign
rename v744 occup_change
rename v747 occup_ch_last_yr

gen occ_change = 0 if occup_change==3
replace occ_change = 1 if occup_change==2 | occup_change==1
*---

*---
rename v410 app_occup_3st
*---
*---
rename v434 voca1_where
rename v502 voca2_where
rename v570 voca3_where
rename v633 voca4_where
rename v687 voca5_where
*---

drop voca_foreign

gen voca_foreign = (voca1_where==3 | voca2_where==3 | voca3_where==3 | voca4_where==3 | voca5_where==3)

drop voca1_where voca2_where voca3_where voca4_where voca5_where 

/*
gen school_voc_yr = 0
replace school_voc_yr = 1 if school_type==1
replace school_voc_yr = . if school_type==.

gen school_vocfach_yr = 0
replace school_vocfach_yr = 1 if school_type==2 | school_insti == 4 
replace school_vocfach_yr = . if school_type==. & school_insti == . 

gen school_uni_yr = 0
replace school_uni_yr = 1 if school_type==3 | school_insti == 10 
replace school_uni_yr = . if school_type==. & school_insti == . 

gen school_civil_yr = 0
replace school_civil_yr = 1 if school_type==4 | school_type ==5
replace school_civil_yr = . if school_type==. & school_type ==.

gen school_master_tech_yr = 0
replace school_master_tech_yr = 1 if school_type==6
replace school_master_tech_yr = . if school_type==.

gen school_health_yr = 0
replace school_health_yr = 1 if school_insti == 1
replace school_health_yr = 1 if school_insti == .

gen school_other_yr = 0
replace school_other_yr = 1 if school_type==9 | school_insti == 11 | school_insti == 9 | school_insti == 2 | school_type == 7 | school_type == 8
replace school_other_yr = 1 if school_type==. & school_insti == . & school_insti == . & school_insti == . & school_type == . & school_type == .

gen school_coll_yr = 0 
replace school_coll_yr = 1 if school_insti == 3 | school_insti == 3 | school_insti == 6 | school_insti == 7 | school_insti == 8
replace school_coll_yr = . if school_insti == . & school_insti == . & school_insti == . & school_insti == . & school_insti == .

gen school_vocac_yr = 0
replace school_vocac_yr = 1 if school_insti == 5
replace school_vocac_yr = . if school_insti == .

gen school_spec_prof = 0
replace school_spec_prof = 1 if school_civil_yr==1 | school_health_yr==1 
replace school_spec_prof = . if school_civil_yr==. & school_health_yr==. 

drop school_type school_insti
drop school_civil_yr school_health_yr
*------------------------------------------------------------------------
*/

**zu viele med, zu wenig high, koennte sich korrigieren lassen mit school_type==2 zu high, aber naja...
**school type==2 ist berufsfachschule or fachschule

**streng genommen ist fachschule technical college was bei spitzoener aber halt nicht consistent mit vorigen samples... nachdenken...

gen educ_high = (school_type==3 | school_type==2)
*| school_insti==3 | school_insti==7 | school_insti==8 | school_insti==10
gen educ_med = (school_type==1 | school_type==4 | school_type==5 | school_type==6 | school_type==7 | school_type==8 | school_type==9) & educ_high==0

gen educ_low = (school_type==10) & educ_high==0 & educ_med==0


**Create table with educational shares
reg educ_high
est store ehigh
reg educ_med
est store emed
reg educ_low
est store elow

esttab ehigh emed elow , not nostar title("Educational groups - 1999")
*---------------------




*------------------------------------------------------------------------

*------------------------------------------------------------------------
**Harmonize socioecon info

*keep `tools'

local tools_merge year v31 v32 v33 v34 v35 v36 v39 v40 v41 v42 v43 v44 v45 v46 v51 v54 v55 v56 v57 v58 v59 v60 v61 v62 v64 v65 v66 v67 v68 v69 v70 v71 v72 v73 v74 v75 v76 v77 v78 v79 v80 v81 v82 v83 v84 v85 v87 v88 v89 v90 v92 v96 v98 v99 v101 v102 v103 v104 v105 v106 v107 v108 v109

rename v31 basic_tools
rename v32 optical_med
*optical_med bei anderen anpassen
rename v33 driven_tools
rename v34 other_tools
rename v35 loet_tools
rename v36 oven
rename v39 machines_manual
rename v40 machines_semiauto
rename v41 mach_prog_ctr_std
rename v42 chemical_plant
rename v43 mach_fill
rename v44 prod_plant
rename v45 energy_gen
rename v46 mach_store
rename v51 mach_diag
rename v54 pc
rename v55 network_int
rename v56 inet
rename v57 laptop
rename v58 scanner
rename v59 comp_steer
rename v60 comp_other
rename v61 writing
rename v62 typewriter
*rename v63 calculator
rename v64 phone_stat
rename v65 phone_isdn
rename v66 voicemail
rename v67 handy
rename v68 fax
rename v69 dictaphone
rename v70 overhead
rename v71 camera
rename v73 bike
rename v74 car_taxi
rename v75 bus
rename v76 truck
rename v77 truck_danger
rename v78 train
rename v79 ship
rename v80 plane
rename v81 transport_simple 
rename v82 tractor
rename v83 streetbuildcar
rename v84 vehicle_lift
rename v85 lift_standard
rename v86 cargo_lift
rename v87 digger
rename v88 crane_hall
rename v89 crane_build
rename v90 crane_standard
rename v91 crane_handling
rename v92 vehicle_other
rename v96 security_camera
rename v98 registry
rename v99 cash_register_elec
rename v101 tool_mvp
rename v102 text_processing
rename v103 software_table
rename v104 software_graph
rename v105 software_database
rename v106 software_science
rename v107 software_other
rename v108 software_analysis
rename v109 software_operate_devices


*--------------------------------------------
**tool categories

gen others_plow_welder_oven = (loet_tools==1 | oven==1)
gen mach_prog_controlled = (mach_prog_ctr_std==1 | mach_store==1 | mach_fill==1 | mach_diag==1)

gen comp = (pc==1 | network_int==1 | inet==1 | laptop==1 | scanner==1 | comp_steer==1 | comp_other==1 | text_processing==1 | software_graph==1 | software_database==1 | software_science==1 | software_other==1 | software_analysis==1 | software_operate_devices==1)
gen phone = (phone_stat==1 | phone_isdn==1 | inet==1 | voicemail==1 | handy==1 | fax==1)

gen audio_video_equip = (overhead==1 | camera==1 | security_camera==1)
gen vehicle = (bike==1 | car_taxi==1 | bus==1 | truck==1 | truck_danger==1 | tractor==1 | streetbuildcar==1 | vehicle_lift==1 | digger==1 | vehicle_other==1)

gen railcar_place = (train==1 | ship==1 | plane==1)
gen crane_forklift = (lift_standard==1 | cargo_lift==1 | crane_hall==1 | crane_build==1 | crane_standard==1 | crane_handling==1)


*******************************************
**b: Create task categories
*******************************************


*keep `tasks' `besonders_skills' occup_pos year 

**Tasks

*local tasks_merge year v112 v113 v114 v115 v116 v189 v190 v191 v192 v193 v194 v195 v196 v197 v198 v199 v200 v201 v202


*---------------------------------
**tasks NOT (!) categorized below
*---------------------------------
**besonders_skills
rename v216 foreign_lang
rename v219 comp_software
rename v221 comp_hardware
rename v228 occup_safety
rename v229 medicine

local not_categ_99 foreign_lang comp_hardware occup_safety medicine

*---------------------------------
**tasks that are categorized below
*---------------------------------
rename v191 measure_evaluate_multi
rename v197 research_multi
rename v199 construct_rd_multi
*gen measure_examine = (measure_evaluate==1 | research==1)
rename v218 shape_design
rename v220 comp_program
rename v223 law_labor_civil
rename v224 law_other
rename v226 finance_taxes
rename v198 negotiate_multi
rename v195 organize_multi
rename v225 manage_organize_personnel_plan
rename v189 teaching_multi
rename v202 teaching_voc
rename v190 consult_inform_multi
rename v194 buy_sell_multi
rename v196 ad_pr_multi
rename v217 sales_pr
rename v215 present
gen self_empl = (occup_pos==4)
rename v213 math
rename v227 controlling
rename v214 german
rename v200 process_multi
rename v112 machines_operate1
rename v192 machines_operate2_multi
rename v115 machines_steer
rename v113 machines_install1
rename v114 machines_install2
rename v116 repair_machines
rename v193 repair_general_multi
rename v201 caretake_multi

rename v266 routine_tasks

gen teaching = (teaching_multi==1)
gen consult_inform = (consult_inform_multi==1)
gen measure_evaluate = (measure_evaluate_multi==1)
gen machines_operate2 = (machines_operate2_multi==1)
gen repair_general = (repair_general_multi==1)
gen buy_sell = (buy_sell_multi==1)
gen organize = (organize_multi==1)
gen ad_pr = (ad_pr_multi==1)
gen research = (research_multi==1)
gen negotiate = (negotiate_multi==1)
gen construct_rd = (construct_rd_multi==1)
gen process = (process_multi==1)
gen caretake = (caretake_multi==1)
gen machines_operate = (machines_operate1==1 | machines_operate2==1 | machines_steer==1)
gen machines_install = (machines_install1==1 | machines_install2==1)

drop machines_operate1 machines_operate2 machines_steer machines_install1 machines_install2
drop *_multi


*******************************************
**c: Task Categories a la Spitz-Oener (2006)
*******************************************

************
**PCA

**cognitive
pca research organize construct_rd teaching consult_inform buy_sell ad_pr [aw=weighting_factor], comp(1)
predict cognitive_pca 
*present comp_program comp_software
**routine
pca machines_operate machines_install process [aw=weighting_factor], comp(1)
predict routine_pca
**manual
pca repair_general caretake [aw=weighting_factor], comp(1)
predict manual_pca

**non_routine analytic
pca research organize construct_rd [aw=weighting_factor], comp(1) 
predict n_rout_anal_pca
**non_routine interactive
pca teaching consult_inform buy_sell present ad_pr [aw=weighting_factor], comp(1)
predict n_rout_int_pca
**routine cognitive
egen rout_cog_pca = std(measure_evaluate)
**routine manual
pca machines_operate machines_install process [aw=weighting_factor], comp(1)
predict rout_man_pca
**non_routine manual
pca repair_general caretake [aw=weighting_factor], comp(1)
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
gen programming = (comp_program==1 | comp_software==1)
**may wanna take comp_software out for robustness

rename comp_program program_it
*----------------
*Non-routine INTERACTIVE
rename teaching teach

gen teaching = (teach==1)
gen consulting = (consult_inform==1)
gen buying = (buy_sell==1)
gen promoting = (present==1 | ad_pr==1)
*gen managing = ()
*gen negotiating = (negotiate==1)

*manage_organize_personnel_plan==1
rename present publish_entertain
*----------------
*Routine Cognitive
gen measuring = (measure_evaluate==1)

*----------------
*ROUTINE MANUAL
rename v252 lift_heavy
rename v265 work_presc

gen operating = (machines_operate==1 | machines_install==1)
gen manufacturing = (process==1)
gen storing = .

*----------------
*NON-ROUTINE MANUAL
gen repairing = (repair_general==1 | repair_machines==1)
gen accomodating = .
gen caring = (caretake==1)
gen cleaning = .
gen protecting = .

*----------------

rename machines_install build_install
rename repair_machines maintenance
*******************************************
**d: Save data (All & tasks only)
*******************************************

**drop civil servants
drop if occup_pos==3

save "$datenpfad\$bibb_99_clean", replace


**Keep subsamples for subsequent analysis
local tasks_final_99 id year research organize construct_rd program_it comp_software teaching consult_inform buy_sell publish_entertain ad_pr machines_operate build_install ///
process repair_general maintenance caretake /// 
investigating measuring organizing researching programming teaching consulting buying promoting ///
operating manufacturing storing repairing accomodating caring cleaning protecting /// 
measure_evaluate

*grow_breed 


keep `tasks_final_99' `not_categ_99' 

save "$datenpfad\$bibb_99_tasks", replace


*******************************************
**e: Save data on Career/ schooling/ socioecon background/ weights
*******************************************

use "$datenpfad\$bibb_99_clean", clear

*drop v1* v2* v3* v4* v5* v6* v7* v8* 

keep  year id voca_foreign occ_change app_occup_3st birthcountry citizen_for sex birthyear age degree_year_unemp degree_year firm_tenure industry for_lang_ex for_lang ///
occup_tenure self_employed_year occup occup_hours_w occup_pos occup_branch occup_firmsize income degree state population population_alt weighting_factor citizen_dummy educ_* ///
cognitive_pca_st routine_pca_st manual_pca_st n_rout_anal_pca_st n_rout_int_pca_st rout_man_pca_st n_rout_man_pca_st rout_cog_pca_st /// 
cognitive_pca routine_pca manual_pca n_rout_anal_pca n_rout_int_pca rout_man_pca n_rout_man_pca rout_cog_pca

*rout_cog_pca_st

*school*
save "$datenpfad\$bibb_99_career", replace


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
