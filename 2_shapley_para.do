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
    shap_yearofbirth relshap_yearofbirth ///
    shap_migback relshap_migback ///
    shap_gender relshap_gender  ///
    shap_siblings relshap_siblings ///
    shap_msedu relshap_msedu ///
    shap_fsedu relshap_fsedu ///
    shap_fprofstat relshap_fprofstat ///
    shap_mprofstat relshap_mprofstat ///
    shap_singleparent relshap_singleparent ///
    shap_otherparent relshap_otherparent ///
    shap_birthregion relshap_birthregion ///
    shap_urban relshap_urban ///
    using `shapley_results'
	

foreach outcome in pcs mcs {
	forvalues yr = 2002(2)2022 {

    preserve
    keep if syear == `yr'

    shapowen i.yearofbirth i.migback gender siblings i.msedu i.fsedu ///
	i.fprofstat i.mprofstat singleparent otherparent ///
    i.birthregion i.urban, scalar(e(r2)) : ///
    regress `outcome' @ [aw=w]
	
	// absolute Shapley value
    matrix M = r(ShapOw)
	
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
	
	// relative Shapley value
	matrix M = r(relShapOw)
	
    scalar a1  = M[2,1]
    scalar a2  = M[3,1]
    scalar a3  = M[4,1]
    scalar a4  = M[5,1]
    scalar a5  = M[6,1]
    scalar a6  = M[7,1]
    scalar a7  = M[8,1]
    scalar a8  = M[9,1]
    scalar a9  = M[10,1]
    scalar a10 = M[11,1]
    scalar a11 = M[12,1]
    scalar a12 = M[13,1]

    post `memhold' ///
        (`yr') ("`outcome'") ///
        (s1) (a1) (s2) (a2) (s3) (a3) ///
        (s4) (a4) (s5) (a5) (s6) (a6) ///
		(s7) (a7) (s8) (a8) (s9) (a9) ///
		(s10) (a10) (s11) (a11) (s12) (a12)

    restore
	}	
}

postclose `memhold'

use `shapley_results', clear
save "$output/shapley_para_new.dta", replace












*------------------------------------------------------------------------------
* graphs
*------------------------------------------------------------------------------
use "$output/shapley_para.dta", clear 

/* Balken / Jahr 
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
*/

*** Shapley Decomposition nur Anteile - Gestapelte Balken über alle Jahre
graph bar (asis) ///
    shap* ///
    if healthoutcome=="pcs", ///
    over(year) ///
    stack ///
	bar(1, color(gs14)) bar(2, color(orange)) bar(3, color(blue)) bar(4, color(green)) bar(5, color(red)) bar(6, color(purple)) ///
	bar(7, color(teal)) bar(8, color(yellow)) bar(9, color(pink)) bar(10, color(brown)) bar(11, color(navy)) bar(12, color(maroon)) ///
    title("Shapley decomposition PCS – all years") ///
    ytitle("% contribution of circumstances to IOp") ///
    legend(cols(2))

graph hbar (asis) ///
    shap* ///
    if healthoutcome=="pcs", ///
    over(year, sort(year)) ///
    stack ///
    outergap(50) ///
	bar(1, color(gs14)) bar(2, color(orange)) bar(3, color(blue)) bar(4, color(green)) bar(5, color(red)) bar(6, color(purple)) ///
	bar(7, color(teal)) bar(8, color(yellow)) bar(9, color(pink)) bar(10, color(brown)) bar(11, color(navy)) bar(12, color(maroon)) ///
    title("Shapley decomposition PCS – all years") ///
    legend(cols(2))
	

*** Shapley Decomposition mit absoluten IOps- Gestapelte Balken über alle Jahre
use "$output/shapley_para.dta", clear 

	merge 1:1 year healthoutcome using "$output/para_pt_IOp_timeseries.dta", nogen // IOp Punktschätzer 
	
	gen pt_R2_100 = pt_R2_ * 100
	
	gen shap_yearofbirth_share = shap_yearofbirth * pt_R2_100
	gen shap_migback_share = shap_migback * pt_R2_100
	gen shap_gender_share = shap_gender * pt_R2_100
	gen shap_siblings_share = shap_siblings * pt_R2_100
    gen shap_msedu_share = shap_msedu * pt_R2_100
    gen shap_fsedu_share = shap_fsedu * pt_R2_100
    gen shap_fprofstat_share = shap_fprofstat * pt_R2_100
    gen shap_mprofstat_share = shap_mprofstat * pt_R2_100
    gen shap_singleparent_share = shap_singleparent * pt_R2_100
    gen shap_otherparent_share = shap_otherparent * pt_R2_100
    gen shap_birthregion_share = shap_birthregion * pt_R2_100
    gen shap_urban_share = shap_urban * pt_R2_100
	

graph bar (asis) ///
    shap*_share ///
    if healthoutcome=="pcs", ///
    over(year) ///
    stack ///
	bar(1, color(gs14)) bar(2, color(orange)) bar(3, color(blue)) bar(4, color(green)) bar(5, color(red)) bar(6, color(purple)) ///
	bar(7, color(teal)) bar(8, color(yellow)) bar(9, color(pink)) bar(10, color(brown)) bar(11, color(navy)) bar(12, color(maroon)) ///
    title("Shapley decomposition PCS – all years") ///
    ytitle("% contribution of circumstances to IOp") ///
    legend(cols(2))
	
	
	
	
	
	
	
	
	