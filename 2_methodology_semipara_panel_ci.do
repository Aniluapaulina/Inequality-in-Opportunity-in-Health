********************************************************************************
***    RIF-Regression Panel Analysis mit Bootstrap-CI
********************************************************************************

clear all
use $output/base_withbw.dta, clear 

local qlist 10 20 30 40 50 60 70 80 90
local B 100   // bweight_0 bis bweight_10

*------------------------------------------------------------------------------
* MENTAL COMPONENT SCALE
*------------------------------------------------------------------------------
tempfile results_rif_mcs
postfile pf_mcs ///
    year quantile boot_b R2_mcs_orig ///
    using `results_rif_mcs', replace

forvalues yr = 2002(2)2022 {
    preserve
    keep if syear == `yr'

    forvalues b = 0/`B' {
        local curweight bweight_`b'

        foreach q of local qlist {
            * RIF für Quantil q – Gewicht variiert mit Bootstrap
            capture drop rif_mcs_q`q'
            egen rif_mcs_q`q' = rifvar(mcs), q(`q') weight(`curweight')
            
            reg rif_mcs_q`q' ///
                i.yearofbirth  i.migback gender siblings ///
                i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
                otherparent i.birthregion i.urban [pw=`curweight']
            local R2 = e(r2)
            
            post pf_mcs (`yr') (`q') (`b') (`R2')
            drop rif_mcs_q`q'
        }
    }
    restore
}
postclose pf_mcs

*------------------------------------------------------------------------------
* PHYSICAL COMPONENT SCALE
*------------------------------------------------------------------------------
tempfile results_rif_pcs
postfile pf_pcs ///
    year quantile boot_b R2_pcs_orig ///
    using `results_rif_pcs', replace

forvalues yr = 2002(2)2022 {
    preserve
    keep if syear == `yr'

    forvalues b = 0/`B' {
        local curweight bweight_`b'

        foreach q of local qlist {
            capture drop rif_pcs_q`q'
            egen rif_pcs_q`q' = rifvar(pcs), q(`q') weight(`curweight')
            
            reg rif_pcs_q`q' ///
                i.yearofbirth  i.migback gender siblings ///
                i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
                otherparent i.birthregion i.urban [pw=`curweight']
            local R2 = e(r2)
            
            post pf_pcs (`yr') (`q') (`b') (`R2')
            drop rif_pcs_q`q'
        }
    }
    restore
}
postclose pf_pcs

*------------------------------------------------------------------------------
* Rohdaten zusammenführen
*------------------------------------------------------------------------------
use `results_rif_mcs', clear
sort year quantile boot_b
merge 1:1 year quantile boot_b using `results_rif_pcs', nogen
save "$output/semipara_IOp_timeseries_raw.dta", replace

*------------------------------------------------------------------------------
* CI berechnen: Punktschätzer (b=0) + Perzentile aus b=1..10
*------------------------------------------------------------------------------

* Punktschätzer
preserve
    keep if boot_b == 0
    keep year quantile R2_mcs_orig R2_pcs_orig
    rename R2_mcs_orig pt_R2_mcs_orig
    rename R2_pcs_orig pt_R2_pcs_orig
    tempfile point_est
    save `point_est'
restore

* CI
keep if boot_b >= 1

foreach v in R2_mcs_orig R2_pcs_orig {
    egen ci_lo_`v' = pctile(`v'), p(2.5)  by(year quantile)
    egen ci_hi_`v' = pctile(`v'), p(97.5) by(year quantile)
}

keep year quantile ci_lo_* ci_hi_*
duplicates drop year quantile, force
sort year quantile

merge 1:1 year quantile using `point_est', nogen
sort year quantile
save "$output/semipara_IOp_timeseries.dta", replace

*------------------------------------------------------------------------------
* Grafiken: Kurve über Jahre pro Quantil (mit CI-Band)
*------------------------------------------------------------------------------
use "$output/semipara_IOp_timeseries.dta", clear


local qlist 10 20 30 40 50 60 70 80 90
foreach q of local qlist {
    twoway ///
        (rcap ci_hi_R2_mcs_orig ci_lo_R2_mcs_orig year ///
            if quantile == `q', lcolor(navy%50)) ///
        (rcap ci_hi_R2_pcs_orig ci_lo_R2_pcs_orig year ///
            if quantile == `q', lcolor(maroon%50)) ///
        (line pt_R2_mcs_orig year ///
            if quantile == `q', lwidth(medthick) lcolor(navy)) ///
        (line pt_R2_pcs_orig year ///
            if quantile == `q', lpattern(dot) lcolor(maroon)), ///
        legend(order(3 "MCS" 4 "PCS") rows(1)) ///
        title("Explained Variance over Time, quantile = `q'") ///
        ytitle("R-squared") xtitle("Year")
    graph export "$output/R2_`q'.png", replace
    list year pt_R2_mcs_orig pt_R2_pcs_orig if quantile == `q', clean
}

*------------------------------------------------------------------------------
* Grafiken: Kurve über Quantile pro Jahr (mit CI-Band)
*------------------------------------------------------------------------------
forvalues yr = 2002(2)2022 {
    twoway ///
        (rcap ci_hi_R2_mcs_orig ci_lo_R2_mcs_orig quantile ///
            if year == `yr', lcolor(navy%50)) ///
        (rcap ci_hi_R2_pcs_orig ci_lo_R2_pcs_orig quantile ///
            if year == `yr', lcolor(maroon%50)) ///
        (line pt_R2_mcs_orig quantile ///
            if year == `yr', lwidth(medthick) lcolor(navy)) ///
        (line pt_R2_pcs_orig quantile ///
            if year == `yr', lpattern(dot) lcolor(maroon)), ///
        legend(order(3 "MCS" 4 "PCS") rows(1)) ///
        title("Explained Variance across Distribution, year = `yr'") ///
        ytitle("R-squared") xtitle("Quantile")
    graph export "$output/R2_`yr'.png", replace
    list quantile pt_R2_mcs_orig pt_R2_pcs_orig if year == `yr', clean
}