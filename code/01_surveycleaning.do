/*******************************************************************************
- Do file to clean survey variables used in analysis
Author: Ryan McCord

 This do-file cleans the confidential facility survey data used in the analysis.

CONFIDENTIALITY NOTE
 -------------------------------------------------------------------------------
 The file `surveydata_drc2.dta` contains identifying information about 
 healthcare facilities and cannot be made public. Therefore, it is not included 
 in the replication package.

 To request access to the raw survey data, please contact:
   ryan.mccord@duke.edu

 RUNNING THIS SCRIPT
 -------------------------------------------------------------------------------
 • This do-file will run **only** if the confidential file is present in the 
   expected project directory:
        data/survey/surveydata_drc2.dta

*******************************************************************************/


/*** Project structure (EDIT THIS LINE ONLY) ***/
global project "/path/to/DRC_Electricity_HCFs"

/*** Confirm survey data file exists ***/
local surveyfile "$project/data/survey/surveydata_drc2.dta"

capture confirm file "`surveyfile'"
if _rc {
    di as error "----------------------------------------------------------------------------"
    di as error " ERROR: Confidential survey file not found:"
    di as error "        `surveyfile'"
    di as error " "
    di as error " This file is restricted and not included in the replication package."
    di as error " To request access, email: ryan.mccord@duke.edu"
    di as error "----------------------------------------------------------------------------"
    exit 1
}

/*** Load confidential data ***/
use "`surveyfile'", clear


/*******************************************************************************
 Construct variables used in analysis
*******************************************************************************/
	//V1 - weights perfect power days first
	gen weight_perfectpower = F1_outagedays/7

	gen weight_badpower = .
	replace weight_badpower = 0/31 if F1_outagedays==7
	replace weight_badpower = 0.5/31 if F5_baddays_freq==1 & weight_badpower==.
	replace weight_badpower = 2/31 if F5_baddays_freq==2 & weight_badpower==.
	replace weight_badpower = 4/31 if F5_baddays_freq==3 & weight_badpower==.
	replace weight_badpower = 8/31 if F5_baddays_freq==4 & weight_badpower==.

	replace weight_badpower = 0/31 if (F5_o_baddays_freq=="Aucun" | F5_o_baddays_freq == "Nos batteries sont encore très puissante, nous n'avons pas assez des coupures" | F5_o_baddays_freq=="Nous utilisons les panneaux solaires" | F5_o_baddays_freq=="Solaire" | F5_o_baddays_freq=="0" | F5_o_baddays_freq=="Chaque jour, normalement nous devons avoir l'électricité 24h sur 24" | F5_o_baddays_freq=="Nous connaissons de coupure en électricité lorsque Soccodé est en train de faire de réparation de leur ligne d'électricité le plus souvent le dimanche et ils annoncent 12h avant pour qu'on prenne de Disposition.") & weight_badpower==.
	replace weight_badpower = 4/31 if (F5_o_baddays_freq=="Chaque semaine" | F5_o_baddays_freq=="Beaucoup des semaines" | F5_o_baddays_freq=="Pendant la période pluvieuse, même une semaine peut finir sans électricité" | F5_o_baddays_freq=="Lappe torche") & weight_badpower==.
	replace weight_badpower = 15/31 if (F5_o_baddays_freq=="15" | F5_o_baddays_freq=="3-7" | F5_o_baddays_freq=="Dans les saisons pluvieuses les panneaux solaires ne fonctionnent pas  solaire" | F5_o_baddays_freq=="Toute la journée" | F5_o_baddays_freq=="12") & weight_badpower==.
	replace weight_badpower = 18/31 if (F5_o_baddays_freq=="4 à 5 par semaine" | F5_o_baddays_freq=="Plus de 3 fois par semaine") & weight_badpower==.
	replace weight_badpower = 24/31 if (F5_o_baddays_freq=="6 fois par semaine" | F5_o_baddays_freq == "On peut réaliser même six jours par semaine sans énergie" | F5_o_baddays_freq=="6fois par semaine" | F5_o_baddays_freq=="5 fois par semaine" | F5_o_baddays_freq=="Plus de 4 fois" | F5_o_baddays_freq=="Le courant n' est pas disponible, nous travaillons presque tous les jours avec le groupe.") & weight_badpower==.
	replace weight_badpower = 0.5/31 if F5_o_baddays_freq=="Certains mois" & weight_badpower==.
	replace weight_badpower = 1/31 if F5_o_baddays_freq=="Tous les mois" & weight_badpower==.
	replace weight_badpower = 31/31 if (F5_o_baddays_freq=="Tous les jours" | F5_o_baddays_freq == "30 jours par mois" | F5_o_baddays_freq == "De 21h jusqu'à 10h chaque jour") & weight_badpower==.
	replace weight_badpower = 31/31 if (F5_o_baddays_freq=="Non disponible" | F5_o_baddays_freq == "Pas d'électricité dans l'établissement" | F5_o_baddays_freq == "Présentement la structure n'a pas de source d'énergie. Le système solaire qu'on avait a été pillé. Donc tous les mois" | F5_o_baddays_freq == "Toujours pas d'électricité" | F5_o_baddays_freq == "Presque tous les jours il n'y a pas d'électricité." | F5_o_baddays_freq == "Pas d'électricité dans la structure" | F5_o_baddays_freq=="Pas du courant" | F5_o_baddays_freq=="7/7 jours" | F5_o_baddays_freq=="Pas d'électricité" | F5_o_baddays_freq=="30" | F5_o_baddays_freq=="pas connecté") & weight_badpower==.
	replace weight_badpower = 5/31 if (F5_o_baddays_freq=="5" | F5_o_baddays_freq=="Ça dépend du saison pluvieuse ou non.car nous utilisons les panneaux solaires") & weight_badpower==.
	replace weight_badpower = 1/31 if (F5_o_baddays_freq=="1" | F5_o_baddays_freq=="1h") & weight_badpower==.
	
	
	
	//replace days_wk_badpower = 10/31 if F5_o_baddays_freq=="Quand le système solaire tombe en panne"

	gen weight_typicalpower = 1 - (weight_badpower + weight_perfectpower)
	
	gen uptime = (24-(weight_badpower*F4_baddays + weight_perfectpower*0 + weight_typicalpower*F2_outagehrs))/24
	replace uptime=0 if uptime==.

	//V2 - weights typical power days first
	gen weight_typicalpower2 = F3_typicaldays/7

	gen weight_perfectpower2 = 1 - (weight_badpower + weight_typicalpower2)

	gen uptime2 = (24-(weight_badpower*F4_baddays + weight_perfectpower2*0 + weight_typicalpower2*F2_outagehrs))/24
	replace uptime2=0 if uptime2==.
	
	//V3 - uses 3-day recall
	replace F8a_2_timeout = 24 if F8a_2_timeout>24
	replace F8b_2_timeout = 24 if F8b_2_timeout>24
	replace F8c_2_timeout = 24 if F8c_2_timeout>24
	gen uptime3 = (24-(F8a_2_timeout+F8b_2_timeout+F8c_2_timeout)/3)/24

	
	
* Power sufficiency - either has a grid connection OR solar/generator that can power the full structure	
	gen sufficient = .
	replace sufficient = 1 if B1_grid < 9
	replace sufficient = 1 if (B1_grid >= 9 & C7_gen_qual==1)
	replace sufficient = 1 if (B1_grid >= 9 & D5_solar_qual==1)
	replace sufficient = 0 if B1_grid >= 9 & sufficient == .
	
	
	gen theft = 0 
	replace theft = 1 if I1_theft > 1

* Create binaries for grid y/n; solar y/n; generator y/n
	
gen grid=0
replace grid=1 if B1_grid<9
replace grid=1 if B1_grid_o=="ENk"
replace grid=1 if B1_grid_o=="SNEL"
replace grid=1 if B1_grid_o=="TURBINE MICROCENTRALE"
replace grid=1 if B1_grid_o=="PENK"
replace grid=1 if B1_grid_o=="Microturbine"
replace grid=1 if B1_grid_o=="Locale"

gen solar=0
replace solar=1 if D1_solar==1
replace solar=1 if B1_grid_o=="HETA"
replace solar=1 if B1_grid_o=="Panneaux solaires locaux"
replace solar=1 if B1_grid_o=="Système solaire"
replace solar=1 if B1_grid_o=="Énergie solaire locale"

gen generator=0
replace generator=1 if C1_gen==1
replace generator=1 if B1_grid_o=="Groupe électrogène communautaire"


**Prepare for export and merge
	rename A8_FOSA organisationunitname


/*******************************************************************************
 Export cleaned version (for merge with sensor + SNIS data)
*******************************************************************************/

export excel using "$project/output/Survey.xlsx", ///
    firstrow(variables) replace
	
	


