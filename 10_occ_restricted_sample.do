
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
global BIBB_Decomp_Full_Allocc_lessrest BIBB_Decomp_Full_Allocc_lessrest.dta

global BIBB_Decomp_Full_Allocc_lr_eger BIBB_Decomp_Full_Allocc_lr_eger.dta

global occs_partitioned occs_partitioned.dta

global occ_for5 occ_for5.dta

global outputname <outputname> /*Outputname einfügen*/

****start log
capture log close
log using "$outputpfad\RIF_Decomp_details_narrow", replace

cd "$datenpfad"
set matsize 800

**************************************************************************************
**************************************************************************************

use "$datenpfad\$BIBB_Decomp_Full", clear

**count foreign workers for each occupat
bysort occup_siab time_dummy: egen immi_occ = total(citizen_dummy)
drop if immi_occ < 3

keep occup_siab time_dummy immi_occ
duplicates drop

**create counting number and remove occupations with only sufficient observation in one sub sample
by occup_siab: gen id_num = 1
by occup_siab: replace id_num = sum(id_num)

bysort occup_siab: gen for5= id_num[2] - id_num[1]
drop if for5 == .

keep occup_siab for5
duplicates drop


save "$datenpfad\$occ_for5", replace
