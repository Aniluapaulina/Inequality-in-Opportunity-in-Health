********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 2_methodolody_para
***	   Description: Parametric methodology- Panel Analysis mit Bootstrap-CI		                                     	
***    Project: "IOP in health in Germany" 
********************************************************************************

clear all
use $output/base_withbw.dta, clear 
tab syear

*------------------------------------------------------------------------------
* Tempfile speichert alle Ergebnisse: (B+1) Iterationen × 11 Jahre
* boot_b=0 → Originalgewicht (bweight0), boot_b=1..10 → Bootstrap-Gewichte
*------------------------------------------------------------------------------
tempfile results
postfile pf ///
    year boot_b ///
    R2_mcs_orig R2_mcs_cfa /// 	/* GiniAbs_mcs_orig GiniRel_mcs_orig GiniAbs_mcs_cfa GiniRel_mcs_cfa /// */
    R2_pcs_orig R2_pcs_cfa ///	/* GiniAbs_pcs_orig GiniRel_pcs_orig GiniAbs_pcs_cfa GiniRel_pcs_cfa  /// */ 
    using `results', replace

	local B 100
	
*------------------------------------------------------------------------------
* Doppelter Loop: Jahre (äußer) × Bootstrap-Gewichte (innen)
*------------------------------------------------------------------------------
forvalues yr = 2002(2)2022 {
    preserve
    keep if syear == `yr'

    forvalues b = 0/`B' {

	local curweight bweight_`b'
		
        *----------------------------------------------------------------------
        * MENTAL COMPONENT SCALE – Original SOEP Gewichtung
        *----------------------------------------------------------------------
        reg mcs i.yearofbirth i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [fw=`curweight']
        local R2_mcs_orig = e(r2)

        /* capture drop mcs_orig_hat
        predict mcs_orig_hat, xb
        ineqdeco mcs_orig_hat
        local GiniAbs_mcs_orig = $S_gini
        ineqdeco mcs
        local Gobs_mcs = $S_gini
        local GiniRel_mcs_orig = `GiniAbs_mcs_orig' / `Gobs_mcs' */

        *----------------------------------------------------------------------
        * MENTAL COMPONENT SCALE – CFA
        *----------------------------------------------------------------------
        reg mcs_cfa50 i.yearofbirth i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [fw=`curweight']
        local R2_mcs_cfa = e(r2)

        /* capture drop mcs_cfa50_hat
        predict mcs_cfa50_hat, xb
        ineqdeco mcs_cfa50_hat
        local GiniAbs_mcs_cfa = $S_gini
        ineqdeco mcs_cfa50
        local Gobs_mcs = $S_gini
        local GiniRel_mcs_cfa = `GiniAbs_mcs_cfa' / `Gobs_mcs' */

        *----------------------------------------------------------------------
        * PHYSICAL COMPONENT SCALE – Original SOEP Gewichtung
        *----------------------------------------------------------------------
        reg pcs i.yearofbirth  i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [fw=`curweight']
        local R2_pcs_orig = e(r2)

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
        reg pcs_cfa50 i.yearofbirth  i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [fw=`curweight']
        local R2_pcs_cfa = e(r2)

        /* capture drop pcs_cfa50_hat
        predict pcs_cfa50_hat, xb
        ineqdeco pcs_cfa50_hat
        local GiniAbs_pcs_cfa = $S_gini
        ineqdeco pcs_cfa50
        local Gobs_pcs = $S_gini
        local GiniRel_pcs_cfa = `GiniAbs_pcs_cfa' / `Gobs_pcs' */

        * Ergebnis posten
        post pf ///
            (`yr') (`b') ///
            (`R2_mcs_orig') (`R2_mcs_cfa') /// /* (`GiniAbs_mcs_orig') (`GiniRel_mcs_orig') /// (`GiniAbs_mcs_cfa') (`GiniRel_mcs_cfa') /// */
            (`R2_pcs_orig') (`R2_pcs_cfa') /* /// (`GiniAbs_pcs_orig') (`GiniRel_pcs_orig') /// (`GiniAbs_pcs_cfa') (`GiniRel_pcs_cfa') */
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
save "$output/para_IOp_timeseries_raw.dta", replace

*------------------------------------------------------------------------------
* CI berechnen: Perzentile aus Bootstrap-Iterationen (b>=1)
* Punktschätzer aus b=0 (Originalgewicht)
*------------------------------------------------------------------------------

/* use "$output/para_IOp_timeseries_raw.dta", clear 
* Zielvariablen definieren
local varlist R2_mcs_orig R2_mcs_cfa /// /* GiniAbs_mcs_orig GiniRel_mcs_orig /// GiniAbs_mcs_cfa  GiniRel_mcs_cfa  /// */
              R2_pcs_orig R2_pcs_cfa /// /* GiniAbs_pcs_orig GiniRel_pcs_orig /// GiniAbs_pcs_cfa  GiniRel_pcs_cfa */

*  Punktschätzer (b=0) 
preserve
    keep if boot_b == 0
    keep year `varlist'
    foreach v of local varlist {
        rename `v' pt_`v'
    }
    tempfile point_estimates
    save `point_estimates'
restore

	 *use `point_estimates' , clear 
	
	
* CI aus Bootstrap-Iterationen 

 keep if boot_b >= 1

/*
foreach v of local varlist {
    egen ci_lo_`v' = pctile(`v'), p(2.5)  by(year)
    egen ci_hi_`v' = pctile(`v'), p(97.5) by(year)
}
*/

foreach v of local varlist {
    bysort year: egen mean_`v' = mean(`v')
    bysort year: egen sd_`v' = sd(`v')
    gen ci_lo_`v' = mean_`v' - 1.96*sd_`v'
    gen ci_hi_`v' = mean_`v' + 1.96*sd_`v'
	
	
keep year ci_lo_* ci_hi_*
duplicates drop year, force
sort year

* Punktschätzer dazumergen
merge 1:1 year using `point_estimates', nogenerate
sort year
}

save "$output/para_IOp_timeseries.dta", replace

*/
*****************************************************
use "$output/para_IOp_timeseries_raw.dta", clear

local varlist R2_mcs_orig R2_mcs_cfa R2_pcs_orig R2_pcs_cfa

* Punktschätzer (b=0)
preserve
    keep if boot_b == 0
    keep year `varlist'
    foreach v of local varlist {
        rename `v' pt_`v'
    }
    tempfile point_estimates
    save `point_estimates'
restore

* CI aus Bootstrap-Iterationen (b=1..B) – SOEP-Methode: SE-basiert
keep if boot_b >= 1

* Punktschätzer dazumergen für Abweichungsberechnung
merge m:1 year using `point_estimates', nogen

foreach v of local varlist {
    gen sq_dev_`v' = (`v' - pt_`v')^2
}

collapse (mean) sq_dev_* pt_*, by(year)

foreach v of local varlist {
    gen se_`v'    = sqrt(sq_dev_`v')
    gen ci_lo_`v' = pt_`v' - 1.96 * se_`v'
    gen ci_hi_`v' = pt_`v' + 1.96 * se_`v'
    drop sq_dev_`v' se_`v'
}

sort year
save "$output/para_IOp_timeseries.dta", replace

*------------------------------------------------------------------------------
* Grafiken mit CI (mit vertikale!!!! Linien )
*------------------------------------------------------------------------------
use "$output/para_IOp_timeseries.dta", clear

*  R2 MCS 
twoway ///
    (rcap ci_hi_R2_mcs_orig ci_lo_R2_mcs_orig year, lcolor(navy%50)) ///
    (rcap ci_hi_R2_mcs_cfa  ci_lo_R2_mcs_cfa  year, lcolor(maroon%50)) ///
    (line pt_R2_mcs_orig year, lwidth(medthick) lcolor(navy)) ///
    (line pt_R2_mcs_cfa  year, lpattern(dot)    lcolor(maroon)), ///
    legend(order(3 "Original" 4 "CFA") rows(1)) ///
    title("Explained Variance over Time – MCS") ///
    ytitle("R-squared") xtitle("Year")
graph export "$output/mcs_R2.png", replace

*  R2 PCS 
twoway ///
    (rcap ci_hi_R2_pcs_orig ci_lo_R2_pcs_orig year, lcolor(navy%50)) ///
    (rcap ci_hi_R2_pcs_cfa  ci_lo_R2_pcs_cfa  year, lcolor(maroon%50)) ///
    (line pt_R2_pcs_orig year, lwidth(medthick) lcolor(navy)) ///
    (line pt_R2_pcs_cfa  year, lpattern(dot)    lcolor(maroon)), ///
    legend(order(3 "Original" 4 "CFA") rows(1)) ///
    title("Explained Variance over Time – PCS") ///
    ytitle("R-squared") xtitle("Year")
graph export "$output/pcs_R2.png", replace

*  Relativer Gini MCS 
twoway ///
    (rcap ci_hi_GiniRel_mcs_orig ci_lo_GiniRel_mcs_orig year, lcolor(navy%50)) ///
    (rcap ci_hi_GiniRel_mcs_cfa  ci_lo_GiniRel_mcs_cfa  year, lcolor(maroon%50)) ///
    (line pt_GiniRel_mcs_orig year, lwidth(medthick) lcolor(navy)) ///
    (line pt_GiniRel_mcs_cfa  year, lpattern(dot)    lcolor(maroon)), ///
    legend(order(3 "Original" 4 "CFA") rows(1)) ///
    title("Relative Inequality of Opportunity – MCS") ///
    ytitle("Relative Gini") xtitle("Year")
graph export "$output/mcs_gini_relative.png", replace

*  Relativer Gini PCS 
twoway ///
    (rcap ci_hi_GiniRel_pcs_orig ci_lo_GiniRel_pcs_orig year, lcolor(navy%50)) ///
    (rcap ci_hi_GiniRel_pcs_cfa  ci_lo_GiniRel_pcs_cfa  year, lcolor(maroon%50)) ///
    (line pt_GiniRel_pcs_orig year, lwidth(medthick) lcolor(navy)) ///
    (line pt_GiniRel_pcs_cfa  year, lpattern(dot)    lcolor(maroon)), ///
    legend(order(3 "Original" 4 "CFA") rows(1)) ///
    title("Relative Inequality of Opportunity – PCS") ///
    ytitle("Relative Gini") xtitle("Year")
graph export "$output/pcs_gini_relative.png", replace