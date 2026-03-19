********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 23.02.2025											
***    Do-file: 3_meanbased_shapley
***	   Description: Shapley decomposition for semi-parametric analysis 		                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************
* Goal: Ascribing covariate contributions to a regression's R2


clear all
use $output/final.dta, clear 

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
* panel baseline
*------------------------------------------------------------------------------
clear all
use $output/final.dta, clear 

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
	

foreach outcome in pcs mcs pcs_cfa50 mcs_cfa50 {
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
*use "$output/shapley_para.dta", clear 
use "$output/shapley_para_new.dta", clear 
	// die outcome-Spalte wurde falsch beschriftet. Zweimal MCS und PCS jeweils anstatt mit _cfa50
	replace healthoutcome = "pcs_cfa50" if _n > 22 & _n <= 33
	replace healthoutcome = "mcs_cfa50" if _n > 33


*** Shapley Decomposition nur Anteile - Gestapelte Balken über alle Jahre
graph bar /* hbar */ (asis) ///
    shap_* ///
    if healthoutcome=="pcs", ///
    over(year) ///
    stack ///
	bar(1, color(gs14)) bar(2, color(orange)) bar(3, color(blue)) bar(4, color(green)) bar(5, color(red)) bar(6, color(purple)) ///
	bar(7, color(teal)) bar(8, color(yellow)) bar(9, color(pink)) bar(10, color(brown)) bar(11, color(navy)) bar(12, color(maroon)) ///
    title("Shapley decomposition PCS, relative") ///
    ytitle("% contribution to IOp", size(small)) ///
    legend(cols(4) size(small) region(lwidth(none)) ///
	order(1 "yearofbirth" 2 "migback" 3 "gender" 4 "siblings" ///
              5 "msedu" 6 "fsedu" 7 "fprofstat" ///
              8 "mprofstat" 9 "singleparent" 10 "otherparent" ///
              11 "birthregion" 12 "urban"))
	
	graph export "$output/pcs_mean_shapley_absolute.png", replace

	
graph bar /* hbar */ (asis) ///
    shap_* ///
    if healthoutcome=="mcs", ///
    over(year) ///
    stack ///
	bar(1, color(gs14)) bar(2, color(orange)) bar(3, color(blue)) bar(4, color(green)) bar(5, color(red)) bar(6, color(purple)) ///
	bar(7, color(teal)) bar(8, color(yellow)) bar(9, color(pink)) bar(10, color(brown)) bar(11, color(navy)) bar(12, color(maroon)) ///
    title("Shapley decomposition MCS, relative") ///
    ytitle("% contribution to IOp", size(small)) ///
    legend(cols(4) size(small) region(lwidth(none)) ///
	order(1 "yearofbirth" 2 "migback" 3 "gender" 4 "siblings" ///
              5 "msedu" 6 "fsedu" 7 "fprofstat" ///
              8 "mprofstat" 9 "singleparent" 10 "otherparent" ///
              11 "birthregion" 12 "urban"))
	
	graph export "$output/mcs_mean_shapley_absolute.png", replace
	
	
*** Shapley Decomposition mit absoluten IOps- Gestapelte Balken über alle Jahre
graph bar /* hbar */ (asis) ///
    relshap_* ///
    if healthoutcome=="pcs", ///
    over(year) ///
    stack ///
	bar(1, color(gs14)) bar(2, color(orange)) bar(3, color(blue)) bar(4, color(green)) bar(5, color(red)) bar(6, color(purple)) ///
	bar(7, color(teal)) bar(8, color(yellow)) bar(9, color(pink)) bar(10, color(brown)) bar(11, color(navy)) bar(12, color(maroon)) ///
    title("Shapley decomposition PCS, absolute") ///
    ytitle("% contribution to IOp", size(small)) ///
    legend(cols(4) size(small) region(lwidth(none)) ///
	order(1 "yearofbirth" 2 "migback" 3 "gender" 4 "siblings" ///
              5 "msedu" 6 "fsedu" 7 "fprofstat" ///
              8 "mprofstat" 9 "singleparent" 10 "otherparent" ///
              11 "birthregion" 12 "urban"))
	
	graph export "$output/pcs_mean_shapley_relative.png", replace
	
graph bar /* hbar */ (asis) ///
    relshap_* ///
    if healthoutcome=="mcs", ///
    over(year) ///
    stack ///
	bar(1, color(gs14)) bar(2, color(orange)) bar(3, color(blue)) bar(4, color(green)) bar(5, color(red)) bar(6, color(purple)) ///
	bar(7, color(teal)) bar(8, color(yellow)) bar(9, color(pink)) bar(10, color(brown)) bar(11, color(navy)) bar(12, color(maroon)) ///
    title("Shapley decomposition MCS, absolute") ///
    ytitle("% contribution to IOp", size(small)) ///
    legend(cols(4) size(small) region(lwidth(none)) ///
	order(1 "yearofbirth" 2 "migback" 3 "gender" 4 "siblings" ///
              5 "msedu" 6 "fsedu" 7 "fprofstat" ///
              8 "mprofstat" 9 "singleparent" 10 "otherparent" ///
              11 "birthregion" 12 "urban"))
	
	graph export "$output/mcs_mean_shapley_relative.png", replace
	
	
	
	

	
	