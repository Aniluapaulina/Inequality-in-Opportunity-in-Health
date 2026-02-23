********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 1_cleaning
***	   Description: Building basic datasets				                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************
* Was mache ich: Ich nehme ppathl (long) als Basis mit unique (pid syear), Migrationshintergrund, Geschlecht und Gewichten und spiele dann 
	* m:1 über (pid) die Elternvariables (bioparen) und Geschwister (biol)
	* und 1:1 über (pid syear) die Gesundheitsvariablen (health und pequiv) und Körpergröße (health) 

*-------------------------------------------------------------------------------
* LOADING RELEVANT DATASETS 
*-------------------------------------------------------------------------------

*** Baseline: ppathl
	use cid pid hid syear ///
	piyear	/// Year of interview
	birthregion /// Bundesland
	birthregion_ew /// Ost/West 
	gebjahr psample pop netto migback netto pbleib phrf phrf0 phrf1 psample sex using $data\ppathl.dta, clear 
	
	gen w = round(phrf)
	label var w "Weight"

	* Balance panel - keep only adults with successfull interviews 
	tab netto 
	keep if netto <= 19 & netto != -3
	drop netto

	* Consider only private households (mit deutschem und ausländischem HV)
	label list pop
	tab pop
	keep if pop == 1 | pop == 2
	drop pop
	
	* Ort der ersten Befragung
	sort pid syear
	by pid: gen firstint = piyear[1]
	label var firstint "Location of first observation"
	merge m:1 hid syear using $data\regionl.dta, keepusing(bula bula_ew ) keep (1 3) nogen
	
	save $output\ppathl.dta , replace

*** Dataset pequiv.dta (marital status, number of children and education)
	use hid pid syear /// 
	m11124				/// disability status (leider time-varying daher unbrauchbar als Ci)
	d11109 				/// education wrt high school 
	d11108				/// years of education
	m111*				/// health related variables 
	w11101 				/// individuals cross-sectional weight - without 1st wave of a subsample
	w11105 				/// cross-sectional weight - all samples
	using $data\pequiv.dta, clear 
	
	save $output/pequiv.dta , replace 

*** Dataset bioparen.dta
	use pid cid bioyear ///
	fnr1 mnr1 fnr2 mnr2 /// Personennummern Eltern 
	living1 			/// Anzahl Jahre leben bei leiblichen Eltern
	living2 			/// Anzahl Jahre leben bei alleinstehender Mutter
	living3 			/// Anzahl Jahre leben bei Mutter mit Partner
	living4 			/// Anzahl Jahre leben bei alleinstehendem Vater
	living5 			/// Anzahl Jahre leben bei Vater mit Partnerin
	living6 			/// Anzahl Jahre leben bei anderen Verwandten
	living7 			/// Anzahl Jahre leben bei Pflegeeltern
	living8				/// Anzahl Jahre leben im Heim
	locchildh			/// Ort der Kindheit
	freli mreli			/// Religion 
	fsedu msedu			/// Schulbschluss 
	fprofstat mprofstat	/// Berufliche Stellung 
	forigin morigin 	/// Herkunftsland 
	fnat mnat			/// Nationalität
	fnr1 fnr2			/// Pers. Nr. Vater1 und Mutter 1
	using $data\bioparen.dta, clear
	
	
	* Infos siblings aus der v39 
	merge 1:1 pid using $v39\bioparen.dta , keepusing(sibl nums numb twin) keep(3)
	gen siblingsv39 = numb + nums if numb >= 0 & nums >= 0
	replace siblingsv39 = 0 if sibl == 2
		
	keep pid cid living* siblingsv39 locchildh fsedu msedu fprofstat mprofstat forigin morigin fnat mnat fnr1 fnr2			
	
	save $output/bioparen.dta , replace 
	
*** Dataset biol.dta 
	use pid syear ///	
	lb0062 lb0063 /// Anzahl Bruder, Schwester vor 2014 
	lb0896 /// Anzahl Geschwister nur in 2014 
	lb1060 /// Anzahl Geschwister nach 2014 
	using $data\biol.dta, clear 

	gen siblings_raw = .
	* Geschiwister vor 2014
	mvdecode lb0062 lb0063, mv(-1 -3 -5 -8 -9)
	recode lb0062 (-2 = 0) // Annahme: -2 (trifft nicht zu) heißt "keine Geschwister, also 0"
	recode lb0063 (-2 = 0) // Annahme: -2 (trifft nicht zu) heißt "keine Geschwister, also 0"
	egen sib_pre2014 = rowtotal(lb0062 lb0063)
	replace siblings_raw = sib_pre2014 if syear < 2014 & (lb0062 != . | lb0063 != . )
	
	* Geschiwister in 2014
	mvdecode lb0896, mv(-1 -3 -5 -8 -9)
	recode lb0896 (-2 = 0) // Annahme: -2 (trifft nicht zu) heißt "keine Geschwister, also 0"
	replace siblings_raw = lb0896 if syear == 2014 & lb0896 != .
	
	* Geschwister nach 2014
	mvdecode lb1060, mv(-1 -3 -5 -8 -9)
	recode lb1060 (-2 = 0) // Annahme: -2 (trifft nicht zu) heißt "keine Geschwister, also 0"
	replace siblings_raw = lb1060 if syear > 2014  & lb1060 != .
	
	bys pid: egen siblings = max(siblings_raw) // Maximum Geschwister ist jetzt einfach die Annahme
	keep pid siblings 
	duplicates drop pid, force
	
	label var siblings "Amount of siblings"
	save $output/biol.dta , replace 
	
*** Datset health.dta 
	use pid syear valid ///
	mcs pcs /// mental component scale & physical component scale 
	pf_nbs rp_nbs bp_nbs gh_nbs vt_nbs sf_nbs re_nbs mh_nbs /// 8 subscales
	bmi height weight ///
	using $data/health.dta , clear 
	
	save $output/pre_health.dta , replace 
	
	
*-------------------------------------------------------------------------------
* MERGING DATA 
*------------------------------------------------------------------------------

// Personal level database 

use $output/ppathl.dta, clear
	sort hid pid syear
	duplicates report pid syear // unique 
	
	merge 1:1 pid syear using $output/health.dta,  keepusing(height) keep (1 3)
	drop _merge 
	
	merge 1:1 pid hid syear using $output/pequiv.dta, keep(1 3) // m111* Gesundheitsvariablen
	duplicates report hid syear pid
	drop _merge 
	
	merge m:1 pid using $output/bioparen.dta, keep(1 3) // living* und Berufe/Bildungshintergurnd der Eltern
	duplicates report hid syear pid
	drop _merge 
	
	merge m:1 pid using $output/biol.dta, keep(1 3) // Geschwister						 
	duplicates report hid syear pid
	drop _merge

	save $output/pre_ci.dta , replace
	

	
	
*-------------------------------------------------------------------------------
*  GENERATING RELEVANT VARIABLES 
*------------------------------------------------------------------------------

	// Health outcomes 
use $output/pre_health.dta , replace 
keep if valid == 1 // Observations every 2 years from 2002

tab syear 
	
	* Rekonstruierung Zeitachse für IAB-Stichproben bei Sondererhebungen
	gen syear_adj = syear
	replace syear_adj = syear - 1 if inlist(syear, 2017, 2019, 2021, 2023)
	
	duplicates tag pid syear_adj, gen(dup)
	tab dup	
	drop if dup > 0 & syear_adj != syear // keeping the observations from regular sampling 
	drop syear
	rename syear_adj syear

** Dichotomize SOEP PCS- and MCS-Scores
	gen mcs_binary = mcs
		replace mcs_binary = 0 if mcs < 50 
		replace mcs_binary = 1 if mcs >=50 
	gen pcs_binary = pcs
		replace pcs_binary = 0 if pcs < 50 
		replace pcs_binary = 1 if pcs >=50  
	
	label var mcs_binary "MCS above 50"
	label var pcs_binary "PCS above 50"
	

** Alternatives to the SOEP PCS- and MCS-Scores ... differetly weighted MCS & PCS: 
	* Confirmatory Factor Analysis (CFA)
	
	* 1) Schätzung der CFA für Basisjahr: zwei latente Faktoren, nur je 4 Subskalen. Mit cov(PCS*MCS) dürfen beide korreliert sein
		preserve
		keep if syear==2002 // Basisjahr 
		sem (PCS -> rp_nbs bp_nbs gh_nbs pf_nbs) (MCS -> vt_nbs sf_nbs re_nbs mh_nbs), cov(PCS*MCS)
		* cov(pcs,mcs) = 718, var(pcs) ≈ 748, var(mcs) ≈ 760 --> Corr = 718/sq(748*760) = 0,95 .... starke positive empirische Korrelation
		restore
		
	* 2) PCS und MCS Scores manuell berechnen mit (soeben geschätzten) fixen Gewichten. 
		* Die Scores werden als lineare Kombinationen der Subskalen, gewichtet nach diesen Faktorladungen.
		generate pcs_cfa = 1*rp_nbs + 0.9626645*bp_nbs + 0.9497551*gh_nbs + 0.9512468*pf_nbs
		generate mcs_cfa = 1*vt_nbs + 1.15413*sf_nbs + 1.16463*re_nbs + 1.072334*mh_nbs
	
		* 3) z-standardisieren & NBS 
		egen pcs_cfa_z = std(pcs_cfa)
		egen mcs_cfa_z = std(mcs_cfa)
		generate pcs_cfa50 = 50 + 10*pcs_cfa_z
		generate mcs_cfa50 = 50 + 10*mcs_cfa_z
		label var pcs_cfa50 "PCS using CFA"
		label var mcs_cfa50 "MCS using CFA"
		drop pcs_cfa mcs_cfa mcs_cfa_z pcs_cfa_z 	
	
** Fragility index 
	*  See Paper "Health ineqality and health types" by Borella using Health and Retirement Study (HRS)	
	
	save $output/health.dta , replace 
	
	
	
	// Circumstances 
use $output/pre_ci.dta , clear 		
	* Uniform English labels
		label var pid "Personal Identifier"
		label var hid "Household Identifier"
		label var syear "Survey year"
		label var psample "Subsample"
	
** Demographics 
	
	* Year of birth  
	rename gebjahr yearofbirth
	label var yearofbirth "Year of birth"
	drop if yearofbirth == -1
	
	gen age = 2026 - yearofbirth
	label var age "Age"
	
	gen age2 = age*age
	label var age2 "Age squared"
	
	* Female gender 	
	rename sex gender 
	recode gender (1=0) (2=1)
	label var gender "Gender"
	label define gender 0 "Male" 1 "Female"
	label val gender gender
	drop if gender < 0
	
	* Migration background 
	recode migback (1=0) (2=1) (3=1), gen (migback_binary)
	label var migback "Migration background"
	label var migback_binary "Migration background Binary "
		
	
** Childhood 

	* Number of siblings 
	tab siblings if siblingsv39 == . , mi
	replace siblingsv39 = siblings if siblingsv39 == . & siblings != .
	tab siblingsv39, mi
	drop siblings
	rename siblingsv39 siblings
	label var siblings "Number of siblings"
	
	su siblings[fw = w], de
	return list 
	replace siblings = `r(p99)' if siblings > `r(p99)' & siblings !=.
	
	
	* Mother's & Father's school education
	gen fedu6 = .
		replace fedu6 = 1 if inlist(fsedu, 1, -2 )
		replace fedu6 = 2 if inlist(fsedu, 2, 8)
		replace fedu6 = 3 if inlist(fsedu, 3)
		replace fedu6 = 4 if inlist(fsedu, 4,7,9)
		replace fedu6 = 5 if inlist(fsedu, 5)  
		replace fedu6 = 6 if inlist(fsedu, 6) 
		replace fedu6 = 7 if inlist(fsedu, -1) 
		replace fedu6 = 100 if inlist(fsedu, ., -5) 

	gen medu6 = .
		replace medu6 = 1 if inlist(msedu, 1, -2 )
		replace medu6 = 2 if inlist(msedu, 2)
		replace medu6 = 3 if inlist(msedu, 3,8)
		replace medu6 = 4 if inlist(msedu, 4,7,9)
		replace medu6 = 5 if inlist(msedu, 5)  
		replace medu6 = 6 if inlist(msedu, 6) 
		replace medu6 = 7 if inlist(msedu, -1 ) 
		replace medu6 = 100 if inlist(msedu, ., -5)
		
		label define edu6_lbl 1 "No degree" 2 "Secondary" 3 "Intermediate" 4 "Upper secondary" 5 "Other degree" 6 "No idea" 7 "Keine Angabe" 100 "Missing"
		label values fedu6 edu6_lbl
		label values medu6 edu6_lbl
		label var fedu6 "Father's school education"
		label var medu6 "Mother's school education"
	
	drop fsedu msedu
	rename fedu6 fsedu
	rename medu6 msedu
	
	
	* Mother's & Father's occupation when individual was 15 years old
		* Variante 1: 
		gen fprof7 = .
			replace fprof7 = 1 if inlist(fprofstat, 200, 210, 220, 230, 240, 250, 310, 320, 330, 510 )
			replace fprof7 = 2 if inlist(fprofstat, 400 , 410, 411, 412, 413, 414, 420, 421, 423, 422,424, 430, 431, 432, 433, 434 )
			replace fprof7 = 3 if inlist(fprofstat, 340, 500 , 520, 521,522, 530, 540, 550, 560 )
			replace fprof7 = 4 if inlist(fprofstat, 600, 610, 620, 630, 640 )
			replace fprof7 = 5 if inlist(fprofstat, 10, 11, 12, 13, 15, 110, 120, 130, 140 )
			replace fprof7 = 6 if inlist(fprofstat, 0)
			replace fprof7 = 7 if inlist(fprofstat, 1)
			replace fprof7 = 100 if inlist(fprofstat, -1, .)
		
		gen mprof7 = .
			replace mprof7 = 1 if inlist(mprofstat, 200, 210, 220, 230, 240, 250, 310, 320, 330, 510 )
			replace mprof7 = 2 if inlist(mprofstat, 400 , 410, 411, 412, 413, 414, 420, 421, 423, 422,424, 430, 431, 432, 433, 434 )
			replace mprof7 = 3 if inlist(mprofstat, 340, 500 , 520, 521,522, 530, 540, 550, 560 )
			replace mprof7 = 4 if inlist(mprofstat, 600, 610, 620, 630, 640 )
			replace mprof7 = 5 if inlist(mprofstat, 10, 11, 12, 13, 15, 110, 120, 130, 140 )
			replace mprof7 = 6 if inlist(mprofstat, 0)
			replace mprof7 = 7 if inlist(mprofstat, 1)
			replace mprof7 = 100 if inlist(mprofstat, -1, .)
			
		label define prof7_lbl 1 "blue collar" 2 "selfemployed" 3 "white collar" 4 "civil servant" 5 "not working or in training" 6 "no idea" /// 
		7 "lebte nicht mehr" 100 "missing"
		label values fprof7 prof7_lbl
		label values mprof7 prof7_lbl
		label var fprof7 "Father's occupation at age 15 "
		label var mprof7 "Mother's occupation at age 15"
		
		
		* Variante 2 ( See Paper by Mel Bartley - that also touches on the National Statistics Socio-Economic Classification. Discussion about which occupation to put in which class/social position; categorisation for example based on the "degree of manuality" )
		gen fprof12 = . 
			replace fprof12 = 1 if inlist(fprofstat, 0 ) // weiss nicht 
			replace fprof12 = 2 if inlist(fprofstat, 1 ) // lebte nicht mehr
			replace fprof12 = 3 if inlist(fprofstat, 10, 12 ) // nicht erw.taetig + Arbeitslos,Krank --> starke gesundheitliche Selektion & Stress
			replace fprof12 = 4 if inlist(fprofstat, 11, 15,  110, 120, 130, 140) // in Ausbildung + Wehrdienst --> Übergangsphase, meist jung 
			replace fprof12 = 5 if inlist(fprofstat, 13 ) // Rentner --> meist alt, zumindest körperlich geschwächter 
			
			replace fprof12 = 6 if inlist(fprofstat, 200, 210, 220, 230, 240, 250, 310, 320, 330, 510) 
				// Blue-collar worker = Körperlich belastende manuelle Arbeit
				// ungelernte & angelernte Arbeiter + Facharbeiter + Vorarbeiter, Meister + Arbeiter in Landwirtschaft 
				// --> hohe physische Belastung, Unfallrisiken 
			
			replace fprof12 = 7 if inlist(fprofstat, 500, 520, 522, 523, 530) //
				// Dienstleistungs- & einfache Angestelltenberufe + mithelf.Fam.angeh.|
				// Angestellter + Ang. mit einfacher und mittlerer quali. Taetigkeit 
				// --> geringere körperliche, aber oft hohe psychosoziale Belastung, wenig bis mittlere Autonomie

			replace fprof12 = 8 if inlist(fprofstat, 340, 540, 550, 560 ) //
				// Hochqualifizierte Angestellte, umfassende Führungsaufgaben, Geschäftsführer
			
			replace fprof12 = 9 if inlist(fprofstat, 600, 610, 620) //
				// Beamte; einfacher und mittlerer Dienst 
				
			replace fprof12 = 10 if inlist(fprofstat, 630, 640 ) //
				// Beamte höherer und gehobener Dienst 
			
			replace fprof12 = 11 if inlist(fprofstat, 400 , 410, 411, 420, 421, 431, 440 ) //
				// Solo Selbständige und Freiberufler (ohne Mitarbeiter); auch mithelf. Fam.angeh.
			
			replace fprof12 = 12 if inlist(fprofstat, 422, 423, 424, 432, 433, 434 ) //
				// Selbständige und Freiberufler mit Mitarbeitern 
				
			replace fprof12 = 13 if inlist(fprofstat, -1, .) 
				// Missing 
				
		gen mprof12 = . 
			replace mprof12 = 1 if inlist(mprofstat, 0 )  
			replace mprof12 = 2 if inlist(mprofstat, 1 ) 
			replace mprof12 = 3 if inlist(mprofstat, 10, 12 ) 
			replace mprof12 = 4 if inlist(mprofstat, 11, 15,  110, 120, 130, 140) 
			replace mprof12 = 5 if inlist(mprofstat, 13 ) 
			replace mprof12 = 6 if inlist(mprofstat, 200, 210, 220, 230, 240, 250, 310, 320, 330, 510) 	
			replace mprof12 = 7 if inlist(mprofstat, 500, 520, 522, 523, 530, 440) 
			replace mprof12 = 8 if inlist(mprofstat, 340, 540, 550, 560 ) 
			replace mprof12 = 9 if inlist(mprofstat, 600, 610, 620) 
			replace mprof12 = 10 if inlist(mprofstat, 630, 640 ) 
			replace mprof12 = 11 if inlist(mprofstat, 400, 410, 411, 420, 421, 431 ) 
			replace mprof12 = 12 if inlist(mprofstat, 422, 423, 424, 432, 433, 434 ) 
			replace mprof12 = 100 if inlist(mprofstat, -1, .)
			
			label define prof12_lbl 1 "no idea" 2 "lebte nicht mehr" 3 "nicht arbeitend" 4 "in Ausbildung/Wehrdienst" ///
			5 "rentenbeziehend" 6 "Blue-collar" 7 "Dienstleistungs- & einfache Angestelltenberufe" ///
			8 "Hochqualifizierte Angestellte und Führungskräfte" 9 "Beamte, einfache oder mittlerer Dienst" ///
			10 "Beamte, gehobener oder höherer Dienst" 11 "Solo Selbständige und Freiberufler" 12 "Selbständige und Freiberufler mit Mitarbeitern" ///
			100 "Missing"
			
			label values fprof12 prof12_lbl
			label values mprof12 prof12_lbl
			label var fprof12 "Father's  occupation at age 15 "
			label var mprof12 "Mother's occupation at age 15"
		
			drop mprofstat fprofstat
			rename fprof12 fprofstat
			rename mprof12 mprofstat
		
	* (Partially) raised in single-parent household (at least one year until age 15)
	* Missings umcoden für living* und fsedu msedu
	foreach i of numlist 1/8 {
		mvdecode living`i', mv(-3 -4 -5 -8 -9)
		recode living`i' (-2 = 0) // Annahme: -2 (trifft nicht zu) heißt 0
	}
	tab living1, mi // 45,000 von 118,000 Observationen sind missings 
	
	gen singleparent = .
		replace singleparent = 1 if (living2 != . & living4 !=. ) & ((living2 > 0 | living4 > 0) | (living2 > 0 & living4 > 0))
		replace singleparent = 0 if (living2 == 0 & living4 == 0) | (living2 == -2 & living4 == -2) 
		replace singleparent = 3 if (living2 == . & living4 == .) 
	label var singleparent "Raised in single-parent household until age 15"
		
	* (Partially) raised in foster-parents household, in a children's home or with relatives other than parents (at least one year until age 15)
	gen otherparent = .
		replace otherparent = 1 if (living6 != . & living7 !=. & living8 !=.) & ((living6 > 0 | living7 > 0 | living8 > 0) | ///
		(living6 > 0 & living7 > 0 & living8 > 0)| (living6 > 0 & living7 > 0 | living8 > 0) | (living6 > 0 | living7 > 0 & living8 > 0)) 
		replace otherparent = 0 if (living6 == 0 & living7 == 0 & living8 == 0)| (living6 == -2 & living7 == -2 & living8 == -2)
		replace otherparent = 3 if (living6 == . & living7 == . & living8) 
	label var otherparent "Raised in other-parent household until age 15"
		
		 
** Place Effects 
	* Federal state born
	tab birthregion
	label var birthregion "Federal state born"
	
	// Es gibt einen Indikator für Ost/West (birthregion_ew), aber der ist weniger informativ als birthregion, also korrigiere ich ihn 
	count if birthregion >0 &  birthregion_ew <0 //  11,650 Fälle mit Infos über Bundesland (birthregion) aber nicht Ost/West (birthregion_ew) 
	recode birthregion_ew (21 = 1) (22 = 0)
	replace birthregion_ew = 1 if inlist(birthregion, 1,2,3,4,5,6,7,8,9,10) 	// warum so viele änderungen? - weil die 11,650 aufgefüllt werden 
	replace birthregion_ew = 0 if inlist(birthregion, 11,12,13,14,15,16)		// warum so viele änderungen? - weil die 11,650 aufgefüllt werden
	label var birthregion_ew "Born in West Germany"	
	label define birthregion_lbl  0 "East" 1 "West" 2 "Abroad" 100 "Missing"
	label values birthregion_ew birthregion_lbl 
	
	// Nicht in Deutschland geboren als 17.Kategorie (birthregion) bzw. 3.Kategorie(birthregion_ew) == direkter Migrationshintergrund 
	replace birthregion = 17 if migback == 2
	replace birthregion_ew = 2 if migback == 2
	
	// Fehlende Werte mithilfe von Informationen über den Ort der ersten befragen auffüllen 
	tab bula_ew birthregion_ew, mi 
	replace birthregion_ew = 0 if bula_ew == 22 & birthregion_ew <= 0 & migback != 2
	replace birthregion_ew = 1 if bula_ew == 21 & birthregion_ew <= 0 & migback != 2
	
	forvalues var = 1/16 {
		replace birthregion = `var' if bula == `var' & birthregion <= 0 & migback != 2
	}
	
	tab birthregion, mi
	drop if birthregion == -2 
	
	* Urbanization (countryside, small or medium city, large city)
	recode locchildh (3 = 2) (4 = 3) (-4 = 100) (-5 = 100) (-2 = 4) (-1 = 100) , gen(urban)
	label define urbanl  1 "Large city" 2 "Small or medium city" 3 "Countryside" 4 "Trifft nicht zu" 100 "Keine Angabe"
	label values urban urbanl
	label var urban "Urbanization of place of upbringing"
	
** Keep the variables relevant for C_i
	keep pid syear phrf pbleib w psample yearofbirth migback_binary migback gender ///
	siblings msedu fsedu fprof7 mprof7 fprofstat mprofstat singleparent otherparent ///
	birthregion_ew birthregion urban age age2
	
	duplicates report pid syear
	save $output/ci.dta , replace
	 
	
	
	
*-------------------------------------------------------------------------------
*  Dealing with Missings
*------------------------------------------------------------------------------

*  Only observations with full information on C_i, MCS_i and PCS_i 
	use $output/health.dta , replace 
	keep if valid == 1 // habe ich bereits in oberen Schritt eingefügt vor den Berechnungen für alternative MCS/PCS
	drop height 
	merge 1:1 pid syear using $output/ci.dta , keep (3) nogen // keep only matched observations 
	di _N 
	
	// Observations for both MCS and PCS
	drop if (mcs < 0 & pcs <0 ) | (mcs <0 & pcs>0) | (mcs >0 & pcs <0 )			// 1 observation where mcs < 0 and pcs > 0
	
	// Ci 
	tab migback, mi 		// 0
	tab siblings, mi 		// 9,676 
	tab msedu, mi			// 9,110 
	tab fsedu, mi			// 3,007 
	tab mprofstat, mi 		// 8,547
	tab fprofstat, mi 		// 18,308
	tab singleparent, mi	// 0
	tab otherparent, mi		// 104 

	drop if missing(siblings, msedu, fsedu, mprofstat, fprofstat, otherparent)
	
	di _N
	tab syear // zwischen 16,000 und 23,000 Beobachtungen in Jahren 2002-2022(2)
	
	/*
			  syear |      Freq.     Percent        Cum.
		------------+-----------------------------------
			   2002 |     19,622        8.24        8.24
			   2004 |     19,755        8.30       16.54
			   2006 |     19,716        8.28       24.83
			   2008 |     17,898        7.52       32.34
			   2010 |     17,046        7.16       39.51
			   2012 |     18,705        7.86       47.36
			   2014 |     24,500       10.29       57.66
			   2016 |     24,364       10.24       67.89
			   2018 |     26,251       11.03       78.92
			   2020 |     26,614       11.18       90.10
			   2022 |     23,564        9.90      100.00
		------------+-----------------------------------
			  Total |    238,035      100.00
	*/
	
	drop if msedu == 100
	drop if fsedu == 100
	drop if mprofstat == 100
	drop if fprofstat == 100
	drop if otherparent == 3
	drop if singleparent == 3
	
	di _N
	tab syear
	/*
			  syear |      Freq.     Percent        Cum.
		------------+-----------------------------------
			   2002 |      9,115        6.72        6.72
			   2004 |      9,698        7.15       13.87
			   2006 |     10,646        7.85       21.72
			   2008 |      9,985        7.36       29.08
			   2010 |     10,271        7.57       36.65
			   2012 |     13,346        9.84       46.49
			   2014 |     16,305       12.02       58.51
			   2016 |     14,639       10.79       69.30
			   2018 |     16,782       12.37       81.67
			   2020 |     15,460       11.40       93.07
			   2022 |      9,397        6.93      100.00
		------------+-----------------------------------
			Total |    135,644      100.00

	- loss of obersations in 2022 largely driven by the variables *sedu, *profstat, aber auch otherparent und singleparent
	- see 2_descriptivestatistics 
 */

	save $output/base.dta , replace
	
	
/*
*-------------------------------------------------------------------------------
*  *COHORT ANALYSIS 
*------------------------------------------------------------------------------
	
	gen cohort = .
	replace cohort = 1927 if inrange(yearofbirth, 1903, 1927)   
	replace cohort = 1945 if inrange(yearofbirth, 1928, 1945)   
	replace cohort = 1964 if inrange(yearofbirth, 1946, 1964)  
	replace cohort = 1980 if inrange(yearofbirth, 1965, 1980)  
	replace cohort = 1996 if inrange(yearofbirth, 1981, 1996)   
	replace cohort = 2009 if inrange(yearofbirth, 1997, 2009)  

	label define cohort 	///
		1927 "1901-1927"	/// 	"Greatest Generation" - wuchs in der Großen Depression auf, kämpfte im 2. WK
		1945 "1928–45" 		///		"Silent Generation" - wuchs während des 2.WK aus; geprägt vom Krieg und Wiederaufbau
		1964 "1946–64" 		///		Babyboomer - Wirtschaftswunder 
		1980 "1965–80" 		///		Generation X - DDR geprägt vom Systemwechsel 
		1996 "1981–96" 		///		Millenials (Generation Y) - Digitalisierung; Nachwendekinder DDR 
		2009 "1997-2009" 	// 		Generation Z - Digital Natives
	label values cohort cohort

	tab cohort, mi
	drop if cohort == . // 2 Observationen, eine davon mit missing yearofbirth und die andere mit yearofbirth==2021
	
	tab syear 

* Altersstrukturen
	su age if cohort == 1927
	su age if cohort == 1945
	su age if cohort == 1964
	su age if cohort == 1980
	su age if cohort == 1996
	su age if cohort == 2009	
	
* Durchschnittsalter je Kohorte 
	gen cohort_1 = 2026-yearofbirth if cohort == 1927 
	gen cohort_2 = 2026-yearofbirth if cohort == 1945 
	gen cohort_3 = 2026-yearofbirth if cohort == 1964 
	gen cohort_4 = 2026-yearofbirth if cohort == 1980 
	gen cohort_5 = 2026-yearofbirth if cohort == 1996 
	gen cohort_6 = 2026-yearofbirth if cohort == 2009 
	
	estpost summarize  ///
    cohort_1 cohort_2 cohort_3 cohort_4 cohort_5 cohort_6 [fw = w]
	
	matrix list e(mean)
	/*	cohort_1   cohort_2   cohort_3   cohort_4   cohort_5   cohort_6
	r1  103.11568  88.154647  70.202898  54.185924  38.791799   26.70419 */
	
	
	
* Repräsentataivität innerhalb der Kohorten 
	tab gender if cohort==1927 [aw=w], mi
	tab gender if cohort==1945 [aw=w], mi
	tab gender if cohort==1964 [aw=w], mi
	tab gender if cohort==1996 [aw=w], mi
	tab gender if cohort==2009 [aw=w], mi
	
	tab migback if cohort==1927 [aw=w], mi
	tab migback if cohort==1964 [aw=w], mi
	tab migback if cohort==1996 [aw=w], mi
	tab migback if cohort==2009 [aw=w], mi
 
	*/

	

*-------------------------------------------------------------------------------
*  *Bootstrap weights
*------------------------------------------------------------------------------
/* 
- 100 Hochrechnungsgewichte (bweight_1 - bweight_100) für das Bootsstrapping (für spätere Präzisionsschätzung von Statistiken)
- Warum kein Personen-Bootstrapping sondern Gewichte-Bootstrapping? --> Stichprobendesign 
SOEP ist keine einfache Zufallsstichprobe (gleiche Ziehungswahrscheinlichkeit), sondern ist geschichtet, stratifizert und oversampled. Zufälligkeit steckt also nicht in "welche person ziehe ich" sondern  in den Ziehungswahrscheinlichkeiten. Idee = was wäre, wenn das SOEP mit dem selben Stichprobendesign nochmal gezogen würde. Man erzeugt viele alternative Gewichtssätze, die jeweils eine mögliche Realisierung des Stichprobenplans darstellen. Statt Personen/Observationen neu zu ziehen, erzeugt man neue Gewichtungssätze. Man resampled also die Ziehungszahl 
- bsample ... bootstrap stichprobe mit Zurücklegen, stratifiziert nach Jahr (innerhalb jedes Jahres wird separat gezogen). Zurücklegen mit _N <= N im Stata(Jahr)
*/

use $output/base.dta , clear

set seed 12345

gen bweight_0 = w																				// I: w ist der Hochrechnungsfaktor (Stichprobengewichte) 

forvalues b=1(1)$B {
	gen bweight_`b'=.
	bsample, strata(syear) weight(bweight_`b')				
	replace bweight_`b'=bweight_`b'
	
	replace bweight_`b'=bweight_`b'*w
}

save $output\base_withbw.dta , replace

	
	
