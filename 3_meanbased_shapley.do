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
* graphs baseline 
*------------------------------------------------------------------------------
*use "$output/shapley_para.dta", clear 
use "$output/shapley_para_new.dta", clear 
	// die outcome-Spalte wurde falsch beschriftet. Zweimal MCS und PCS jeweils anstatt mit _cfa50
	replace healthoutcome = "pcs_cfa50" if _n > 22 & _n <= 33
	replace healthoutcome = "mcs_cfa50" if _n > 33


*** Shapley Decomposition - gestapelt Balken über alle Jahre --> Anteile am absolute Iop
foreach var in /* pcs mcs */ pcs_cfa50 mcs_cfa50 {
	
	graph bar /* hbar */ (asis) ///
    shap_* ///
    if healthoutcome=="`var'", ///
    over(year) ///
    stack ///
	/// YOB: Grau
    bar(1,  color("150 150 150")) ///
    /// Demographic: Blautöne (migback, gender, siblings)
    bar(2,  color("55 126 184")) ///
    bar(3,  color("107 174 214")) ///
    bar(4,  color("189 215 231")) ///
    /// SES: Rottöne (msedu, fsedu, fprofstat, mprofstat)
    bar(5,  color("165 0 38"))   ///  dunkelrot - msedu
    bar(6,  color("215 48 39"))  ///  rot - fsedu
    bar(7,  color("244 109 67")) ///  lachs - fprofstat
    bar(8,  color("253 190 152")) /// helllachs - mprofstat
    /// Family structure: Grüntöne (singleparent, otherparent)
    bar(9,  color("35 139 69")) ///
    bar(10, color("116 196 118")) ///
    /// Geographic: Lilatöne (birthregion, urban)
    bar(11, color("117 107 177")) ///
    bar(12, color("188 189 220")) ///
    title("Shapley decomposition `var', absolute") ///
    ytitle("% contribution to IOp", size(small)) ///
    legend(cols(4) size(small) region(lwidth(none)) ///
	order(1 "yearofbirth" 2 "migback" 3 "gender" 4 "siblings" 5 "msedu" 6 "fsedu" 7 "fprofstat" ///
		  8 "mprofstat" 9 "singleparent" 10 "otherparent" 11 "birthregion" 12 "urban"))
	
	graph export "$output/`var'_mean_shapley_absolute.png", replace
}

	
*** Shapley Decomposition mit gestapelte Balken über alle Jahre --> relative Anteile an 1
foreach var in /* pcs mcs */ pcs_cfa50 mcs_cfa50 {
	
	graph bar /* hbar */ (asis) ///
    relshap_* ///
    if healthoutcome=="`var'", ///
    over(year) ///
    stack ///
	/// YOB: Grau
    bar(1,  color("150 150 150")) ///
    /// Demographic: Blautöne (migback, gender, siblings)
    bar(2,  color("55 126 184")) ///
    bar(3,  color("107 174 214")) ///
    bar(4,  color("189 215 231")) ///
    /// SES: Rottöne (msedu, fsedu, fprofstat, mprofstat)
    bar(5,  color("165 0 38"))   ///  dunkelrot - msedu
    bar(6,  color("215 48 39"))  ///  rot - fsedu
    bar(7,  color("244 109 67")) ///  lachs - fprofstat
    bar(8,  color("253 190 152")) /// helllachs - mprofstat
    /// Family structure: Grüntöne (singleparent, otherparent)
    bar(9,  color("35 139 69")) ///
    bar(10, color("116 196 118")) ///
    /// Geographic: Lilatöne (birthregion, urban)
    bar(11, color("117 107 177")) ///
    bar(12, color("188 189 220")) ///
    title("Shapley decomposition `var', relative") ///
    ytitle("% contribution to IOp", size(small)) ///
    legend(cols(4) size(small) region(lwidth(none)) ///
	order(1 "yearofbirth" 2 "migback" 3 "gender" 4 "siblings" 5 "msedu" 6 "fsedu" 7 "fprofstat" ///
		  8 "mprofstat" 9 "singleparent" 10 "otherparent" 11 "birthregion" 12 "urban"))
	
	graph export "$output/`var'_mean_shapley_relative.png", replace
	
}

	
*------------------------------------------------------------------------------
* graphs mit aggregierten kategorien  
*------------------------------------------------------------------------------
use "$output/shapley_para_new.dta", clear 
	// die outcome-Spalte wurde falsch beschriftet. Zweimal MCS und PCS jeweils anstatt mit _cfa50
	replace healthoutcome = "pcs_cfa50" if _n > 22 & _n <= 33
	replace healthoutcome = "mcs_cfa50" if _n > 33
	
* Kategorien zusammenfassen (Summe der Shapley-Anteile relativ)
gen relshap_cat1_yob         = relshap_yearofbirth
gen relshap_cat2_demographic = relshap_migback + relshap_gender + relshap_siblings
gen relshap_cat3_family      = relshap_singleparent + relshap_otherparent
gen relshap_cat4_ses	     = relshap_msedu + relshap_fsedu + relshap_fprofstat + relshap_mprofstat
gen relshap_cat5_geo         = relshap_birthregion + relshap_urban

* Kategorien zusammenfassen (Summe der Shapley-Anteile absolut)
gen shap_cat1_yob         = shap_yearofbirth
gen shap_cat2_demographic = shap_migback + shap_gender + shap_siblings
gen shap_cat3_family      = shap_singleparent + shap_otherparent
gen shap_cat4_ses	     = shap_msedu + shap_fsedu + shap_fprofstat + shap_mprofstat
gen shap_cat5_geo         = shap_birthregion + shap_urban


* absolute
foreach var in /* pcs mcs */ pcs_cfa50 mcs_cfa50 {
    graph bar (asis) ///
        shap_cat1_yob shap_cat2_demographic shap_cat3_family ///
        shap_cat4_ses shap_cat5_geo ///
        if healthoutcome == "`var'", ///
        over(year) ///
        stack ///
        bar(1, color("150 150 150")) ///  Grau (YOB)
        bar(2, color("55 126 184"))  ///  Blau (Demographic)
        bar(3, color("35 139 69"))   ///  Grün (Family)
        bar(4, color("165 0 38"))    ///  Rot (SES)
        bar(5, color("117 107 177")) ///  Lila (Geographic)
        title("Shapley decomposition `var', absolute") ///
        ytitle("% contribution to IOp", size(small)) ///
        legend(cols(3) size(small) region(lwidth(none)) ///
            order(1 "Year of birth" 2 "Other demographic" 3 "Family structure" ///
                  4 "SES" 5 "Geographic origin"))
    graph export "$output/`var'_mean_shapley_absolute_cat.png", replace
}
	

* relative
foreach var in /* pcs mcs */ pcs_cfa50 mcs_cfa50 {
    graph bar (asis) ///
        relshap_cat1_yob relshap_cat2_demographic relshap_cat3_family ///
        relshap_cat4_ses relshap_cat5_geo ///
        if healthoutcome == "`var'", ///
        over(year) ///
        stack ///
         bar(1, color("150 150 150")) ///  Grau (YOB)
        bar(2, color("55 126 184"))  ///  Blau (Demographic)
        bar(3, color("35 139 69"))   ///  Grün (Family)
        bar(4, color("165 0 38"))    ///  Rot (SES)
        bar(5, color("117 107 177")) ///  Lila (Geographic)
        title("Shapley decomposition `var', relative") ///
        ytitle("% contribution to IOp", size(small)) ///
        legend(cols(3) size(small) region(lwidth(none)) ///
            order(1 "Year of birth" 2 "Other demographic" 3 "Family structure" ///
                  4 "SES" 5 "Geographic origin"))
    graph export "$output/`var'_mean_shapley_relative_cat.png", replace
}
	



*------------------------------------------------------------------------------
* tabellen mit aggregierten kategorien  
*-----------------------------------------------------------------------------
foreach var in /* pcs mcs */ pcs_cfa50 mcs_cfa50 {
    di "=== `var' ==="
    tabstat  relshap_cat1_yob relshap_cat2_demographic relshap_cat3_family relshap_cat4_ses relshap_cat5_geo ///
            if healthoutcome == "`var'", ///
            by(year) format(%6.3f)
}
		
*** für latex 
foreach var in pcs_cfa50 mcs_cfa50 {
    preserve
    keep if healthoutcome == "`var'"
    keep year relshap_cat1_yob relshap_cat2_demographic relshap_cat3_family ///
             relshap_cat4_ses relshap_cat5_geo

    foreach v of varlist relshap_cat* {
        replace `v' = round(`v' * 100, 0.1)
    }

	* Header schreiben
    file open fh using "$output/table_`var'.tex", write replace
    file write fh "\begin{tabular}{lrrrrr}" _n
    file write fh "\hline" _n
    file write fh "\textbf{Year} & \textbf{YOB} & \textbf{Demographic} & \textbf{Family} & \textbf{SES} & \textbf{Geographic} \\" _n
    file write fh "\hline" _n

    * Zeilen schreiben
    forvalues i = 1/`=_N' {
        file write fh ///
            (year[`i']) " & " ///
            (relshap_cat1_yob[`i']) " & " ///
            (relshap_cat2_demographic[`i']) " & " ///
            (relshap_cat3_family[`i']) " & " ///
            (relshap_cat4_ses[`i']) " & " ///
            (relshap_cat5_geo[`i']) " \\" _n
    }

    file write fh "\hline" _n
    file write fh "\end{tabular}" _n
    file close fh

    restore
}
	
	
	
	