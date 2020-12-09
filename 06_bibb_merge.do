
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
global bibb_92_career BIBB_1992_CAREER.dta
global bibb_99_career BIBB_1999_CAREER.dta
global bibb_06_career BIBB_2006_CAREER.dta
global bibb_12_career BIBB_2012_CAREER.dta
global bibb_18_career BIBB_2018_CAREER.dta

global bibb_92_tasks BIBB_1992_TASKS.dta
global bibb_99_tasks BIBB_1999_TASKS.dta
global bibb_06_tasks BIBB_2006_TASKS.dta
global bibb_12_tasks BIBB_2012_TASKS.dta
global bibb_18_tasks BIBB_2018_TASKS.dta

global bibb_all_career BIBB_ALL_CAREER.dta
global bibb_all_ BIBB_ALL.dta

global TASKS_ALL TASKS_ALL.dta

global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\bibb_merge_all", replace


**************************************************************************************
**************************************************************************************

*******************************************
*******************************************
**II. Data merge of BIBB 92-18
*******************************************
*******************************************


*******************************************
**a: Import and append all data relating socioecon / school / career / weights
*******************************************

**Import 1992
clear

append using "$datenpfad\$bibb_92_career"
append using "$datenpfad\$bibb_99_career"
append using "$datenpfad\$bibb_06_career"
append using "$datenpfad\$bibb_12_career"
append using "$datenpfad\$bibb_18_career"

**Delete variables that do not appear consistently across surveys
drop  app_occup       lf    projecting_factor   occup_3st income_east income_west degree_age birthcountry population_alt 

duplicates drop id year, force

save "$datenpfad\$bibb_all_career", replace 


*******************************************
**task data


**Import 1992
clear
use "$datenpfad\$bibb_92_tasks", clear
append using "$datenpfad\$bibb_99_tasks"
append using "$datenpfad\$bibb_06_tasks"
append using "$datenpfad\$bibb_12_tasks"
append using "$datenpfad\$bibb_18_tasks"




**Overview of frequency of task categories per year

duplicates drop
*unab task_categories: _all  

*drop investigating organizing researching programming consulting buying teaching promoting measuring operating manufacturing storing repairing accomodating caring cleaning protecting

*drop tasks that appear only once
drop extract_materials comp_hardware comp_software materials security_measures medicine occup_safety foreign_lang  

*drop tasks that appear only twice 
drop sort_archive machines_equip
	
**bundle tasks		
local task_cats research program_it guard consult_inform machines_operate grow_breed pack_ship construct_rd organize buy_sell ad_pr publish_entertain accounting_booking /// 
	write process measure_evaluate build_install host clean repair_general maintenance caretake /// 
investigating organizing researching programming teaching consulting buying promoting measuring operating manufacturing storing repairing accomodating caring cleaning protecting

sort year 

collapse (sum) `task_cats', by(year id)
summarize

	
*mark tasks that appear  five times
gen task_incomp_five = ( guard==1 | pack_ship==1 | publish_entertain==1 |  /// 
	host==1 | clean==1 | caretake==1 | repair_general==1)
	
*mark tasks that appear at least thrice but less than five times
gen task_incomp = (grow_breed==1 | accounting_booking==1 | write==1 | maintenance==1 | build_install==1 | guard==1 | pack_ship==1 | publish_entertain==1 | measure_evaluate==1 | /// 
	host==1 | clean==1 | caretake==1 | repair_general==1)

	
*******************************************
**Merge with socioecon / career / school / weights
*******************************************

cd "$datenpfad"
merge 1:1 id year using $bibb_all_career

tab _merge
keep if _merge==3
drop _merge


*******************************************
**Merge with Number of Tasks performed
*******************************************

cd "$datenpfad"
merge 1:1 id year using $TASKS_ALL

/*
tab _merge
keep if _merge==3
*/
drop _merge

label variable tasks_total "Tasks (Number)"

**Modify ID
sort year id 

**create counting number and replace old ID
gen id_num = 1
order id_num, a(id)
*sort jahr kreis

replace id_num = sum(id_num)

rename id id_old
rename id_num id

unique id_old
unique id

drop id_old

**adjust weight variables

replace weighting_factor = weight_desing if year == 2006 | year == 2012 | year == 2018

**drop other weighting vars
drop  weight_desing weight_mz05 weight_12 weight_12_hr weight_18 weight_18_hr

rename weighting_factor weight

*drop if year==1979 | year==1986

drop if investigating > 1
drop if organizing  > 1
drop if researching  > 1
drop if programming  > 1
drop if teaching  > 1
drop if consulting  > 1
drop if buying  > 1
drop if promoting  > 1
drop if operating  > 1
drop if manufacturing  > 1
drop if storing  > 1
drop if repairing  > 1
drop if accomodating  > 1
drop if caring  > 1
drop if cleaning  > 1
drop if protecting  > 1
drop if measuring  > 1



save "$datenpfad\$bibb_all", replace
	

	
log close
exit
