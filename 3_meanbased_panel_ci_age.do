********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 3_meanbased_panel_ci_age
***	   Description: Parametric methodology- Panel Analysis mit Bootstrap-CI		                                     	
***    Project: "IOP in health in Germany" 
********************************************************************************

clear all
use $output/final.dta, clear 
tab syear

* Tempfile für Haupresultate 
tempfile results
postfile pf ///
    year boot_b ///
	IOP_mcs_orig IOP_mcs_cfa ///
	IOP_pcs_orig IOP_pcs_cfa ///
    R2_mcs_orig R2_mcs_cfa /// 	
	R2_pcs_orig R2_pcs_cfa ///	
	GiniAbs_mcs_cfa GiniRel_mcs_cfa /// 
	GiniAbs_pcs_cfa GiniRel_pcs_cfa  /// 
	var_mcs var_mcs_cfa ///
	var_pcs var_pcs_cfa ///
    using `results', replace

	local B 10
	
*------------------------------------------------------------------------------
* Doppelter Loop: Jahre (äußer) × Bootstrap-Gewichte (innen)
*------------------------------------------------------------------------------
forvalues yr = 2002(2)2022 {
    preserve
    keep if syear == `yr'

    forvalues b = 0/`B' {
		
	local curweight bweight_`b'
	
	* Gesamtvarianz
	qui sum mcs [aw=`curweight']
	local var_mcs = r(Var)

	qui sum mcs_cfa50 [aw=`curweight']
	local var_mcs_cfa = r(Var)

	qui sum pcs [aw=`curweight']
	local var_pcs = r(Var)

	qui sum pcs_cfa50 [aw=`curweight']
	local var_pcs_cfa = r(Var)
		
        *----------------------------------------------------------------------
        * MENTAL COMPONENT SCALE – Original SOEP Gewichtung
        *----------------------------------------------------------------------
		 reg mcs c.age c.age#c.age i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [aw=`curweight']
       
	   * relative IOp
        local R2_mcs_orig = e(r2)
		
	   * absolute IOp
		capture drop mcs_hat
		predict mcs_hat, xb
		quietly summarize mcs_hat [aw=`curweight']  
		local IOP_mcs_orig = r(Var)

        /*capture drop mcs_orig_hat
        predict mcs_orig_hat, xb
        ineqdeco mcs_orig_hat
        local GiniAbs_mcs_orig = $S_gini
        ineqdeco mcs
        local Gobs_mcs = $S_gini
        local GiniRel_mcs_orig = `GiniAbs_mcs_orig' / `Gobs_mcs' */

        *----------------------------------------------------------------------
        * MENTAL COMPONENT SCALE – CFA
        *----------------------------------------------------------------------
        /* reg mcs_cfa50 i.yearofbirth i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [aw=`curweight'] */ 
		
		 reg mcs_cfa50 c.age c.age#c.age i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [aw=`curweight']
		
		* relative IOp
        local R2_mcs_cfa = e(r2)
		
		* absolute IOp
		capture drop mcs_cfa_hat
		predict mcs_cfa_hat , xb
		quietly summarize mcs_cfa_hat [aw=`curweight']  
		local IOP_mcs_cfa = r(Var)

        ineqdeco mcs_cfa_hat [aw=`curweight']
        local GiniAbs_mcs_cfa = $S_gini
        ineqdeco mcs_cfa50 [aw=`curweight']
        local Gobs_mcs = $S_gini
        local GiniRel_mcs_cfa = `GiniAbs_mcs_cfa' / `Gobs_mcs' 

        *----------------------------------------------------------------------
        * PHYSICAL COMPONENT SCALE – Original SOEP Gewichtung
        *----------------------------------------------------------------------
       reg pcs c.age c.age#c.age i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [aw=`curweight']
		
		* relative IOp
        local R2_pcs_orig = e(r2)

		* absolute IOp
		capture drop pcs_hat
		predict pcs_hat, xb
		quietly summarize pcs_hat [aw=`curweight']  
		local IOP_pcs_orig = r(Var)


        /* capture drop pcs_orig_hat
        predict pcs_orig_hat, xb
        ineqdeco pcs_orig_hat
        local GiniAbs_pcs_orig = $S_gini
        ineqdeco pcs
        local Gobs_pcs = $S_gini
        local GiniRel_pcs_orig = `GiniAbs_pcs_orig' / `Gobs_pcs' */
		
        *----------------------------------------------------------------------
        * PHYSICAL COMPONENT SCALE – CFA
        *----------------------------------------------------------------------
       reg pcs_cfa50 c.age c.age#c.age i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [aw=`curweight']
		
		* relative IOp
        local R2_pcs_cfa = e(r2)
		
		* absolute IOp
		capture drop pcs_cfa_hat
		predict pcs_cfa_hat, xb
		quietly summarize pcs_cfa_hat [aw=`curweight']  
		local IOP_pcs_cfa = r(Var)

        ineqdeco pcs_cfa_hat [aw=`curweight']
        local GiniAbs_pcs_cfa = $S_gini
        ineqdeco pcs_cfa50 [aw=`curweight']
        local Gobs_pcs = $S_gini
        local GiniRel_pcs_cfa = `GiniAbs_pcs_cfa' / `Gobs_pcs' 

        * Ergebnisse posten
       post pf ///
			(`yr') (`b') ///
			(`IOP_mcs_orig') (`IOP_mcs_cfa') ///
			(`IOP_pcs_orig') (`IOP_pcs_cfa') ///
			(`R2_mcs_orig') (`R2_mcs_cfa') ///
			(`R2_pcs_orig') (`R2_pcs_cfa') ///
			(`GiniAbs_mcs_cfa') (`GiniRel_mcs_cfa') ///
			(`GiniAbs_pcs_cfa') (`GiniRel_pcs_cfa') ///
			(`var_mcs') (`var_mcs_cfa') ///
			(`var_pcs') (`var_pcs_cfa')	
    } 
    restore
} 

postclose pf

*------------------------------------------------------------------------------
* Rohergebnisse laden und speichern
*------------------------------------------------------------------------------
use `results', clear
order year boot_b, first
sort year boot_b

* Konsitenzprüfung
gen R2_check_mcs_cfa = IOP_mcs_cfa / var_mcs_cfa
gen R2_check_pcs_cfa = IOP_pcs_cfa / var_pcs_cfa
br R2_check_pcs_cfa R2_check_mcs_cfa R2_mcs_cfa R2_pcs_cfa 

save "$output/para_IOp_timeseries_raw.dta", replace


*------------------------------------------------------------------------------
* CI berechnen: Perzentile aus Bootstrap-Iterationen (b>=1)
* Punktschätzer aus b=0 (Originalgewicht)
*------------------------------------------------------------------------------
use "$output/para_IOp_timeseries_raw.dta", clear

* local varlist R2_mcs_orig R2_mcs_cfa R2_pcs_orig R2_pcs_cfa
local varlist var_mcs var_mcs_cfa var_pcs var_pcs_cfa ///
              IOP_mcs_orig IOP_mcs_cfa IOP_pcs_orig IOP_pcs_cfa ///
              R2_mcs_orig R2_mcs_cfa R2_pcs_orig R2_pcs_cfa ///
			  GiniAbs_mcs_cfa GiniRel_mcs_cfa GiniAbs_pcs_cfa GiniRel_pcs_cfa
			  
*** Punktschätzer (b=0)
preserve
    keep if boot_b == 0
    keep year `varlist'
    foreach v of local varlist {
        rename `v' pt_`v'
    }
    tempfile point_estimates
    save `point_estimates'
restore

*** CI aus Bootstrap-Iterationen (b=1..B) – SOEP-Methode: SE-basiert
keep if boot_b >= 1

* Punktschätzer dazumergen für Abweichungsberechnung, genauer gesagt um die quadratische Abweichung der Punktschätzer von den anderen bootrapping-estimates zu berechen. aus dieses abweichungen wird dann der mittelwert (mit collapse) berechnet, die damit die varianz der Bootstrap-Iterationen ergibt 
merge m:1 year using `point_estimates', nogen

foreach v of local varlist {
    gen sq_dev_`v' = (`v' - pt_`v')^2
}

collapse (mean) sq_dev_* pt_* , by(year)

foreach v of local varlist {
    gen se_`v'    = sqrt(sq_dev_`v')
   
    gen ci_lo_`v' = pt_`v' - 1.96 * se_`v'
    gen ci_hi_`v' = pt_`v' + 1.96 * se_`v'
    drop sq_dev_`v'
}

* Wert + standard error für latex tabelle später für total variance und absolute iop 
foreach v in var_pcs_cfa var_mcs_cfa IOP_mcs_cfa IOP_pcs_cfa {
    gen out_`v' = ///
        string(pt_`v', "%9.3f") + ///
        " (" + string(se_`v', "%9.3f") + ")"
}

* Wert für latex tabelle später für relative iop 
gen rel_IOP_mcs_cfa = pt_IOP_mcs_cfa/pt_var_mcs_cfa
gen rel_IOP_pcs_cfa = pt_IOP_pcs_cfa/pt_var_pcs_cfa

replace rel_IOP_mcs_cfa = rel_IOP_mcs_cfa*100
replace rel_IOP_pcs_cfa = rel_IOP_pcs_cfa*100

gen out_rel_mcs_cfa = string(rel_IOP_mcs_cfa, "%9.3f")
gen out_rel_pcs_cfa = string(rel_IOP_pcs_cfa, "%9.3f") 


sort year
save "$output/para_IOp_timeseries.dta", replace

/* Vorbereitung für shapley decomposition: year x healthoutcome 
use "$output/para_IOp_timeseries.dta", clear
	reshape long pt_R2_, i(year) j(healthoutcome) string
	replace healthoutcome = "mcs" if healthoutcome == "mcs_orig"
	replace healthoutcome = "pcs" if healthoutcome == "pcs_orig"
save "$output/para_pt_IOp_timeseries.dta", replace
*/

*------------------------------------------------------------------------------
* Grafiken mit CI (mit vertikalen!!!! Linien )
*------------------------------------------------------------------------------
use "$output/para_IOp_timeseries.dta", clear

*  R2 für PCS_CFA und MCS_CFA 
twoway ///
    (rcap ci_hi_R2_mcs_cfa ci_lo_R2_mcs_cfa year, lcolor(navy%50)) ///
    (rcap ci_hi_R2_pcs_cfa  ci_lo_R2_pcs_cfa  year, lcolor(maroon%50)) ///
    (line pt_R2_mcs_cfa year, lpattern(medthick) lcolor(navy)) ///
    (line pt_R2_pcs_cfa  year, lpattern(medthick)    lcolor(maroon)), ///
    legend(order(3 "MCS" 4 "PCS") rows(1)) ///
    title("Explained Variance over Time, e.g., relative IOp") ///
    ytitle("R-squared") xtitle("Year")
graph export "$output/mcs_pcs_R2.png", replace

*  R2 MCS versus MCS_CFA
twoway ///
    (rcap ci_hi_R2_mcs_orig ci_lo_R2_mcs_orig year, lcolor(navy%50)) ///
    (rcap ci_hi_R2_mcs_cfa  ci_lo_R2_mcs_cfa  year, lcolor(maroon%50)) ///
    (line pt_R2_mcs_orig year, lwidth(medthick) lcolor(navy)) ///
    (line pt_R2_mcs_cfa  year, lpattern(medthick)    lcolor(maroon)), ///
    legend(order(3 "Original" 4 "CFA") rows(1)) ///
    title("Explained Variance over Time – MCS") ///
    ytitle("R-squared") xtitle("Year")
graph export "$output/mcs_R2.png", replace


*  R2 PCS versus PCS_CFA
twoway ///
    (rcap ci_hi_R2_pcs_orig ci_lo_R2_pcs_orig year, lcolor(navy%50)) ///
    (rcap ci_hi_R2_pcs_cfa  ci_lo_R2_pcs_cfa  year, lcolor(maroon%50)) ///
    (line pt_R2_pcs_orig year, lwidth(medthick) lcolor(navy)) ///
    (line pt_R2_pcs_cfa  year, lpattern(medthick)    lcolor(maroon)), ///
    legend(order(3 "Original" 4 "CFA") rows(1)) ///
    title("Explained Variance over Time – PCS") ///
    ytitle("R-squared") xtitle("Year")
graph export "$output/pcs_R2.png", replace


*  Relativer Gini PCS_CFA versus MCS_CFA (viel höher !?)
twoway ///
    (rcap ci_hi_GiniRel_mcs_cfa ci_lo_GiniRel_mcs_cfa year, lcolor(navy%50)) ///
    (rcap ci_hi_GiniRel_pcs_cfa  ci_lo_GiniRel_pcs_cfa  year, lcolor(maroon%50)) ///
    (line pt_GiniRel_mcs_cfa year, lwidth(medthick) lcolor(navy)) ///
    (line pt_GiniRel_pcs_cfa  year, lpattern(medthick)    lcolor(maroon)), ///
    legend(order(3 "MCS" 4 "PCS") rows(1)) ///
    title("Relative Gini over Time, e.g., relative IOp") ///
    ytitle("Relative Gini") xtitle("Year")
graph export "$output/pcs_gini_relative.png", replace */


*------------------------------------------------------------------------------
* Tabellenexport für Overleaf nur mit Punktschätzern 
*------------------------------------------------------------------------------
use $output/final.dta, clear 
tab syear

* Tempfile mit Anzahl der Observationen pro Jahr für Tabelle später 
tempfile freq
	preserve
	keep syear	
	rename syear year 
	contract year   
	rename _freq N
	save `freq'
	restore
	
use "$output/para_IOp_timeseries.dta", clear
	merge 1:1 year using `freq', nogen 

tsset year

* für prozentangaben 
replace pt_R2_mcs_cfa = pt_R2_mcs_cfa*100
replace pt_R2_pcs_cfa = pt_R2_pcs_cfa*100

preserve

* Runden
foreach v of varlist pt_R2_* {
    replace `v' = round(`v', 0.01)
}

* Datei öffnen
file open fh using "$output/Tables/table_meanbased_IOp.tex", write replace

* Header
file write fh "\begin{tabular}{lcccc}" _n
file write fh "\hline" _n
file write fh "\textbf{Year} & \textbf{MCS} & \textbf{PCS} & \textbf{Sample size} \\" _n
file write fh "\hline" _n

* Zeilen schreiben
forvalues i = 1/`=_N' {
    file write fh ///
        (year[`i']) " & " ///
		(pt_R2_mcs_cfa[`i']) " & " ///
		(pt_R2_pcs_cfa[`i']) " & " ///
        (N[`i']) " \\" _n
}

* Footer
file write fh "\hline" _n
file write fh "\end{tabular}" _n
file close fh

restore
		

*--------------------------------------------------------------------------------------------
* Tabellenexport für Overleaf mit absolute and relative IOp, sd und Fußnote 
* für MCS 
*--------------------------------------------------------------------------------------------
use "$output/para_IOp_timeseries.dta", clear

* N (Fallzahlen) erzeugen und mergen
preserve
    use "$output/final.dta", clear
    keep syear
    rename syear year
    contract year
    rename _freq N
    tempfile freq
    save `freq'
restore

merge 1:1 year using `freq', nogen
sort year

preserve

* Datei öffnen
file open fh using "$output/Tables/table_IOP_MCS_age.tex", write replace

file write fh "\begin{tabular}{lcccc}" _n
file write fh "\hline" _n
file write fh "\textbf{Year} & \textbf{Total inequality} & \textbf{Absolute IOp} & \textbf{Relative IOp} & \textbf{N} \\" _n
file write fh "\hline" _n

forvalues i = 1/`=_N' {
    file write fh ///
        (year[`i']) " & " ///
        (out_var_mcs_cfa[`i']) " & " ///
        (out_IOP_mcs_cfa[`i']) " & " ///
        (out_rel_mcs_cfa[`i']) " & " ///
        (N[`i']) " \\" _n
}

file write fh "\hline" _n
file write fh "\multicolumn{5}{l}{\footnotesize{Bootstrapped standard errors in parentheses (B=100).}}" _n
file write fh "\end{tabular}" _n

file close fh
restore 

*--------------------------------------------------------------------------------------------
* Tabellenexport für Overleaf mit absolute and relative IOp, sd und Fußnote 
* für PCS 
*--------------------------------------------------------------------------------------------
use "$output/para_IOp_timeseries.dta", clear

* N (Fallzahlen) erzeugen und mergen
preserve
    use "$output/final.dta", clear
    keep syear
    rename syear year
    contract year
    rename _freq N
    tempfile freq
    save `freq'
restore

merge 1:1 year using `freq', nogen
sort year

preserve

* Datei öffnen
file open fh using "$output/Tables/table_IOP_PCS_age.tex", write replace

file write fh "\begin{tabular}{lcccc}" _n
file write fh "\hline" _n
file write fh "\textbf{Year} & \textbf{Total inequality} & \textbf{Absolute IOp} & \textbf{Relative IOp} & \textbf{N} \\" _n
file write fh "\hline" _n

forvalues i = 1/`=_N' {
    file write fh ///
        (year[`i']) " & " ///
        (out_var_pcs_cfa[`i']) " & " ///
        (out_IOP_pcs_cfa[`i']) " & " ///
        (out_rel_pcs_cfa[`i']) " & " ///
        (N[`i']) " \\" _n
}

file write fh "\hline" _n
file write fh "\multicolumn{5}{l}{\footnotesize{Bootstrapped standard errors in parentheses (B=100).}}" _n
file write fh "\end{tabular}" _n

file close fh
	
	
	
	
	
	