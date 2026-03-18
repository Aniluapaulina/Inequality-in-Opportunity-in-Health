********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 2_methodolody_para_cohort
***	   Description: Parametric methodology- Panel Analysis 			                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************

clear all
use $output/base.dta, clear 

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
 
 
misstable summarize ///
    mcs migback gender siblings ///
    msedu fsedu fprofstat mprofstat singleparent ///
    otherparent birthregion urban age age2 ///
    if cohort==1927 & syear==2002

	
	
* Panel analysis 
tempfile results
postfile pf ///
    cohort syear ///
    R2_mcs_orig R2_mcs_cfa ///
    GiniAbs_mcs_orig GiniRel_mcs_orig GiniAbs_mcs_cfa GiniRel_mcs_cfa ///
    R2_pcs_orig R2_pcs_cfa ///
    GiniAbs_pcs_orig GiniRel_pcs_orig GiniAbs_pcs_cfa GiniRel_pcs_cfa ///
    using `results', replace

levelsof syear, local(years)

* Main loop: 2002-2022
foreach cohort in 1927 1945 1964 1980 1996 2009{
	
	  foreach y of local years {
	  	
		* Mindestfallzahl absichern
        count if cohort == `cohort' & syear == `y'
        if r(N) < 20 continue
		
		count if cohort == `cohort' & syear == `y'
		di "cohort=" `cohort' " year=" `y' " N=" r(N)

	  	
*------------------------------------------------------------------------------
* MENTAL COMPONENT SCALE
*------------------------------------------------------------------------------
	* Outcome = SOEP MCS based on all weights from EFA 
	reg mcs i.yearofbirth i.migback gender /*siblings */ i.msedu i.fsedu i.fprofstat i.mprofstat /*singleparent otherparent*/ ///
	i.birthregion i.urban age age2 [fw=w] if cohort == `cohort' & syear == `y'
    local R2_mcs_orig = e(r2)
	
	capture drop mcs_orig_hat
	predict mcs_orig_hat if e(sample), xb
    ineqdeco mcs_orig_hat if e(sample)
    local GiniAbs_mcs_orig = $S_gini
    ineqdeco mcs if e(sample)
    local Gobs_mcs = $S_gini
    local GiniRel_mcs_orig = `GiniAbs_mcs_orig' / `Gobs_mcs'
 
	** Outcome = MCS based on CFA 
	reg mcs_cfa50  i.yearofbirth i.migback gender  /*siblings */ i.msedu i.fsedu i.fprofstat i.mprofstat /*singleparent otherparent*/ ///
	i.birthregion i.urban age age2 [fw=w] if cohort == `cohort' & syear == `y'
	local R2_mcs_cfa = e(r2)

	capture drop mcs_cfa50_hat
	predict mcs_cfa50_hat if e(sample), xb
    ineqdeco mcs_cfa50_hat if e(sample)
    local GiniAbs_mcs_cfa = $S_gini
    ineqdeco mcs_cfa50 if e(sample)
    local Gobs_mcs = $S_gini
    local GiniRel_mcs_cfa = `GiniAbs_mcs_cfa' / `Gobs_mcs'
	 
	 
*------------------------------------------------------------------------------
* PHYSICAL COMPONNET SCALE 
*------------------------------------------------------------------------------
	* Outcome = SOEP MCS based on all weights from EFA 
	reg pcs i.yearofbirth  i.migback gender  /*siblings */ i.msedu i.fsedu i.fprofstat i.mprofstat /*singleparent otherparent*/ ///
	i.birthregion i.urban age age2 [fw=w] if cohort == `cohort' & syear == `y'
    local R2_pcs_orig = e(r2)

	capture drop pcs_orig_hat
	predict pcs_orig_hat if e(sample), xb
    ineqdeco pcs_orig_hat if e(sample)
    local GiniAbs_pcs_orig = $S_gini
    ineqdeco pcs if e(sample)
    local Gobs_pcs = $S_gini
    local GiniRel_pcs_orig = `GiniAbs_pcs_orig' / `Gobs_pcs' 
	
	** Outcome = MCS based on CFA 
	reg pcs_cfa50  i.yearofbirth  i.migback gender  /*siblings */ i.msedu i.fsedu i.fprofstat i.mprofstat /*singleparent otherparent*/ ///
	i.birthregion i.urban age age2 [fw=w] if cohort == `cohort' & syear == `y'
	local R2_pcs_cfa = e(r2)

	capture drop pcs_cfa50_hat
	predict pcs_cfa50_hat if e(sample), xb
    ineqdeco pcs_cfa50_hat if e(sample)
    local GiniAbs_pcs_cfa = $S_gini
    ineqdeco pcs_cfa50 if e(sample)
    local Gobs_pcs = $S_gini
    local GiniRel_pcs_cfa = `GiniAbs_pcs_cfa' / `Gobs_pcs'

*------------------------------------------------------------------------------
* POST
*------------------------------------------------------------------------------

	 post pf ///
            (`cohort') (`y') ///
            (`R2_mcs_orig') (`R2_mcs_cfa') ///
            (`GiniAbs_mcs_orig') (`GiniRel_mcs_orig') ///
            (`GiniAbs_mcs_cfa') (`GiniRel_mcs_cfa') ///
            (`R2_pcs_orig') (`R2_pcs_cfa') ///
            (`GiniAbs_pcs_orig') (`GiniRel_pcs_orig') ///
            (`GiniAbs_pcs_cfa') (`GiniRel_pcs_cfa')
    }
		
}
	postclose pf

	
* load and results 
	use `results', clear
	order cohort, first
	sort cohort
	save "$output/para_IOp_cohort.dta", replace

	
* Graphs 
use "$output/para_IOp_cohort.dta", clear

* R^2 for MCS over time 
twoway ///
    (line R2_mcs_orig cohort, lwidth(medthick)) ///
    (line R2_mcs_cfa  cohort, lpattern(dot)), ///
    legend(order(1 "Original" 2 "CFA") rows(1)) ///
    title("Explained Variance over Time – MCS") ///
    ytitle("R-squared") ///
    xtitle("cohort")

	graph export "$output/mcs_R2_cohort.png", replace
	
	list cohort R2_mcs_orig R2_mcs_cfa, clean 
	/* Tabelle: 
  1.     1927   .4298359   .4778862  
  2.     1945   .0996828   .1279498  
  3.     1964   .0304053   .0420348  
  4.     1980   .0385806   .0524319  
  5.     1996   .0464336    .054958  
  6.     2009   .1213736   .1356299 
 */ 

	
* R^2 for PCS over time
twoway ///
    (line R2_pcs_orig cohort, lwidth(medthick)) ///
    (line R2_pcs_cfa  cohort, lpattern(dot)), ///
    legend(order(1 "Original" 2 "CFA") rows(1)) ///
    title("Explained Variance over Time – PCS") ///
    ytitle("R-squared") ///
    xtitle("cohort")