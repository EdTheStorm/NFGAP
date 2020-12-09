
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


global outputname <outputname> /*Outputname einfügen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\bibb_descriptives", replace


**************************************************************************************
**************************************************************************************

use "$datenpfad\$bibb_all_adj", clear


*******************************************
**no. of activities overall
*******************************************

local tasks_incomp grow_breed accounting_booking write maintenance  build_install guard pack_ship publish_entertain measure_evaluate host clean caretake repair_general
	
	
bysort id: egen t_tasks_tot = total(research +  program_it + guard + consult_inform + machines_operate + grow_breed + pack_ship + construct_rd + organize + buy_sell /// 
												+ ad_pr + publish_entertain + accounting_booking + write + process + measure_evaluate + build_install + host + clean /// 
												+ repair_general + maintenance + caretake)
												
bysort id: egen t_tasks_tot_incomp = total(research + program_it + consult_inform + machines_operate + construct_rd + organize + buy_sell + ad_pr + process  /// 
												   + guard + pack_ship + publish_entertain + host + clean + caretake + repair_general ) ///
												   
											
bysort id: egen t_tasks_tot_full = total(research + program_it + consult_inform + machines_operate + construct_rd + organize + buy_sell + ad_pr + process)
												  
*******************************************
**c: Create task categories
*******************************************

gen n_rout_anal = (investigating==1 | organizing==1 | researching==1 | programming==1)
gen n_rout_int = (teaching==1 | consulting==1 | buying==1 | promoting==1)
gen rout_cog = (measuring==1)
gen rout_man = (operating==1 | manufacturing==1 | storing==1)
gen n_rout_man = (repairing==1 | accomodating==1 | caring==1 | cleaning==1 | protecting==1)


** Count number of tasks within each task group for each individual
bysort id: egen t_n_rout_anal = total(investigating +  organizing + researching + programming)
bysort id: egen t_n_rout_int = total(teaching + consulting + buying + promoting)
bysort id: egen t_rout_cog = total(measuring)
bysort id: egen t_rout_man = total(operating + manufacturing + storing)
bysort id: egen t_n_rout_man = total(repairing + accomodating + caring + cleaning + protecting)

**Count how many tasks are included in each task group
describe `n_rout_anal' 
gen tnr_n_rout_anal = 4
describe `n_rout_int' 
gen tnr_n_rout_int = 4
describe `rout_cog' 
gen tnr_rout_cog = 1
describe `rout_man' 
gen tnr_rout_man = 3
describe `n_rout_man' 
gen tnr_n_rout_man = 5

**Create task intensity (Spitz-Oener definition)
gen tint_n_rout_anal_so = (t_n_rout_anal/tnr_n_rout_anal)
gen tint_n_rout_int_so = (t_n_rout_int/tnr_n_rout_int)
gen tint_rout_cog_so = (t_rout_cog/tnr_rout_cog)
gen tint_rout_man_so = (t_rout_man/tnr_rout_man)
gen tint_n_rout_man_so = (t_n_rout_man/tnr_n_rout_man)

**Create task intensity (Antonczyk definition)
gen tint_n_rout_anal_an = (t_n_rout_anal/(t_n_rout_anal+t_n_rout_int+t_rout_cog+t_rout_man+t_n_rout_man))
gen tint_n_rout_int_an = (t_n_rout_int/(t_n_rout_anal+t_n_rout_int+t_rout_cog+t_rout_man+t_n_rout_man))
gen tint_rout_cog_an = (t_rout_cog/(t_n_rout_anal+t_n_rout_int+t_rout_cog+t_rout_man+t_n_rout_man))
gen tint_rout_man_an = (t_rout_man/(t_n_rout_anal+t_n_rout_int+t_rout_cog+t_rout_man+t_n_rout_man))
gen tint_n_rout_man_an = (t_n_rout_man/(t_n_rout_anal+t_n_rout_int+t_rout_cog+t_rout_man+t_n_rout_man))

**Create task intensity (ALM definition)
gen tint_cognitive = ((t_n_rout_anal+t_n_rout_int)/(t_n_rout_anal+t_n_rout_int+t_rout_cog+t_rout_man+t_n_rout_man))
gen tint_routine = ((t_rout_cog+t_rout_man)/(t_n_rout_anal+t_n_rout_int+t_rout_cog+t_rout_man+t_n_rout_man))
gen tint_non_routine = (t_n_rout_man/(t_n_rout_anal+t_n_rout_int+t_rout_cog+t_rout_man+t_n_rout_man))

**could standardize intensities as well (mean zero + std dev)
*su var
*gen stdmi = (BMI - r(mean)) / r(sd)

**Drop amount of tasks within each task group & number of tasks performed by each individual (not needed anymore)
drop t_n_rout_anal t_n_rout_int t_rout_cog t_rout_man t_n_rout_man
drop tnr_n_rout_anal tnr_n_rout_int tnr_rout_cog tnr_rout_man tnr_n_rout_man

**Drop indicators whether individual performs task i
drop n_rout_anal n_rout_int rout_cog rout_man n_rout_man

**Rename task categories
foreach var of varlist tint_n_rout_anal_so tint_n_rout_int_so tint_rout_cog_so tint_rout_man_so tint_n_rout_man_so tint_n_rout_anal_an tint_n_rout_int_an tint_rout_cog_an tint_rout_man_an tint_n_rout_man_an tint_cognitive tint_routine tint_non_routine {
   	local newname = substr("`var'", 6, .)
   	rename `var' `newname'
	
}


local tasks_so n_rout_anal_so n_rout_int_so rout_cog_so rout_man_so n_rout_man_so

local tasks_an n_rout_anal_an n_rout_int_an rout_cog_an rout_man_an n_rout_man_an

local tasks_alm cognitive routine non_routine


*collapse (mean)  n_rout_anal n_rout_int rout_cog rout_man n_rout_man, by(year)


**************************************************************************************

*******************************************
**d: Task intensity by task group (Prep.)
*******************************************

*************
**d1: Harmonization of occupation groups across bibb samples
*************

**Harmonize occupation groups 

*keep only relevant occup vars

*drop occup_first occup_first_6st occup_first_pos occup_first_branch app_occup_3st occup_92_4st occup_10_3st

gen occup_3st = int(occup/10) if year==1979 | year==1992 | year==1999 | year==2006
replace occup_3st = occup if year==1986 | year==2012 | year==2018

gen occup_2st = int(occup_3st/10)

rename occup occup_4st
rename occup_3st occup

format  occup %03.0f if occup<100

gen occup_siab = 1 if occup==011|occup==012|occup==013|occup==014|occup==015|occup==016|occup==017|occup==018|occup==019|occup==020|occup==021|occup==022|occup==023|occup==024|occup==025|occup==026|occup==027|occup==028|occup==029|occup==030|occup==031|occup==032|occup==041|occup==042|occup==043|occup==044
replace occup_siab = 2 if occup==051|occup==052|occup==053|occup==054|occup==055|occup==056|occup==057|occup==058|occup==059|occup==060|occup==061|occup==062
replace occup_siab = 3 if occup==071|occup==072|occup==073|occup==074|occup==075|occup==076|occup==077|occup==078|occup==079|occup==080|occup==081|occup==082|occup==083|occup==084|occup==085|occup==086|occup==087|occup==088|occup==089|occup==090|occup==091|occup==101|occup==102|occup==103|occup==104|occup==105|occup==106|occup==107|occup==108|occup==109|occup==110|occup==111|occup==112
replace occup_siab = 4 if occup==121|occup==122|occup==123|occup==124|occup==125|occup==126|occup==127|occup==128|occup==129|occup==130|occup==131|occup==132|occup==133|occup==134|occup==135
replace occup_siab = 5 if occup==141
replace occup_siab = 6 if occup==142|occup==143|occup==144
replace occup_siab = 7 if occup==151
replace occup_siab = 8 if occup==161|occup==162|occup==163|occup==164
replace occup_siab = 9 if occup==171|occup==172|occup==173|occup==174
replace occup_siab = 10 if occup==175|occup==176|occup==177
replace occup_siab = 11 if occup==181|occup==182|occup==183|occup==184
replace occup_siab = 12 if occup==191|occup==192|occup==193|occup==194|occup==195|occup==196|occup==197|occup==198|occup==199|occup==200|occup==201|occup==202|occup==203
replace occup_siab = 13 if occup==211|occup==212|occup==213
replace occup_siab = 14 if occup==221
replace occup_siab = 15 if occup==222|occup==223|occup==224
replace occup_siab = 16 if occup==225|occup==226
replace occup_siab = 17 if occup==231|occup==232|occup==233|occup==234|occup==235|occup==242|occup==243|occup==244
replace occup_siab = 18 if occup==241
replace occup_siab = 19 if occup==251|occup==252|occup==263
replace occup_siab = 20 if occup==261
replace occup_siab = 21 if occup==262
replace occup_siab = 22 if occup==270|occup==271|occup==272
replace occup_siab = 23 if occup==273
replace occup_siab = 24 if occup==274|occup==275
replace occup_siab = 25 if occup==281
replace occup_siab = 26 if occup==282|occup==283|occup==284
replace occup_siab = 27 if occup==285|occup==286
replace occup_siab = 28 if occup==291|occup==301|occup==302
replace occup_siab = 29 if occup==303|occup==304|occup==305|occup==306
replace occup_siab = 30 if occup==311
replace occup_siab = 31 if occup==312|occup==313|occup==315
replace occup_siab = 32 if occup==314
replace occup_siab = 33 if occup==321
replace occup_siab = 34 if occup==322
replace occup_siab = 35 if occup==323
replace occup_siab = 36 if occup==331|occup==332|occup==333|occup==334|occup==335|occup==336|occup==337|occup==338|occup==339|occup==340|occup==341|occup==342|occup==343|occup==444|occup==345|occup==346|occup==371|occup==372|occup==373|occup==374|occup==375|occup==376|occup==377|occup==378
replace occup_siab = 37 if occup==351|occup==352|occup==353|occup==354|occup==355|occup==356|occup==357|occup==358|occup==359|occup==360|occup==361|occup==362
replace occup_siab = 38 if occup==391|occup==392
replace occup_siab = 39 if occup==401|occup==402|occup==403
replace occup_siab = 40 if occup==411|occup==412
replace occup_siab = 41 if occup==421|occup==422|occup==423|occup==424|occup==425|occup==426|occup==427|occup==428|occup==429|occup==430|occup==431|occup==432|occup==433
replace occup_siab = 42 if occup==441|occup==442
replace occup_siab = 43 if occup==451|occup==453
replace occup_siab = 44 if occup==452
replace occup_siab = 45 if occup==461|occup==462
replace occup_siab = 46 if occup==463|occup==464|occup==465|occup==466
replace occup_siab = 47 if occup==470|occup==471|occup==472
replace occup_siab = 48 if occup==481|occup==482
replace occup_siab = 49 if occup==483|occup==484|occup==485|occup==486
replace occup_siab = 50 if occup==491|occup==492|occup==502|occup==503|occup==504
replace occup_siab = 51 if occup==501
replace occup_siab = 52 if occup==511
replace occup_siab = 53 if occup==512|occup==513|occup==514
replace occup_siab = 54 if occup==521
replace occup_siab = 55 if occup==522
replace occup_siab = 56 if occup==531
replace occup_siab = 57 if occup==514|occup==542|occup==543|occup==544|occup==545|occup==546
replace occup_siab = 58 if occup==547|occup==548|occup==549
replace occup_siab = 59 if occup==601
replace occup_siab = 60 if occup==602
replace occup_siab = 61 if occup==603
replace occup_siab = 62 if occup==604|occup==605|occup==606|occup==607
replace occup_siab = 63 if occup==611|occup==612
replace occup_siab = 64 if occup==621
replace occup_siab = 65 if occup==622|occup==623
replace occup_siab = 66 if occup==624|occup==625|occup==626|occup==627
replace occup_siab = 67 if occup==628
replace occup_siab = 68 if occup==629
replace occup_siab = 69 if occup==631|occup==632
replace occup_siab = 70 if occup==633|occup==634
replace occup_siab = 71 if occup==635
replace occup_siab = 72 if occup==681
replace occup_siab = 73 if occup==682
replace occup_siab = 74 if occup==683|occup==684|occup==685|occup==686
replace occup_siab = 75 if occup==687|occup==688
replace occup_siab = 76 if occup==691|occup==692
replace occup_siab = 77 if occup==693|occup==694
replace occup_siab = 78 if occup==701
replace occup_siab = 79 if occup==702|occup==703|occup==704|occup==705|occup==706
replace occup_siab = 80 if occup==711|occup==712|occup==713|occup==715|occup==716
replace occup_siab = 81 if occup==714
replace occup_siab = 82 if occup==721|occup==722|occup==723|occup==724|occup==725|occup==726
replace occup_siab = 83 if occup==731|occup==732|occup==733|occup==734
replace occup_siab = 84 if occup==741
replace occup_siab = 85 if occup==742
replace occup_siab = 86 if occup==743|occup==744
replace occup_siab = 87 if occup==751
replace occup_siab = 88 if occup==752|occup==753
replace occup_siab = 89 if occup==761|occup==762|occup==763
replace occup_siab = 90 if occup==771|occup==772
replace occup_siab = 91 if occup==773
replace occup_siab = 92 if occup==774
replace occup_siab = 93 if occup==781
replace occup_siab = 94 if occup==782|occup==783
replace occup_siab = 95 if occup==784
replace occup_siab = 96 if occup==791|occup==792
replace occup_siab = 97 if occup==793|occup==794
replace occup_siab = 98 if occup==801|occup==802|occup==803|occup==804|occup==805|occup==806|occup==807|occup==808|occup==809|occup==810|occup==811|occup==812|occup==813|occup==814
replace occup_siab = 99 if occup==821|occup==822|occup==823
replace occup_siab = 100 if occup==831|occup==832|occup==833|occup==834
replace occup_siab = 101 if occup==835|occup==836|occup==837|occup==838
replace occup_siab = 102 if occup==841|occup==842|occup==843|occup==844
replace occup_siab = 103 if occup==851|occup==852
replace occup_siab = 104 if occup==853
replace occup_siab = 105 if occup==854
replace occup_siab = 106 if occup==855|occup==857
replace occup_siab = 107 if occup==856
replace occup_siab = 108 if occup==861|occup==863|occup==891|occup==892|occup==893
replace occup_siab = 109 if occup==862
replace occup_siab = 110 if occup==864
replace occup_siab = 111 if occup==871|occup==872|occup==873|occup==874
replace occup_siab = 112 if occup==875|occup==876|occup==877
replace occup_siab = 113 if occup==881|occup==882|occup==883
replace occup_siab = 114 if occup==901|occup==902
replace occup_siab = 115 if occup==911|occup==912
replace occup_siab = 116 if occup==913
replace occup_siab = 117 if occup==921|occup==922|occup==923|occup==924
replace occup_siab = 118 if occup==931|occup==932
replace occup_siab = 119 if occup==933|occup==934
replace occup_siab = 120 if occup==935|occup==936|occup==937

rename occup occup_3st

**remove occups with military or civil servants only
drop if occup_siab == 89 | occup_siab == 98 

**gen occup_siab indicator
tab occup_siab, gen(occup_siab)

*************
**h: Create occupation-specific task categores based on KldB92 (SOEP measure)
*************

*************************************************************************************
 
 **Remove empty observation on occupation
drop if occup_siab==.


**Spitz Oener
foreach i of local tasks_so {
		bysort occup_siab: egen `i'_occ_w=wtmean(`i'), weight(occup_3st)
}	


**Antonczyk
foreach i of local tasks_an {
		bysort occup_siab: egen `i'_occ_w=wtmean(`i'), weight(occup_3st)
}	

**ALM
foreach i of local tasks_alm {
		bysort occup_siab: egen `i'_occ_w=wtmean(`i'), weight(occup_3st)
}	

***************************

***by 3digit occupations

**Antonczyk
foreach i of local tasks_an {
		bysort occup_3st: egen `i'_occ_w3=wtmean(`i'), weight(occup_3st)
}

***************************

***occ-specific values for 90s and 00s sample

gen time_dummy = (year > 2000)

**Antonczyk
foreach i of local tasks_an {
		bysort occup_siab time_dummy: egen `i'_occ_wt=wtmean(`i'), weight(occup_3st)
}

**ALM
foreach i of local tasks_alm {
		bysort occup_siab time_dummy: egen `i'_occ_wt=wtmean(`i'), weight(occup_3st)
}



***************************
****Create occup-specific averages for each activity and then create occup-level: PCA (incl. standardizing) 


**PCA

**occupation-level
bysort occup_siab year: egen cognitive_pca_occ = mean(cognitive_pca)
egen cognitive_pca_occ_st = std(cognitive_pca_occ)

bysort occup_siab year: egen routine_pca_occ = mean(routine_pca)
egen routine_pca_occ_st = std(routine_pca_occ)

bysort occup_siab year: egen manual_pca_occ = mean(manual_pca)
egen manual_pca_occ_st = std(manual_pca_occ)

/*
**standardize pca scores with mean 0 (already have that mean) and std. dev. = 1
egen cognitive_pca_occ = std(cognitive_occ_w)
egen routine_pca_occ = std(routine_occ_w)
egen manual_pca_occ = std(non_routine_occ_w)


egen cognitive_pca_occ_ind = std(cognitive_occ_ind)
egen routine_pca_occ_ind = std(routine_occ_ind)
egen manual_pca_occ_ind = std(non_routine_occ_ind)
*/


save "$datenpfad\$bibb_all_adj_task", replace

	
log close
exit



