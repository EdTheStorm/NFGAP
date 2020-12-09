

clear all
***Version festlegen
version 12
***Bildschirmausgabe steuern
set more off
set logtype text
set linesize 255

/*
***Ado Pfad festlegen
sysdir set PERSONAL "C:\Users\Admin\Documents\PhD\Research\Census\Census data\C_Programm\Master do file stuff\"
mata mata mlib index
*/

** Makros für Pfade
global datenpfad "C:\Users\estorm\Google Drive\BIBB data\BIBB-Erwerbstaetige_1-6\BIBB_ALLE\"
global dopfad "C:\Users\estorm\Google Drive\BIBB data\Stata Code\BIBB\nfgap\"
global outputpfad "C:\Users\estorm\Google Drive\BIBB data\Log Files\BIBB_log\"

*** Makros für Datei- und Outputnamen


global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\bibb_master_decomp", replace

*******************************************************
*******************************************************
*******************************************************

*cd "$dopfad"
*do decomp_rif_ind_fe_robust


cd "$dopfad"
do 01_bibb_92
cd "$dopfad"
do 02_bibb_99
cd "$dopfad"
do 03_bibb_06
cd "$dopfad"
do 04_bibb_12
cd "$dopfad"
do 05_bibb_18
cd "$dopfad"
do 06_bibb_merge
cd "$dopfad"
do 07_bibb_var_create
cd "$dopfad"
do 08_bibb_task_siab
cd "$dopfad"
do 09_bibb_soep_siab_merge
cd "$dopfad"
do 10_occ_restricted_sample
cd "$dopfad"
do 11_decomp_ob
cd "$dopfad"
do 12_decomp_rif_ind_occ_task_immi3
cd "$dopfad"
do 13_decomp_rif_bw
cd "$dopfad"
do 14_decomp_rif_ind_fe
cd "$dopfad"
do 15_decomp_rif_robust_ind_occ_unrestricted
cd "$dopfad"
do 16_decomp_rif_robust_ind_fe_immi3
cd "$dopfad"
do 17_decomp_rif_robust_civil
cd "$dopfad"
do 18a_decomp_rif_robust_male
cd "$dopfad"
do 18b_decomp_rif_robust_female
cd "$dopfad"
do 19_decomp_rif_robust_base_rm


log close
exit
