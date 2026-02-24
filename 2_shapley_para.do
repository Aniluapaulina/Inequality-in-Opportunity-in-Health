********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 23.02.2025											
***    Do-file: 1_cleaning
***	   Description: Shapley decomposition for parametric analysis 		                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************
* Goal: Ascribing covariate contributions to a regression's R2

clear all
use $output/base_withbw.dta, clear 

*------------------------------------------------------------------------------
* cross section
*------------------------------------------------------------------------------
keep if syear == 2020
	reg mcs i.yearofbirth i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [aw=w]
	
	* Das sind 12 Variablenblöcke --> dauert etwas
	shapowen i.yearofbirth i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban, scalar(e(r2)) : regress pcs @ [aw=w] 
	
	matrix list r(relShapOw)
	matrix list r(ShapOw)
	
	* Nested structures 
	shapowen (i.yearofbirth i.migback gender) (siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent) (i.birthregion i.urban), scalar(e(r2)) : regress pcs @ [aw=w] 
	

*------------------------------------------------------------------------------
* panel 
*------------------------------------------------------------------------------
clear all
use $output/base_withbw.dta, clear 

tempfile shapley_results
tempname memhold

postfile `memhold' ///
    year str3 healthoutcome ///
    shap_yearofbirth ///
    shap_migback ///
    shap_gender ///
    shap_siblings ///
    shap_msedu ///
    shap_fsedu ///
    shap_fprofstat ///
    shap_mprofstat ///
    shap_singleparent ///
    shap_otherparent ///
    shap_birthregion ///
    shap_urban ///
    using `shapley_results'
	

foreach outcome in pcs mcs {
	forvalues yr = 2002(2)2004 {

    preserve
    keep if syear == `yr'

    shapowen i.yearofbirth i.migback gender siblings i.msedu i.fsedu ///
	i.fprofstat i.mprofstat singleparent otherparent ///
    i.birthregion i.urban, scalar(e(r2)) : ///
    regress `outcome' @ [aw=w]

    matrix M = r(relShapOw)
	
    scalar s1  = M[2,1]
    scalar s2  = M[3,1]
    scalar s3  = M[4,1]
    scalar s4  = M[5,1]
    scalar s5  = M[6,1]
    scalar s6  = M[7,1]
    scalar s7  = M[8,1]
    scalar s8  = M[9,1]
    scalar s9  = M[10,1]
    scalar s10 = M[11,1]
    scalar s11 = M[12,1]
    scalar s12 = M[13,1]

    post `memhold' ///
        (`yr') ("`outcome'") ///
        (s1) (s2) (s3) (s4) (s5) (s6) ///
        (s7) (s8) (s9) (s10) (s11) (s12)

    restore
	}	
}

postclose `memhold'

use `shapley_results', clear
save "$output/shapley_para.dta", replace


*------------------------------------------------------------------------------
* graphs
*------------------------------------------------------------------------------
use "$output/shapley_para.dta", clear 

* Balken / Jahr 
levelsof year, local(years)

foreach outcome in pcs mcs {
	foreach y of local years {
		graph bar ///
			shap_yearofbirth shap_migback shap_gender shap_siblings ///
			shap_msedu shap_fsedu shap_fprofstat shap_mprofstat ///
			shap_singleparent shap_otherparent shap_birthregion shap_urban ///
			if year == `y' & healthoutcome == "`outcome'", ///
			title("Shapley decomposition PCS - `y'") ///
			ytitle("Relative contribution") ///
			legend(off) ///
			name(bar_`y', replace)
			
		graph export "$output/shapley_para_`y'_`outcome'.png", replace 
	}
}


* gestapelte Balken über alle Jahre
graph bar (asis) ///
    shap_yearofbirth shap_migback shap_gender shap_siblings ///
    shap_msedu shap_fsedu shap_fprofstat shap_mprofstat ///
    shap_singleparent shap_otherparent shap_birthregion shap_urban ///
    if healthoutcome=="pcs", ///
    over(year) ///
    stack ///
    title("Shapley decomposition PCS – all years") ///
    ytitle("% contribution of circumstances to IOp") ///
    legend(cols(2))

graph hbar (asis) ///
    shap_yearofbirth shap_migback shap_gender shap_siblings ///
    shap_msedu shap_fsedu shap_fprofstat shap_mprofstat ///
    shap_singleparent shap_otherparent shap_birthregion shap_urban ///
    if healthoutcome=="pcs", ///
    over(year, sort(year)) ///
    stack ///
    outergap(50) ///
	bar(1, color(gs14)) ///
    bar(2, color(orange)) ///
    bar(3, color(blue)) ///
    bar(4, color(green)) ///
    bar(5, color(red)) ///
    bar(6, color(purple)) ///
    bar(7, color(teal)) ///
    bar(8, color(yellow)) ///
    bar(9, color(pink)) ///
    bar(10, color(brown)) ///
    bar(11, color(navy)) ///
    bar(12, color(maroon)) ///
    title("Shapley decomposition PCS – all years") ///
    legend(cols(2))
	
	