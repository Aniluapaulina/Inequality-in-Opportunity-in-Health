********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 3_meanbased_panel
***	   Description: Parametric methodology- Panel Analysis 			                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************

clear all
use $output/final.dta, clear 
*use $output/basenomissings.dta , clear
tab syear

* Bootrstrapping-based CI
local B 100
local wlist
forvalues b = 1/`B' {
    local wlist `wlist' w_`b'
}

* Panel analysis 
tempfile results
postfile pf ///
    year ///
    R2_mcs_orig R2_mcs_cfa ///
    GiniAbs_mcs_orig GiniRel_mcs_orig GiniAbs_mcs_cfa GiniRel_mcs_cfa ///
    R2_pcs_orig R2_pcs_cfa ///
    GiniAbs_pcs_orig GiniRel_pcs_orig  GiniAbs_pcs_cfa GiniRel_pcs_cfa ///
	using `results', replace
	

* Main loop: 2002-2022
forvalues yr = 2002(2)2022 {
	preserve
	
	keep if syear == `yr'
	
*------------------------------------------------------------------------------
* MENTAL COMPONENT SCALE
*------------------------------------------------------------------------------
	* Outcome = SOEP MCS based on all weights from EFA 
	reg mcs i.yearofbirth i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [aw=w]
    local R2_mcs_orig = e(r2)
	
    predict mcs_orig_hat, xb
    ineqdeco mcs_orig_hat
    local GiniAbs_mcs_orig = $S_gini
    ineqdeco mcs
    local Gobs_mcs = $S_gini
    local GiniRel_mcs_orig = `GiniAbs_mcs_orig' / `Gobs_mcs'
 
	
	** Outcome = MCS based on CFA 
	reg mcs_cfa50  ii.yearofbirth  i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [aw=w]
	local R2_mcs_cfa = e(r2)

    predict mcs_cfa50_hat, xb
    ineqdeco mcs_cfa50_hat
    local GiniAbs_mcs_cfa = $S_gini
    ineqdeco mcs_cfa50
    local Gobs_mcs = $S_gini
    local GiniRel_mcs_cfa = `GiniAbs_mcs_cfa' / `Gobs_mcs'
	 
	 
*------------------------------------------------------------------------------
* PHYSICAL COMPONNET SCALE 
*------------------------------------------------------------------------------
	* Outcome = SOEP MCS based on all weights from EFA 
	reg pcs i.yearofbirth  i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [aw=w]
    local R2_pcs_orig = e(r2)

    predict pcs_orig_hat, xb
    ineqdeco pcs_orig_hat
    local GiniAbs_pcs_orig = $S_gini
    ineqdeco pcs
    local Gobs_pcs = $S_gini
    local GiniRel_pcs_orig = `GiniAbs_pcs_orig' / `Gobs_pcs' 
	
	
	** Outcome = MCS based on CFA 
	reg pcs_cfa50  i.yearofbirth  i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [aw=w]
	local R2_pcs_cfa = e(r2)

    predict pcs_cfa50_hat, xb
    ineqdeco pcs_cfa50_hat
    local GiniAbs_pcs_cfa = $S_gini
    ineqdeco pcs_cfa50
    local Gobs_pcs = $S_gini
    local GiniRel_pcs_cfa = `GiniAbs_pcs_cfa' / `Gobs_pcs'

	post pf ///
    (`yr') ///
    (`R2_mcs_orig') (`R2_mcs_cfa') ///
    (`GiniAbs_mcs_orig') (`GiniRel_mcs_orig') ///
    (`GiniAbs_mcs_cfa') (`GiniRel_mcs_cfa') ///
    (`R2_pcs_orig') (`R2_pcs_cfa') ///
    (`GiniAbs_pcs_orig') (`GiniRel_pcs_orig') ///
    (`GiniAbs_pcs_cfa') (`GiniRel_pcs_cfa')
	
	restore 
		
}
	postclose pf

	
* load and results 
	use `results', clear
	order year, first
	sort year
	save "$output/para_IOp_timeseries.dta", replace

	
* Graphs 
use "$output/para_IOp_timeseries.dta", clear

* R^2 for MCS over time 
twoway ///
    (line R2_mcs_orig year, lwidth(medthick)) ///
    (line R2_mcs_cfa  year, lpattern(dot)), ///
    legend(order(1 "Original" 2 "CFA") rows(1)) ///
    title("Explained Variance over Time – MCS") ///
    ytitle("R-squared") ///
    xtitle("Year")

	graph export "$output/mcs_R2.png", replace
	
	list year R2_mcs_orig  R2_mcs_cfa, clean 
	
* R^2 for PCS over time
twoway ///
    (line R2_pcs_orig year, lwidth(medthick)) ///
    (line R2_pcs_cfa  year, lpattern(dot)), ///
    legend(order(1 "Original" 2 "CFA") rows(1)) ///
    title("Explained Variance over Time – PCS") ///
    ytitle("R-squared") ///
    xtitle("Year")
    
	graph export "$output/pcs_R2.png", replace
	
	list year R2_pcs_orig  R2_pcs_cfa, clean 

* Rel Gini MCS over time 
twoway ///
    (line GiniRel_mcs_orig year, lwidth(medthick)) ///
    (line GiniRel_mcs_cfa  year, lpattern(dot)), ///
    legend(order(1 "Original" 2  "CFA") rows(1)) ///
    title("Relative Inequality of Opportunity – MCS") ///
    ytitle("Relative Gini") ///
    xtitle("Year")
	
	graph export "$output/mcs_gini_relative.png", replace
	list year GiniRel_mcs_orig GiniRel_mcs_cfa, clean 
	
* Rel Gini PCS over time 
 twoway ///
    (line GiniRel_pcs_orig year, lwidth(medthick)) ///
    (line GiniRel_pcs_cfa  year, lpattern(dot)), ///
    legend(order(1 "Original" 2 "CFA") rows(1)) ///
    title("Relative Inequality of Opportunity – PCS") ///
    ytitle("Relative Gini") ///
    xtitle("Year")
    
	graph export "$output/pcs_gini_relative.png", replace
	list year GiniRel_pcs_orig GiniRel_pcs_cfa, clean 


