
clear all
***Version festlegen
version 12
***Bildschirmausgabe steuern
set more off
set logtype text
set linesize 255



** Makros fÃ¼r Pfade
global datenpfad "C:\Users\estorm\Google Drive\BIBB data\BIBB-Erwerbstaetige_1-6\BIBB_ALLE\"
global outputpfad "C:\Users\estorm\Google Drive\BIBB data\Log Files\BIBB_log\"

*** Makros fÃ¼r Datei- und Outputnamen

global bibb_all BIBB_ALL.dta
global bibb_all_adj BIBB_ALL_ADJ.dta


global outputname <outputname> /*Outputname einfÃ¼gen*/

***Aufzeichnung Protokoll starten
capture log close
log using "$outputpfad\bibb_descriptives", replace


**************************************************************************************
**************************************************************************************

*******************************************
*******************************************
**III. Construct task groups based on BIBB 79-99
*******************************************
*******************************************

clear
use "$datenpfad\$bibb_all", clear


local tasks repair_renovate teach_train mach_op_ctrl res_an_eva_plan plan_con_des_sket rules_use neg_lob_coord_org sell_buy_advise_adv entertain_pres employ_manage_hr calc_bookkeeping correct_text_data mach_equip serve_accomodate rules_workout measure restaurate

local task_groups non_routine_analytic non_routine_interact routine_cognitive routine_manual non_routine_manual

local tasks_uncat grow_breed pack_ship comp_hardware materials security_measures medicine  foreign_lang comp_software occup_safety

local tasks_other task_mvp1 task_mvp2 task_mvp3 skills_total

local schooling haupt mittlere fachhoch abi

local schooling_voc school_vocfach_yr school_vocac_yr school_coll_yr school_uni_yr school_other_yr school_master_tech_yr school_voc_yr school_spec_prof 

local occup_info occup occup_hours_w occup_branch occup_firmsize worker employee clerk selfemp

local socioecon income birthyear sex state age population

local weight weighting_factor

*drop `tasks' `tasks_uncat' `task_groups' `tasks_other' `schooling' `schooling_voc' `occup_info' `socioecon' `weight'

drop self_employed east_west_dummy


*keep `tasks' `task_groups' year id

local non_routine_analytic res_an_eva_plan plan_con_des_sket rules_use rules_workout 

local non_routine_interactive neg_lob_coord_org sell_buy_advise_adv entertain_pres employ_manage_hr teach_train  

local routine_cognitive calc_bookkeeping correct_text_data measure 

local routine_manual mach_op_ctrl mach_equip  

local non_routine_manual repair_renovate serve_accomodate restaurate  



*******************************************
**b: Create categorical data
*******************************************

**Sample Restriction: 
**keep only workers aged 18-65
keep if age >=18 & age <=65
gen agesq = (age^2)/100



**drop self-employed
drop if self_employed==3
**drop if work less than 15 hours/week (to be consistent with SIAB restrictions)
drop if occup_hours_w<15
**drop if no obs on occupation
drop if occup==.
**Delete East-German states
drop if state == 12 | state == 13 | state == 14 | state == 15 | state == 16

*******************************************
**Career

replace occup_tenure = year - occup_tenure 
gen occup_tenure_sq = (occup_tenure^2)/100

replace firm_tenure = year - firm_tenure if year==1999 | year==2006 | year==2012 | year==2018 
gen firm_tenure_sq = (firm_tenure^2)/100

*******************************************
**Education 

drop if birthyear==9999

gen school_years = degree_year - birthyear - 6
gen school_years2 = degree_year - year - age -6

gen test = school_years-school_years2

gen dropout = year==1992 & (degree==6)
replace dropout = 1 if year==1999 & (degree==9)
replace dropout = 1 if year==2006 & (degree==1)
replace dropout = 1 if year==2012 & (degree==1 | degree==12)
replace dropout = 1 if year==2018 & (degree==1 | degree==12)

gen haupt = year==1979 & (degree==1)
replace haupt = 1 if year==1986 & (degree==2)
**bei 1986 kein Abschluss: degree==1 
replace haupt = 1 if year==1992 & (degree==1)
**bei 1992 kein Abschluss: degree==6
replace haupt = 1 if (year==1999 & degree==1) | (year==1999 & degree==2) | (year==1999 & degree==3)
**bei 1999 kein Abschluss: degree==9
replace haupt = 1 if year==2006 & (degree==2)

replace haupt = 1 if year==2012 & (degree==1 | degree==2 | degree==3)
**auch mal zwecks robustheit haupt und kein abschluss in einem 
replace haupt = 1 if year==2018 & (degree==1 | degree==2 | degree==3)

gen mittlere = year==1979 & (degree==2)
replace mittlere = 1 if year==1986 & (degree==3)
replace mittlere = 1 if year==1992 & (degree==2)
replace mittlere = 1 if year==1999 & (degree==4)
replace mittlere = 1 if year==2006 & (degree==3)
replace mittlere = 1 if year==2012 & (degree==4 | degree==5 | degree==6 )
replace mittlere = 1 if year==2018 & (degree==4 | degree==5 | degree==6 )

/*
gen fachhoch = year==1979 & (degree==3)
replace fachhoch = 1 if year==1986 & (degree==4)
replace fachhoch = 1 if year==1992 & (degree==3)
replace fachhoch = 1 if year==1999 & (degree==5)
*/

**abi und fachhochschule
gen abi = year==1979 & (degree==4 | degree==3)
replace abi = 1 if year==1986 & (degree==5 | degree==4)
replace abi = 1 if year==1992 & (degree==4 | degree==3)
replace abi = 1 if (year==1999 & degree==6) | (year==1999 & degree==7) | (year==1999 & degree==5)
replace abi = 1 if year==2006 & (degree==4)
replace abi = 1 if year==2012 & (degree==7 | degree==8 | degree==9 )
replace abi = 1 if year==2018 & (degree==7 | degree==8 | degree==9 )

drop degree

gen school_degree = 0 if dropout==1
replace school_degree = 1 if haupt==1
replace school_degree = 2 if mittlere==1
replace school_degree = 3 if abi==1
*******************************************
** (Potential) experience

gen experience = year - degree_year

gen exp = age - 6 - 8 if dropout==1
replace exp = age - 6 - 9 if haupt==1
replace exp = age - 6 - 10 if mittlere==1
replace exp = age - 6 - 13 if abi==1
replace exp = age - 6 - 17 if educ_high==1
*******************************************
** Industry (broad)

rename occup_branch ob

**industry (Industrie)
gen sector = 1 if (year==1992 & industry==1)
replace sector = 1 if (year==1999 & industry==1)
replace sector = 1 if (year==2006 & industry==2)
replace sector = 1 if (year==2012 & industry==2)
replace sector = 1 if (year==2018 & industry==2)

replace sector = 1 if (year==1979 & ob>=5 & ob <=38) | (year==1986 & industry==1)

**craft (Handwerk)
replace sector = 2 if (year==1992 & industry==2)
replace sector = 2 if (year==1999 & industry==2)
replace sector = 2 if (year==2006 & industry==3)
replace sector = 2 if (year==2012 & industry==3)
replace sector = 2 if (year==2018 & industry==3)

replace sector = 2 if (year==1979 & ob>=39 & ob <=61) | (year==1979 & (ob==72 | ob == 72 | ob == 73 | ob == 83)) | (year==1986 & industry==2)

**trade (Handel)
replace sector = 3 if (year==1992 & industry==3)
replace sector = 3 if (year==1999 & industry==3)
replace sector = 3 if (year==2006 & industry==4)
replace sector = 3 if (year==2012 & industry==4)
replace sector = 3 if (year==2018 & industry==4)

replace sector = 3 if (year==1979 & ob>=95 & ob <=97) | (year==1986 & industry==3)

**services (Dienstleistungen)
replace sector = 4 if (year==1992 & industry==6)
replace sector = 4 if (year==1999 & industry==6)
replace sector = 4 if (year==2006 & industry==5)
replace sector = 4 if (year==2012 & industry==5)
replace sector = 4 if (year==2018 & industry==5)

replace sector = 4 if (year==1979 & ob>=70 & ob <=86) | (year==1979 & ob==69) | (year==1986 & industry==4)

**others (Sonstige)
replace sector = 5 if (year==1992 & industry==5)
replace sector = 5 if (year==1999 & industry==5) | (year==1999 & industry==7)
replace sector = 5 if (year==2006 & industry==6) | (year==2006 & industry==7)
replace sector = 5 if (year==2012 & industry==6) | (year==2012 & industry==7)
replace sector = 5 if (year==2018 & industry==6) | (year==2018 & industry==7)

replace sector = 5 if (year==1979 & ob>=0 & ob <=4) | (year==1979 & ob>=63 & ob <=68) | (year==1979 & ob>=87 & ob <=94) | (year==1986 & industry==5)

rename sector sector_broad


** Industry (narrow)
gen sector = .

replace sector = 1 if (year == 1992 & (ob == 63)) | (year == 1999 & (ob == 1)) |  (year == 2006 & (ob == 1 | ob == 2)) | (year == 2012 & (ob == 1 | ob == 2)) | (year == 2018 & (ob == 1 | ob == 2))
replace sector = 2 if (year == 1992 & (ob == 10)) | (year == 1999 & (ob == 10)) |  (year == 2006 & (ob == 10 | ob == 11 | ob == 23)) | (year == 2012 & (ob == 10 | ob == 11 | ob == 23)) | (year == 2018 & (ob == 10 | ob == 11 | ob == 23))
replace sector = 3 if (year == 1992 & (ob == 11)) | (year == 1999 & (ob == 11)) |  (year == 2006 & (ob == 24 | ob == 25)) | (year == 2012 & (ob == 24 | ob == 25)) | (year == 2018 & (ob == 10 | ob == 11 | ob == 23)) 
replace sector = 4 if (year == 1992 & (ob == 12)) | (year == 1999 & (ob == 12)) |  (year == 2006 & (ob == 26 | ob == 13 | ob == 14)) | (year == 2012 & (ob == 26 | ob == 13 | ob == 14)) | (year == 2018 & (ob == 26 | ob == 13 | ob == 14)) 
replace sector = 5 if (year == 1992 & (ob == 13) | ob == 21 | ob == 14) | (year == 1999 & (ob == 13 | ob == 21 | ob == 14)) |  (year == 2006 & (ob == 27 | ob == 28)) | (year == 2012 & (ob == 27 | ob == 28)) | (year == 2018 & (ob == 27 | ob == 28))
replace sector = 6 if (year == 1992 & (ob == 15)) | (year == 1999 & (ob == 15)) |  (year == 2006 & (ob == 29)) | (year == 2012 & (ob == 29)) | (year == 2018 & (ob == 29))
replace sector = 7 if (year == 1992 & (ob == 16)) | (year == 1999 & (ob == 16)) |  (year == 2006 & (ob == 34)) | (year == 2012 & (ob == 34)) | (year == 2018 & (ob == 34))
replace sector = 8 if (year == 1992 & (ob == 17)) | (year == 1999 & (ob == 17)) |  (year == 2006 & (ob == 35)) | (year == 2012 & (ob == 35)) | (year == 2018 & (ob == 35))
replace sector = 9 if (year == 1992 & (ob == 18)) | (year == 1999 & (ob == 18)) |  (year == 2006 & (ob == 30 | ob == 72)) | (year == 2012 & (ob == 30 | ob == 72)) | (year == 2018 & (ob == 30 | ob == 72))
replace sector = 10 if (year == 1992 & (ob == 19)) | (year == 1999 & (ob == 19)) |  (year == 2006 & (ob == 31)) | (year == 2012 & (ob == 31)) | (year == 2018 & (ob == 31))
replace sector = 11 if (year == 1992 & (ob == 20)) | (year == 1999 & (ob == 20)) |  (year == 2006 & (ob == 33)) | (year == 2012 & (ob == 33)) | (year == 2018 & (ob == 33))
replace sector = 12 if (year == 1992 & (ob == 22)) | (year == 1999 & (ob == 22)) |  (year == 2006 & (ob == 45)) | (year == 2012 & (ob == 45)) | (year == 2018 & (ob == 45))
replace sector = 13 if (year == 1992 & (ob == 23)) | (year == 1999 & (ob == 23)) |  (year == 2006 & (ob == 20 | ob ==36)) | (year == 2012 & (ob == 20 | ob ==36)) | (year == 2018 & (ob == 20 | ob ==36))
replace sector = 14 if (year == 1992 & (ob == 24)) | (year == 1999 & (ob == 24)) |  (year == 2006 & (ob == 21)) | (year == 2012 & (ob == 21)) | (year == 2018 & (ob == 21))
replace sector = 15 if (year == 1992 & (ob == 25)) | (year == 1999 & (ob == 25)) |  (year == 2006 & (ob == 22)) | (year == 2012 & (ob == 22)) | (year == 2018 & (ob == 22)) 
replace sector = 16 if (year == 1992 & (ob == 26)) | (year == 1999 & (ob == 26)) |  (year == 2006 & (ob == 19)) | (year == 2012 & (ob == 19)) | (year == 2018 & (ob == 19))
replace sector = 17 if (year == 1992 & (ob == 27)) | (year == 1999 & (ob == 27)) |  (year == 2006 & (ob == 17 | ob == 18)) | (year == 2012 & (ob == 17 | ob == 18)) | (year == 2018 & (ob == 17 | ob == 18))
replace sector = 18 if (year == 1992 & (ob == 28)) | (year == 1999 & (ob == 28)) |  (year == 2006 & (ob == 15 | ob == 16)) | (year == 2012 & (ob == 15 | ob == 16)) | (year == 2018 & (ob == 15 | ob == 16))
replace sector = 19 if (year == 1992 & (ob == 40 | ob == 41 | ob == 42)) | (year == 1999 & (ob == 40 | ob == 41 | ob == 42 | ob == 43)) |  (year == 2006 & (ob == 52 | ob == 50)) | (year == 2012 & (ob == 52 | ob == 50)) | (year == 2018 & (ob == 52 | ob == 50))
replace sector = 20 if (year == 1992 & (ob == 43 | ob == 44)) | (year == 1999 & (ob == 44 | ob == 45)) | (year == 2006 & (ob == 51 | ob == 70 | ob == 71)) | (year == 2012 & (ob == 51 | ob == 70 | ob == 71)) | (year == 2018 & (ob == 51 | ob == 70 | ob == 71))
replace sector = 21 if (year == 1992 & (ob == 50)) | (year == 1999 & (ob == 50)) |  (year == 2006 & (ob == 64)) | (year == 2012 & (ob == 64)) | (year == 2018 & (ob == 64))
replace sector = 22 if (year == 1992 & (ob == 51 | ob == 52)) | (year == 1999 & (ob == 51 | ob == 52 | ob == 53)) |  (year == 2006 & (ob == 60 | ob == 61 | ob == 62 | ob == 63)) | (year == 2012 & (ob == 60 | ob == 61 | ob == 62 | ob == 63)) | (year == 2018 & (ob == 60 | ob == 61 | ob == 62 | ob == 63))
replace sector = 23 if (year == 1992 & (ob == 53)) | (year == 1999 & (ob == 54)) |  (year == 2006 & (ob == 65 | ob == 67)) | (year == 2012 & (ob == 65 | ob == 67)) | (year == 2018 & (ob == 65 | ob == 67))
replace sector = 24 if (year == 1992 & (ob == 54)) | (year == 1999 & (ob == 55)) |  (year == 2006 & (ob == 66)) | (year == 2012 & (ob == 66)) | (year == 2018 & (ob == 66))
replace sector = 25 if (year == 1992 & (ob == 55)) | (year == 1999 & (ob == 56)) |  (year == 2006 & (ob == 55)) | (year == 2012 & (ob == 55)) | (year == 2018 & (ob == 55))
replace sector = 26 if (year == 1992 & (ob == 56)) | (year == 1999 & (ob == 60)) |  (year == 2006 & (ob == 80 | ob == 73)) | (year == 2012 & (ob == 80 | ob == 73)) | (year == 2018 & (ob == 80 | ob == 73))
replace sector = 27 if (year == 1992 & (ob == 57)) | (year == 1999 & (ob == 58 | ob == 59)) |  (year == 2006 & (ob == 74)) | (year == 2012 & (ob == 74)) | (year == 2018 & (ob == 74)) 
replace sector = 28 if (year == 1992 & (ob == 58)) | (year == 1999 & (ob == 57)) |  (year == 2006 & (ob == 85)) | (year == 2012 & (ob == 85)) | (year == 2018 & (ob == 85))
replace sector = 29 if (year == 1992 & (ob == 59)) | (year == 1999 & (ob == 62)) |  (year == 2006 & (ob == 91)) | (year == 2012 & (ob == 91)) | (year == 2018 & (ob == 91))
replace sector = 30 if (year == 1992 & (ob == 60)) | (year == 1999 & (ob == 61)) |  (year == 2006 & (ob == 75)) | (year == 2012 & (ob == 75)) | (year == 2018 & (ob == 75))
replace sector = 31 if (year == 1992 & (ob == 61)) | (year == 1999 & (ob == 63 | ob == 64)) |  (year == 2006 & (ob == 92 | ob == 32)) | (year == 2012 & (ob == 92 | ob == 32)) | (year == 2018 & (ob == 92 | ob == 32))
replace sector = 32 if (year == 1992 & (ob == 64)) | (year == 1999 & (ob == 65 | ob == 66)) |  (year == 2006 & (ob == 40 | ob == 90 | ob == 37 | ob == 41)) | (year == 2012 & (ob == 40 | ob == 90 | ob == 37 | ob == 41)) | (year == 2018 & (ob == 40 | ob == 90 | ob == 37 | ob == 41)) 
replace sector = 33 if (year == 1992 & (ob == 62 | ob == 29 | ob ==30)) | (year == 1999 & (ob == 29 | ob == 30 | ob == 67)) |  (year == 2006 & (ob == 93)) | (year == 2012 & (ob == 93)) | (year == 2018 & (ob == 93))


**also for 1979 and 1986
replace sector = . if sector == 5 & (year == 1979 | year == 1986) 

replace sector = 1 if (year == 1979 & (ob == 0 | ob == 1 | ob == 2 | ob == 3)) | (year == 1986 & (ob == 62))
replace sector = 2 if (year == 1979 & (ob == 6 | ob == 7)) | (year == 1986 & (ob == 10))
replace sector = 3 if (year == 1979 & (ob == 9 | ob == 10 | ob == 11 | ob  == 12 | ob  == 13)) | (year == 1986 & (ob == 11))
replace sector = 4 if (year == 1979 & (ob == 5 | ob  == 8 | ob  == 14 | ob  == 15 | ob == 16)) | (year == 1986 & (ob == 12))
replace sector = 5 if (year == 1979 & (ob == 17 | ob == 18 | ob == 19 | ob == 20 | ob == 21 | ob == 22 | ob == 23 | ob == 24 | ob == 25 | ob == 38 | ob == 39 | ob == 37)) | (year == 1986 & (ob == 13 | ob == 14 | ob == 21))
replace sector = 6 if (year == 1979 & (ob == 26 | ob == 27 | ob == 30)) | (year == 1986 & (ob == 15))
replace sector = 7 if (year == 1979 & (ob == 28 | ob == 29)) | (year == 1986 & (ob == 16))
replace sector = 8 if (year == 1979 & (ob == 31 | ob == 32)) | (year == 1986 & (ob == 17))
replace sector = 9 if (year == 1979 & (ob == 33)) | (year == 1986 & (ob == 18))
replace sector = 10 if (year == 1979 & (ob == 34)) | (year == 1986 & (ob == 19))
replace sector = 11 if (year == 1979 & (ob == 35 | ob == 36 | ob == 83)) | (year == 1986 & (ob == 20))
replace sector = 12 if (year == 1979 & (ob == 59 | ob == 60 | ob  == 61)) | (year == 1986 & (ob == 22))
replace sector = 13 if (year == 1979 & (ob == 40 | ob == 41 | ob == 42)) | (year == 1986 & (ob == 23))
replace sector = 14 if (year == 1979 & (ob == 43)) | (year == 1986 & (ob == 24))
replace sector = 15 if (year == 1979 & (ob == 44)) | (year == 1986 & (ob == 25))
replace sector = 16 if (year == 1979 & (ob == 45 | ob == 46)) | (year == 1986 & (ob == 26))
replace sector = 17 if (year == 1979 & (ob == 47 | ob == 48 | ob == 49 | ob == 50 | ob == 51 | ob == 52 | ob == 53)) | (year == 1986 & (ob == 27))
replace sector = 18 if (year == 1979 & (ob == 54 | ob == 55 | ob == 56 | ob == 57 | ob == 58)) | (year == 1986 & (ob == 28))
replace sector = 19 if (year == 1979 & (ob == 97)) | (year == 1986 & (ob == 40 | ob == 41 | ob == 42))
replace sector = 20 if (year == 1979 & (ob == 95 | ob == 96 | ob == 85)) | (year == 1986 & (ob == 44 | ob == 43))
replace sector = 21 if (year == 1979 & (ob == 64)) | (year == 1986 & (ob == 50))
replace sector = 22 if (year == 1979 & (ob == 63 | ob == 65 | ob == 66 | ob == 67 | ob == 68)) | (year == 1986 & (ob == 51 | ob == 52))
replace sector = 23 if (year == 1979 & (ob == 69)) | (year == 1986 & (ob == 53))
replace sector = 24 if (year == 1979 & (ob == 93)) | (year == 1986 & (ob == 54))
replace sector = 25 if (year == 1979 & (ob == 70)) | (year == 1986 & (ob == 55))
replace sector = 26 if (year == 1979 & (ob == 71 | ob == 74 | ob == 75)) | (year == 1986 & (ob == 56))
replace sector = 27 if (year == 1979 & (ob == 79 | ob == 80 | ob == 81 | ob == 82 | ob == 83)) | (year == 1986 & (ob == 57))
replace sector = 28 if (year == 1979 & (ob == 78 | ob == 84)) | (year == 1986 & (ob == 58))
replace sector = 29 if (year == 1979 & (ob == 87 | ob == 88 | ob == 89)) | (year == 1986 & (ob == 59))
replace sector = 30 if (year == 1979 & (ob == 91 | ob == 92 | ob == 94)) | (year == 1986 & (ob == 60))
replace sector = 31 if (year == 1979 & (ob == 76 | ob == 77)) 
*| (year == 1986 & (ob == ))
replace sector = 32 if (year == 1979 & (ob == 4)) | (year == 1986 & (ob == 63))
replace sector = 33 if (year == 1979 & (ob == 86 | ob == 72 | ob == 73)) | (year == 1986 & (ob == 61 | ob == 29 | ob == 30))


**string variable for each industry group
gen str20 sector_str = "agri_forestry" if sector==1
replace sector_str = "mining" if sector==2
replace sector_str = "chemical" if sector==3
replace sector_str = "stones_ceramics" if sector==4
replace sector_str = "iron prod" if sector==5
replace sector_str = "engineering" if sector==6
replace sector_str = "car_prod" if sector==7
replace sector_str = "ship_plane_prod" if sector==8
replace sector_str = "data process" if sector==9
replace sector_str = "electronics" if sector==10

replace sector_str = "mechanics" if sector==11
replace sector_str = "construction" if sector==12
replace sector_str = "wood" if sector==13
replace sector_str = "paper" if sector==14
replace sector_str = "print" if sector==15
replace sector_str = "leather" if sector==16
replace sector_str = "textile" if sector==17
replace sector_str = "food" if sector==18
replace sector_str = "retail" if sector==19
replace sector_str = "wholesale" if sector==20

replace sector_str = "post_office" if sector==21
replace sector_str = "transportation" if sector==22
replace sector_str = "banking" if sector==23
replace sector_str = "insurance" if sector==24
replace sector_str = "hospitality" if sector==25
replace sector_str = "education" if sector==26
replace sector_str = "freelancer" if sector==27
replace sector_str = "health" if sector==28
replace sector_str = "orga_admin" if sector==29
replace sector_str = "advocacy_groups" if sector==30

replace sector_str = "media_art" if sector==31
replace sector_str = "utilities" if sector==32
replace sector_str = "services_other" if sector==33

**industries that cannot be classified (consistently)
*replace sector = 34 if (year == 1992 & (ob == 31)) | (year == 1999 & (ob == 2 | ob == 31 | ob == 46)) |  (year == 2006 & (ob == 95 | ob == 96 | ob == 97 | ob == 98 | ob == 99 | ob == 100)) | (year == 2012 & (ob == 95 | ob == 96 | ob == 97 | ob == 98 | ob == 99 | ob == 100))


*******************************************
** Population

**Harmonize sizes of home city (4 classes: 0-20k / 20k-100k / 100k-500k / >500k)
*20k
gen pop = 1 if (year==1979 & population==1) 
replace pop = 1 if (year==1986 & population==1) | (year==1986 & population==2) | (year==1986 & population==3)
replace pop = 1 if (year==1992 & population==1) | (year==1992 & population==2) | (year==1992 & population==3)
replace pop = 1 if (year==1999 & population==1) | (year==1999 & population==2) | (year==1999 & population==3)
replace pop = 1 if (year==2006 & population==1) | (year==2006 & population==2) | (year==2006 & population==3)
replace pop = 1 if (year==2012 & population==1) | (year==2012 & population==2) | (year==2012 & population==3)
replace pop = 1 if (year==2018 & population==1) | (year==2018 & population==2) | (year==2018 & population==3)

*100k
replace pop = 2 if (year==1979 & population==2) 
replace pop = 2 if (year==1986 & population==4) | (year==1986 & population==5)
replace pop = 2 if (year==1992 & population==4) | (year==1992 & population==5) 
replace pop = 2 if (year==1999 & population==4) | (year==1999 & population==5)
replace pop = 2 if (year==2006 & population==4) | (year==2006 & population==5)
replace pop = 2 if (year==2012 & population==4) | (year==2012 & population==5)
replace pop = 2 if (year==2018 & population==4) | (year==2018 & population==5)

*500k
replace pop = 3 if (year==1979 & population==3) 
replace pop = 3 if (year==1986 & population==6) 
replace pop = 3 if (year==1992 & population==6) 
replace pop = 3 if (year==1999 & population==6) 
replace pop = 3 if (year==2006 & population==6) 
replace pop = 3 if (year==2012 & population==6) 
replace pop = 3 if (year==2018 & population==6) 

*>500k
replace pop = 4 if (year==1979 & population==4) 
replace pop = 4 if (year==1986 & population==7) 
replace pop = 4 if (year==1992 & population==7) 
replace pop = 4 if (year==1999 & population==7) 
replace pop = 4 if (year==2006 & population==7)
replace pop = 4 if (year==2012 & population==7)
replace pop = 4 if (year==2018 & population==7)

drop population
rename pop population

**gen dummy for large cities
gen urban = (pop==4)
*drop if population == .

*******************************************
** Firm size


**Harmonize sizes of Firm size (5 classes: 0-9 / 10-99 / 100-499 / 500-999 / 1000+)
*0-9
gen firm_size = 1 if (year==1979 & occup_firmsize==1) | (year==1979 & occup_firmsize==2)
replace firm_size = 1 if (year==1986 & occup_firmsize==1) | (year==1986 & occup_firmsize==2) 
replace firm_size = 1 if (year==1992 & occup_firmsize==1) | (year==1992 & occup_firmsize==2)
replace firm_size = 1 if (year==1999 & occup_firmsize==1) | (year==1999 & occup_firmsize==2)
replace firm_size = 1 if (year==2006 & occup_firmsize==1) | (year==2006 & occup_firmsize==2) | (year==2012 & occup_firmsize==3) | (year==2012 & occup_firmsize==4)
replace firm_size = 1 if (year==2012 & occup_firmsize==1) | (year==2012 & occup_firmsize==2) | (year==2012 & occup_firmsize==3) | (year==2012 & occup_firmsize==4)
replace firm_size = 1 if (year==2018 & occup_firmsize==1) | (year==2018 & occup_firmsize==2) | (year==2018 & occup_firmsize==3) | (year==2018 & occup_firmsize==4)

*10-99
replace firm_size = 2 if (year==1979 & occup_firmsize==3) | (year==1979 & occup_firmsize==4)
replace firm_size = 2 if (year==1986 & occup_firmsize==3) | (year==1986 & occup_firmsize==4) 
replace firm_size = 2 if (year==1992 & occup_firmsize==3) | (year==1992 & occup_firmsize==4)
replace firm_size = 2 if (year==1999 & occup_firmsize==3) | (year==1999 & occup_firmsize==4)
replace firm_size = 2 if (year==2006 & occup_firmsize==5) | (year==2006 & occup_firmsize==6) | (year==2012 & occup_firmsize==7)
replace firm_size = 2 if (year==2012 & occup_firmsize==5) | (year==2012 & occup_firmsize==6) | (year==2012 & occup_firmsize==7)
replace firm_size = 2 if (year==2018 & occup_firmsize==5) | (year==2018 & occup_firmsize==6) | (year==2018 & occup_firmsize==7)

*100-499
replace firm_size = 3 if (year==1979 & occup_firmsize==5) 
replace firm_size = 3 if (year==1986 & occup_firmsize==5) 
replace firm_size = 3 if (year==1992 & occup_firmsize==5) 
replace firm_size = 3 if (year==1999 & occup_firmsize==5) 
replace firm_size = 3 if (year==2006 & occup_firmsize==8) | (year==2006 & occup_firmsize==9)
replace firm_size = 3 if (year==2012 & occup_firmsize==8) | (year==2012 & occup_firmsize==9)
replace firm_size = 3 if (year==2018 & occup_firmsize==8) | (year==2018 & occup_firmsize==9)

*500-999
replace firm_size = 4 if (year==1979 & occup_firmsize==6) 
replace firm_size = 4 if (year==1986 & occup_firmsize==6) 
replace firm_size = 4 if (year==1992 & occup_firmsize==6) 
replace firm_size = 4 if (year==1999 & occup_firmsize==6) 
replace firm_size = 4 if (year==2006 & occup_firmsize==10)
replace firm_size = 4 if (year==2012 & occup_firmsize==10)
replace firm_size = 4 if (year==2018 & occup_firmsize==10)

*1000+
replace firm_size = 5 if (year==1979 & occup_firmsize==7) 
replace firm_size = 5 if (year==1986 & occup_firmsize==7) 
replace firm_size = 5 if (year==1992 & occup_firmsize==7) 
replace firm_size = 5 if (year==1999 & occup_firmsize==7) 
replace firm_size = 5 if (year==2006 & occup_firmsize==11)
replace firm_size = 5 if (year==2012 & occup_firmsize==11)
replace firm_size = 5 if (year==2018 & occup_firmsize==11)

rename occup_firmsize occup_firmsize_orig
rename firm_size occup_firmsize

**create variable for large firms: 1000+ employees
gen firm_large = (occup_firmsize==5)
*drop if occup_firmsize == .

*******************************************
**Income 

*<600
gen income_gr = 1 if (year==1979 & income==1) | (year==1979 & income==2) | (year==1986 & income==1) | (year==1986 & income==2) | (year==1992 & income==1) | (year==1999 & income==1) | (year==2006 & income<=600) | (year==2012 & income <=600) | (year==2018 & income <=600)
*600-1000
replace income_gr = 2 if (year==1979 & income==3) | (year==1979 & income==4) | (year==1986 & income==3) | (year==1986 & income==4) | (year==1992 & income==2) | (year==1999 & income==2) | (year==2006 & income<=1000 & income > 600) | (year==2012 & income<=1000 & income > 600) | (year==2018 & income<=1000 & income > 600)
*1000-1500
replace income_gr = 3 if (year==1979 & income==5) | (year==1979 & income==6) | (year==1986 & income==5) | (year==1986 & income==6) | (year==1992 & income==3) | (year==1999 & income==3) | (year==2006 & income<=1500 & income > 1000) | (year==2012 & income<=1500 & income > 1000) | (year==2018 & income<=1500 & income > 1000)
*1500-2000
replace income_gr = 4 if (year==1979 & income==7) | (year==1979 & income==8) | (year==1986 & income==7) | (year==1986 & income==8) | (year==1992 & income==5) | (year==1999 & income==4) | (year==2006 & income<=2000 & income > 1500) | (year==2012 & income<=2000 & income > 1500) | (year==2018 & income<=2000 & income > 1500)
*2000-2500
replace income_gr = 5 if (year==1979 & income==9) | (year==1986 & income==9) | (year==1986 & income==10) | (year==1992 & income==7) | (year==1999 & income==5) | (year==2006 & income<=2500 & income > 2000) | (year==2012 & income<=2500 & income > 2000) | (year==2018 & income<=2500 & income > 2000)
*2500-3000
replace income_gr = 6 if (year==1979 & income==10) | (year==1986 & income==11) | (year==1986 & income==12) | (year==1992 & income==8) | (year==1999 & income==6) | (year==2006 & income<=3000 & income > 2500) | (year==2012 & income<=3000 & income > 2500) | (year==2018 & income<=3000 & income > 2500)
*3000-4000
replace income_gr = 7 if (year==1979 & income==11) | (year==1986 & income==13) | (year==1986 & income==14) | (year==1992 & income==9) | (year==1992 & income==10) | (year==1999 & income==7) | (year==1999 & income==8) | (year==2006 & income<=4000 & income > 3000) | (year==2012 & income<=4000 & income > 3000) | (year==2018 & income<=4000 & income > 3000)
*4000-5000
replace income_gr = 8 if (year==1979 & income==12) | (year==1986 & income==15) | (year==1986 & income==16) | (year==1992 & income==9) | (year==1992 & income==11)| (year==1992 & income==12) | (year==1999 & income==9) | (year==1999 & income==10) | (year==2006 & income<=5000 & income > 4000) | (year==2012 & income<=5000 & income > 4000) | (year==2018 & income<=5000 & income > 4000)
*>5000
*>5000
replace income_gr = 9 if (year==1979 & income==13) | (year==1986 & income>=17 & income!=98 & income!=99 & income!=.a) | (year==1992 & income>=13 & income!=98 & income!=99 & income!=.a) | (year==1999 & income>=11 & income!=98 & income!=99 & income!=.a & income!=.t) | (year==2006 & income > 5000 & income!=99998 & income!=99999) | (year==2012 & income > 5000 & income!=99998 & income!=99999)

*drop if income_gr==.


*******************************************
**Real Income 

**Info for CPI taken from FRED via OECD with 2015=100
/*
79: 46.1612333489441
86: 58.7358338360608
92: 68.8028970737547
99: 78.8084709193956
06: 87.6090222739144
12: 97.1325871231064
*/

**for years with only interval data use the midpoint as income value

*79
replace income = 200 if (year==1979 & income==1) 
replace income = 500 if (year==1979 & income==2) 
replace income = 700 if (year==1979 & income==3)
replace income = 900 if (year==1979 & income==4) 
replace income = 1125 if (year==1979 & income==5) 
replace income = 1375 if (year==1979 & income==6) 
replace income = 1625 if (year==1979 & income==7) 
replace income = 1875 if (year==1979 & income==8)
replace income = 2250 if (year==1979 & income==9) 
replace income = 2750 if (year==1979 & income==10)
replace income = 3500 if (year==1979 & income==11) 
replace income = 4500 if (year==1979 & income==12) 
replace income = 5000 if (year==1979 & income==13) 


*86
replace income = 200 if (year==1986 & income==1) 
replace income = 500 if (year==1986 & income==2) 
replace income = 700 if (year==1986 & income==3)
replace income = 900 if (year==1986 & income==4) 
replace income = 1125 if (year==1986 & income==5) 
replace income = 1375 if (year==1986 & income==6) 
replace income = 1625 if (year==1986 & income==7) 
replace income = 1875 if (year==1986 & income==8)
replace income = 2125 if (year==1986 & income==9) 
replace income = 2375 if (year==1986 & income==10)
replace income = 2625 if (year==1986 & income==11) 
replace income = 2825 if (year==1986 & income==12) 
replace income = 3250 if (year==1986 & income==13) 
replace income = 3750 if (year==1986 & income==14)
replace income = 4250 if (year==1986 & income==15)
replace income = 4750 if (year==1986 & income==16)
replace income = 5250 if (year==1986 & income==17)
replace income = 5750 if (year==1986 & income==18)
replace income = 7000 if (year==1986 & income==19)
replace income = 9000 if (year==1986 & income==20)
replace income = 12500 if (year==1986 & income==21)
replace income = 15000 if (year==1986 & income==22)


*92
replace income = 300 if (year==1992 & income==1) 
replace income = 800 if (year==1992 & income==2) 
replace income = 1250 if (year==1992 & income==3)
replace income = 1750 if (year==1992 & income==5) 
replace income = 2250 if (year==1992 & income==7) 
replace income = 2750 if (year==1992 & income==8) 
replace income = 3250 if (year==1992 & income==9) 
replace income = 3750 if (year==1992 & income==10)
replace income = 4250 if (year==1992 & income==11) 
replace income = 4750 if (year==1992 & income==12)
replace income = 5250 if (year==1992 & income==13) 
replace income = 5750 if (year==1992 & income==14) 
replace income = 6000 if (year==1992 & income==16) 


*99
replace income = 300 if (year==1999 & income==1) 
replace income = 800 if (year==1999 & income==2) 
replace income = 1250 if (year==1999 & income==3)
replace income = 1750 if (year==1999 & income==4) 
replace income = 2250 if (year==1999 & income==5) 
replace income = 2750 if (year==1999 & income==6) 
replace income = 3250 if (year==1999 & income==7) 
replace income = 3750 if (year==1999 & income==8)
replace income = 4250 if (year==1999 & income==9) 
replace income = 4750 if (year==1999 & income==10)
replace income = 5250 if (year==1999 & income==11) 
replace income = 5750 if (year==1999 & income==12) 
replace income = 6500 if (year==1999 & income==13) 
replace income = 7500 if (year==1999 & income==14) 
replace income = 8500 if (year==1999 & income==15) 
replace income = 9500 if (year==1999 & income==16) 
replace income = 12500 if (year==1999 & income==17) 
replace income = 15000 if (year==1999 & income==18) 

*06
replace income = 7700 if income >= 7700 & year == 2006

*12
replace income = 7700 if income >= 7700 & year == 2012

*18
replace income = 7700 if income >= 7700 & year == 2018

**create cpi
gen cpi = 46.1612333489441 if year==1979
replace cpi = 58.7358338360608 if year==1986
replace cpi = 68.8028970737547 if year==1992
replace cpi = 78.8084709193956 if year==1999
replace cpi = 87.6090222739144 if year==2006
replace cpi = 97.1325871231064 if year==2012
replace cpi = 103.775629271545 if year==2018

**drop if no income reported or misreported observations
drop if income==99998 | income ==99999
*drop if income < 100 & year==2006
*drop if income < 100 & year==2012

**convert DM into EUR: official exchange rate is set at EUR 1 for DEM 1.95583 (1DM = 0.511291881)

replace income = income * 0.511291881 if (year == 1992 | year == 1999) & year !=.

**create real income
gen income_real = (income/cpi)*100 if income != .

replace income_real = (income/cpi)*100


**SIAB limits for years 1992, 99, 2006, 12: 3,284 / 3,603 / 3,926 / 3,768
gen income_real_cap = income_real 

replace income_real_cap = 2000 if income_real >= 2000 & income_real != . & year == 1979
replace income_real_cap = 2800 if income_real >= 2800 & income_real != . & year == 1986
replace income_real_cap = 3284 if income_real >= 3284 & income_real != . & year == 1992
replace income_real_cap = 3603 if income_real >= 3603 & income_real != . & year == 1999
replace income_real_cap = 3926 if income_real >= 3926 & income_real != . & year == 2006
replace income_real_cap = 3768 if income_real >= 3768 & income_real != . & year == 2012
replace income_real_cap = 3768 if income_real >= 3768 & income_real != . & year == 2018

**(real) hourly wage
gen wage_h = income_real/(occup_hours_w*4)
gen wage_hlog = log(wage_h)

* (real) daily wage
gen hours_d = occup_hours_w/5

gen wage_d = wage_h * hours_d
gen wage_dlog = log(wage_d)

**(real) hourly wage - CAPPED
gen wage_h_cap = income_real_cap/(occup_hours_w*4)
gen wage_hlog_cap = log(wage_h_cap)

**(real) daily wage - CAPPED
gen wage_d_cap = wage_h_cap * hours_d
gen wage_dlog_cap = log(wage_d_cap)

*******************************************
**Occupation type

gen workers = 0
gen employees = 0
gen clerks = 0
gen selfemps = 0
gen other_empls = 0

*79
replace workers = 1 if (year==1979 & occup_pos==1) | (year==1979 & occup_pos==2) | (year==1979 & occup_pos==3) | (year==1979 & occup_pos==4) | (year==1979 & occup_pos==5)
replace employees = 1 if (year==1979 & occup_pos==10) | (year==1979 & occup_pos==11) | (year==1979 & occup_pos==12) | (year==1979 & occup_pos==13) | (year==1979 & occup_pos==14) | (year==1979 & occup_pos==15)
replace clerks = 1 if (year==1979 & occup_pos==20) | (year==1979 & occup_pos==21) | (year==1979 & occup_pos==22) | (year==1979 & occup_pos==23)
replace selfemps = 1 if (year==1979 & occup_pos==40) | (year==1979 & occup_pos==41) | (year==1979 & occup_pos==42) | (year==1979 & occup_pos==43) | (year==1979 & occup_pos==44) | (year==1979 & occup_pos==45)
replace other_empls = 1 if (year==1979 & occup_pos==30)

*86
replace workers = 1 if (year==1986 & occup_pos==10) | (year==1986 & occup_pos==11) | (year==1986 & occup_pos==12) | (year==1986 & occup_pos==13) 
replace employees = 1 if (year==1986 & occup_pos==20) | (year==1986 & occup_pos==21) | (year==1986 & occup_pos==22) | (year==1986 & occup_pos==23) | (year==1986 & occup_pos==24) | (year==1986 & occup_pos==25)
replace clerks = 1 if (year==1986 & occup_pos==30) | (year==1986 & occup_pos==31) | (year==1986 & occup_pos==32) | (year==1986 & occup_pos==33)
replace selfemps = 1 if (year==1986 & occup_pos==40) | (year==1986 & occup_pos==41) | (year==1986 & occup_pos==42) | (year==1986 & occup_pos==43) | (year==1986 & occup_pos==44) | (year==1986 & occup_pos==45)
*92
replace workers = 1 if (year==1992 & occup_pos==10) | (year==1992 & occup_pos==11) | (year==1992 & occup_pos==12) | (year==1992 & occup_pos==13) 
replace employees = 1 if (year==1992 & occup_pos==20) | (year==1992 & occup_pos==21) | (year==1992 & occup_pos==22) | (year==1992 & occup_pos==23) | (year==1992 & occup_pos==24) | (year==1992 & occup_pos==25)
replace clerks = 1 if (year==1992 & occup_pos==30) | (year==1992 & occup_pos==31) | (year==1992 & occup_pos==32) | (year==1992 & occup_pos==33)
replace selfemps = 1 if (year==1992 & self_employed==3) 
*99
replace workers = 1 if (year==1999 & occup_pos==1) 
replace employees = 1 if (year==1999 & occup_pos==2) 
replace clerks = 1 if (year==1999 & occup_pos==3)
replace selfemps = 1 if (year==1999 & occup_pos==4)
replace other_empls = 1 if (year==1999 & occup_pos==5) | (year==1999 & occup_pos==6)
*06
replace workers = 1 if (year==2006 & occup_pos==1) 
replace employees = 1 if (year==2006 & occup_pos==2) 
replace clerks = 1 if (year==2006 & occup_pos==3)
replace selfemps = 1 if (year==2006 & occup_pos==4) | (year==2006 & occup_pos==5)
replace other_empls = 1 if (year==2006 & occup_pos==6) | (year==2006 & occup_pos==7) | (year==2006 & occup_pos==8) | (year==2006 & occup_pos==9)
*12
replace workers = 1 if (year==2012 & occup_pos==1) 
replace employees = 1 if (year==2012 & occup_pos==2) 
replace clerks = 1 if (year==2012 & occup_pos==3)
replace selfemps = 1 if (year==2012 & occup_pos==4) | (year==2012 & occup_pos==5)
replace other_empls = 1 if (year==2012 & occup_pos==6) | (year==2012 & occup_pos==7) | (year==2012 & occup_pos==9)
*18
replace workers = 1 if (year==2018 & occup_pos==1) 
replace employees = 1 if (year==2018 & occup_pos==2) 
replace clerks = 1 if (year==2018 & occup_pos==3)
replace selfemps = 1 if (year==2018 & occup_pos==4) | (year==2018 & occup_pos==5)
replace other_empls = 1 if (year==2018 & occup_pos==6) | (year==2018 & occup_pos==7) | (year==2018 & occup_pos==9)

egen worker_type = rowtotal(workers employees clerks selfemps)
**Drop other employment due to inconsistent appearance in surveys and occup_pos (not needed anymore)


*drop if worker_type==0
*drop worker employee clerk selfemp

**************************************************************************************


*******************************************
**Hierarchi level (following Cassidy)

gen hier_lower = 0
gen hier_middle = 0
gen hier_upper = 0
gen hier_exec = 0

gen civil = .

*79

replace hier_lower = 1 if (year==1979 & occup_pos==1) | (year==1979 & occup_pos==2) | (year==1979 & occup_pos==11) | (year==1979 & occup_pos==12) | (year==1979 & occup_pos==20)
replace hier_middle = 1 if (year==1979 & occup_pos==3) | (year==1979 & occup_pos==13) | (year==1979 & occup_pos==21) 
replace hier_upper = 1 if (year==1979 & occup_pos==4) | (year==1979 & occup_pos==14) | (year==1979 & occup_pos==22)
replace hier_exec = 1 if (year==1979 & occup_pos==5) | (year==1979 & occup_pos==15) | (year==1979 & occup_pos==23)

*86
replace hier_lower = 1 if (year==1986 & occup_pos==10) | (year==1986 & occup_pos==21) | (year==1986 & occup_pos==30) 
replace hier_middle = 1 if (year==1986 & occup_pos==11) | (year==1986 & occup_pos==22) | (year==1986 & occup_pos==31) 
replace hier_upper = 1 if (year==1986 & occup_pos==12) | (year==1986 & occup_pos==24) | (year==1986 & occup_pos==32) 
replace hier_exec = 1 if (year==1986 & occup_pos==13) | (year==1986 & occup_pos==25) | (year==1986 & occup_pos==33) | (year==1986 & occup_pos==20) 

*92
replace hier_lower = 1 if (year==1992 & occup_pos==10) | (year==1992 & occup_pos==21) | (year==1992 & occup_pos==30) 
replace hier_middle = 1 if (year==1992 & occup_pos==11) | (year==1992 & occup_pos==22) | (year==1992 & occup_pos==31) 
replace hier_upper = 1 if (year==1992 & occup_pos==12) | (year==1992 & occup_pos==24) | (year==1992 & occup_pos==32) 
replace hier_exec = 1 if (year==1992 & occup_pos==13) | (year==1992 & occup_pos==25) | (year==1992 & occup_pos==33) | (year==1992 & occup_pos==20)

*99
replace hier_lower = 1 if (year==1999 & occup_pos==10) | (year==1999 & occup_pos==21) | (year==1999 & occup_pos==30) 
replace hier_middle = 1 if (year==1999 & occup_pos==11)| (year==1999 & occup_pos==22) | (year==1999 & occup_pos==31) 
replace hier_upper = 1 if (year==1999 & occup_pos==12)| (year==1999 & occup_pos==24) | (year==1999 & occup_pos==32)  
replace hier_exec = 1 if (year==1999 & occup_pos==13)| (year==1999 & occup_pos==25) | (year==1999 & occup_pos==33) | (year==1999 & occup_pos==20)   

*06
replace hier_lower = 1 if (year==2006 & worker==1) | (year==2006 & employee==1) | (year==2006 & civil==1)
replace hier_middle = 1 if (year==2006 & worker==2) | (year==2006 & employee==2) | (year==2006 & civil==2) 
replace hier_upper = 1 if (year==2006 & worker==3) | (year==2006 & employee==3) | (year==2006 & civil==3) 
replace hier_exec = 1 if (year==2006 & worker==4) | (year==2006 & master_employee==1) | (year==2006 & civil==4) 

*12
replace hier_lower = 1 if (year==2012 & worker==1) | (year==2012 & employee==1) | (year==2012 & civil==1)
replace hier_middle = 1 if (year==2012 & worker==2) | (year==2012 & employee==2) | (year==2012 & civil==2) 
replace hier_upper = 1 if (year==2012 & worker==3) | (year==2012 & employee==3) | (year==2012 & civil==3) 
replace hier_exec = 1 if (year==2012 & worker==4) | (year==2012 & master_employee==1) | (year==2012 & civil==4) 

*18
replace hier_lower = 1 if (year==2018 & worker==1) | (year==2018 & employee==1) | (year==2018 & civil==1)
replace hier_middle = 1 if (year==2018 & worker==2) | (year==2018 & employee==2) | (year==2018 & civil==2) 
replace hier_upper = 1 if (year==2018 & worker==3) | (year==2018 & employee==3) | (year==2018 & civil==3) 
replace hier_exec = 1 if (year==2018 & worker==4) | (year==2018 & master_employee==1) | (year==2018& civil==4) 


egen hierarchy = rowtotal(hier_lower hier_middle hier_upper hier_exec)


drop other_empl occup_pos


***indicators

tab year, gen(year)
tab state, gen(state)
tab sector, gen(sector)


save "$datenpfad\$bibb_all_adj", replace

	
log close
exit
