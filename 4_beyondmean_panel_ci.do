********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 05.05.2026											
***    Do-file: 4_beyondmean_panel_ci
***	   Description: RIF-Regression Panel Analysis für absolute und relative IOp mit Bootstrap-CI                                 	
***    Project: "IOP in health in Germany" 
********************************************************************************

clear all
use $output/final.dta, clear 

local qlist 10 20 30 40 50 60 70 80 90
local B 10   // bweight_0 bis bweight_10

*------------------------------------------------------------------------------
* MENTAL COMPONENT SCALE
*------------------------------------------------------------------------------
tempfile results_rif_mcs

postfile pf_mcs ///
    year quantile boot_b R2 abs_iop var_rif rel_iop str3 outcome ///
    using `results_rif_mcs', replace

forvalues yr = 2002(2)2022 {
    preserve
    keep if syear == `yr'

    forvalues b = 0/`B' {
        local curweight bweight_`b'

        foreach q of local qlist {
            * RIF für Quantil q – Gewicht variiert mit Bootstrap
            capture drop rif_mcs_q`q'
            egen rif_mcs_q`q' = rifvar(mcs_cfa50), q(`q') weight(`curweight')
		
			reg rif_mcs_q`q' ///
				c.age c.age#c.age  i.migback gender siblings ///
				i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
				otherparent i.birthregion i.urban [aw=`curweight']

			* Relative IOp
			local R2 = e(r2)
			
			* Totale Varianz 
			summarize rif_mcs_q`q' [aw=`curweight']
			local var_rif = r(Var)

			* Absolutes IOp = Var(fitted values)
			capture drop rif_hat
			predict rif_hat, xb
			quietly summarize rif_hat [aw=`curweight']
			local abs_iop = r(Var)
			drop rif_hat
			
			* Relative IOp robustness check
			local rel_iop = `abs_iop' / `var_rif'
	
			post pf_mcs (`yr') (`q') (`b') (`R2') (`abs_iop') (`var_rif') (`rel_iop') ("mcs")
			
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
    year quantile boot_b R2 abs_iop var_rif rel_iop str3  outcome ///
    using `results_rif_pcs', replace

forvalues yr = 2002(2)2022 {
    preserve
    keep if syear == `yr'

    forvalues b = 0/`B' {
        local curweight bweight_`b'

        foreach q of local qlist {
            capture drop rif_pcs_q`q'
            egen rif_pcs_q`q' = rifvar(pcs_cfa50), q(`q') weight(`curweight')
            
  
	reg rif_pcs_q`q' ///
		c.age c.age#c.age  i.migback gender siblings ///
		i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
		otherparent i.birthregion i.urban [aw=`curweight']

	* Relative IOp
	local R2 = e(r2)
			
	* Totale Varianz 
	summarize rif_pcs_q`q' [aw=`curweight']
	local var_rif = r(Var)
			
	* Absolutes IOp = Var(fitted values)
	capture drop rif_hat
	predict rif_hat, xb
	quietly summarize rif_hat [aw=`curweight']
	local abs_iop = r(Var)
	drop rif_hat

	* Relative IOp robustness check
	local rel_iop = `abs_iop' / `var_rif'
	
	post pf_pcs (`yr') (`q') (`b') (`R2') (`abs_iop') (`var_rif') (`rel_iop') ("pcs")
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
append using `results_rif_pcs'
save "$output/semipara_IOp_timeseries_raw_neu.dta", replace


*------------------------------------------------------------------------------
* CI berechnen: Punktschätzer (b=0) + Perzentile aus b=1..10
*------------------------------------------------------------------------------
use  "$output/semipara_IOp_timeseries_raw_neu.dta", clear

local varlist var_rif abs_iop rel_iop
		  
* Punktschätzer (b=0)
preserve
    keep if boot_b == 0
    keep year quantile outcome `varlist'
    foreach v of local varlist {
        rename `v' pt_`v'
    }
    tempfile point_estimates
    save `point_estimates'
restore

* CI aus Bootstrap-Iterationen (b=1..B) – SOEP-Methode: SE-basiert
keep if boot_b >= 1

* Punktschätzer dazumergen für Abweichungsberechnung, genauer gesagt um die quadratische Abweichung der Punktschätzer von den anderen bootrapping-estimates zu berechen. aus dieses abweichungen wird dann der mittelwert (mit collapse) berechnet, die damit die varianz der Bootstrap-Iterationen ergibt 
merge m:1 year quantile outcome using `point_estimates', nogen

foreach v of local varlist {
    gen sq_dev_`v' = (`v' - pt_`v')^2
}

collapse (mean) sq_dev_* pt_*, by(outcome year quantile)

foreach v of local varlist {
    gen se_`v'    = sqrt(sq_dev_`v') // Standardabweichung auf Basis der Varianz
    gen ci_lo_`v' = pt_`v' - 1.96 * se_`v' // untere Grenze des KI
    gen ci_hi_`v' = pt_`v' + 1.96 * se_`v'	// obere Grenze des KI
    drop sq_dev_`v' se_`v'
}

* Wert für latex tabelle später für relative iop 
gen rel_IOp = pt_abs_iop/pt_var_rif
replace rel_IOp = rel_IOp*100
gen out_rel_IOp = string(rel_IOp, "%9.3f")

sort outcome year quantile 
save "$output/semipara_IOp_timeseries_neu.dta", replace

*------------------------------------------------------------------------------
***  Grafik über alle Jahre mit Farbcodierung
*------------------------------------------------------------------------------
* 11 Farbtöne: hell=früh, dunkel=spät

use "$output/semipara_IOp_timeseries_neu.dta", clear


** Relative IOP (R squared) @paulina 
local plots ""
local i = 1
foreach yr of numlist 2002(2)2022 {
    
    * Farben direkt per Index zuweisen
    local mcs_color : word `i' of ///
        "189 215 231" "158 202 225" "107 174 214" "66 146 198" "33 113 181" "8 81 156" "8 69 148" "8 55 130" "8 45 110" "8 37 90" "8 29 70"
    local pcs_color : word `i' of ///
        "252 187 161" "252 160 130" "252 141 89" "239 101 72" "215 48 31" "180 30 20" "165 15 21" "140 10 15" "120 5 10" "103 0 13" "80 0 10"
    local plots `plots' ///
        (line pt_rel_iop quantile if year==`yr' & outcome == "mcs", lcolor("`mcs_color'") lwidth(medthick)) ///
        (line pt_rel_iop quantile if year==`yr'& outcome == "pcs", lcolor("`pcs_color'") lwidth(medthick))
    local i = `i' + 1
}

twoway `plots', ///
    ytitle("R-squared") xtitle("Quantile") ///
    legend(order(1 "MCS 2002" 11 "MCS 2010" 21 "MCS 2022" ///
                 2 "PCS 2002" 12 "PCS 2010" 22 "PCS 2022") ///
           cols(3) size(small)) 

graph export "$output/Graphs/relIOp_allyears.png", replace


** Absolute IOP @paulina 
local plots ""
local i = 1
foreach yr of numlist 2002(2)2022 {
    
    * Farben direkt per Index zuweisen
    local mcs_color : word `i' of ///
        "189 215 231" "158 202 225" "107 174 214" "66 146 198" "33 113 181" "8 81 156" "8 69 148" "8 55 130" "8 45 110" "8 37 90" "8 29 70"
    local pcs_color : word `i' of ///
        "252 187 161" "252 160 130" "252 141 89" "239 101 72" "215 48 31" "180 30 20" "165 15 21" "140 10 15" "120 5 10" "103 0 13" "80 0 10"
    local plots `plots' ///
        (line pt_abs_iop quantile if year==`yr' & outcome == "mcs", lcolor("`mcs_color'") lwidth(medthick)) ///
        (line pt_abs_iop quantile if year==`yr'& outcome == "pcs", lcolor("`pcs_color'") lwidth(medthick))
    local i = `i' + 1
}

twoway `plots', ///
    ytitle("Variance of fitted values") xtitle("Quantile") ///
    legend(order(1 "MCS 2002" 11 "MCS 2010" 21 "MCS 2022" ///
                 2 "PCS 2002" 12 "PCS 2010" 22 "PCS 2022") ///
           cols(3) size(small)) 

graph export "$output/Graphs/absIOp_allyears.png", replace

** Total Variance @paulina 
local plots ""
local i = 1
foreach yr of numlist 2002(2)2022 {
    
    * Farben direkt per Index zuweisen
    local mcs_color : word `i' of ///
        "189 215 231" "158 202 225" "107 174 214" "66 146 198" "33 113 181" "8 81 156" "8 69 148" "8 55 130" "8 45 110" "8 37 90" "8 29 70"
    local pcs_color : word `i' of ///
        "252 187 161" "252 160 130" "252 141 89" "239 101 72" "215 48 31" "180 30 20" "165 15 21" "140 10 15" "120 5 10" "103 0 13" "80 0 10"
    local plots `plots' ///
        (line pt_var_rif quantile if year==`yr' & outcome == "mcs", lcolor("`mcs_color'") lwidth(medthick)) ///
        (line pt_var_rif quantile if year==`yr'& outcome == "pcs", lcolor("`pcs_color'") lwidth(medthick))
    local i = `i' + 1
}

twoway `plots', ///
    ytitle("Variance") xtitle("Quantile") ///
    legend(order(1 "MCS 2002" 11 "MCS 2010" 21 "MCS 2022" ///
                 2 "PCS 2002" 12 "PCS 2010" 22 "PCS 2022") ///
           cols(3) size(small)) 

graph export "$output/Graphs/var_allyears.png", replace


*------------------------------------------------------------------------------
* Grafik: Kurve über Quantile pro Jahr (mit CI-Band)
*------------------------------------------------------------------------------
*** ... hier noch mal einzeln getrennt nach jahren 

forvalues yr = 2002(2)2022 {
    twoway ///
        (rcap ci_hi_rel_iop ci_lo_rel_iop quantile  if year == `yr' & outcome == "mcs", lcolor(navy%50)) ///
        (rcap ci_hi_rel_iop ci_lo_rel_iop quantile  if year == `yr' & outcome == "pcs", lcolor(maroon%50)) ///
        (line pt_rel_iop quantile  if year == `yr' & outcome == "mcs", lwidth(medthick) lcolor(navy)) ///
        (line pt_rel_iop quantile  if year == `yr' & outcome == "pcs", lpattern(dot) lcolor(maroon)), ///
        legend(order(3 "MCS" 4 "PCS") rows(1)) ///
        ytitle("R-squared") xtitle("Quantile") /*
		title("Explained Variance across Distribution, year = `yr'") */ 
    *graph export "$output/R2_`yr'.png", replace
    
}

*** speziell für 2022 @paulina 

 twoway ///
        (rcap ci_hi_rel_iop ci_lo_rel_iop quantile  if year == 2022 & outcome == "mcs", lcolor(navy%50)) ///
        (rcap ci_hi_rel_iop ci_lo_rel_iop quantile  if year == 2022 & outcome == "pcs", lcolor(maroon%50)) ///
        (line pt_rel_iop quantile  if year == 2022 & outcome == "mcs", lwidth(medthick) lcolor(navy)) ///
        (line pt_rel_iop quantile  if year == 2022 & outcome == "pcs", lpattern(medthick) lcolor(maroon)), ///
        legend(order(3 "MCS" 4 "PCS") rows(1)) ///
        ytitle("R-squared") xtitle("Quantile") 
		graph export "$output/Graphs/R2_2022.png", replace
	
	

*------------------------------------------------------------------------------
* Grafik: Kurve über Jahre pro Quantil (mit CI-Band)
*------------------------------------------------------------------------------
use "$output/semipara_IOp_timeseries_neu.dta", clear

* relative IOp 
local qlist 10 20 30 40 50 60 70 80 90
foreach q of local qlist {
    twoway ///
        (rcap ci_hi_rel_iop ci_lo_rel_iop year  if quantile == `q' & outcome == "mcs", lcolor(navy%50)) ///
        (rcap ci_hi_rel_iop ci_lo_rel_iop year  if quantile == `q' & outcome == "pcs", lcolor(maroon%50)) ///
        (line pt_rel_iop year  if quantile == `q' & outcome == "mcs", lwidth(medthick) lcolor(navy)) ///
        (line pt_rel_iop year  if quantile == `q' & outcome == "pcs" , lpattern(dot) lcolor(maroon)), ///
        legend(order(3 "MCS" 4 "PCS") rows(1)) ///
        title("Explained Variance over Time, quantile = `q'") ///
        ytitle("R-squared") xtitle("Year")
    *graph export "$output/R2_`q'.png", replace
}

* absolute IOp 
local qlist 10 20 30 40 50 60 70 80 90
foreach q of local qlist {
    twoway ///
       (rcap ci_hi_abs_iop ci_lo_abs_iop year  if quantile == `q' & outcome == "mcs", lcolor(navy%50)) ///
       (rcap ci_hi_abs_iop ci_lo_abs_iop year  if quantile == `q' & outcome == "pcs", lcolor(maroon%50)) ///
       (line pt_abs_iop year  if quantile == `q' & outcome == "mcs", lwidth(medthick) lcolor(navy)) ///
       (line pt_abs_iop year  if quantile == `q' & outcome == "pcs" , lpattern(dot) lcolor(maroon)), ///
       title("Explained Variance over Time, quantile = `q'") ///
       ytitle("R-squared") xtitle("Year")
    *graph export "$output/R2_`q'.png", replace
}




*------------------------------------------------------------------------------
* Tabelle
*------------------------------------------------------------------------------

************
*** PCS
************
use "$output/semipara_IOp_timeseries_neu.dta", clear

sort outcome year quantile
keep year quantile pt_rel_iop pt_abs_iop outcome
keep if outcome == "pcs"
sort year quantile

reshape wide pt_rel_iop pt_abs_iop, i(year) j(quantile)

foreach q in 10 20 30 40 50 60 70 80 90 {
	replace pt_abs_iop`q' = pt_abs_iop`q'* 100
    gen out_q`q'_abs = string(pt_abs_iop`q', "%9.3f")
	
	replace pt_rel_iop`q' = pt_rel_iop`q'* 100
    gen out_q`q'_rel = string(pt_rel_iop`q', "%9.3f")
	
}
	
* Absolute IOp
file open fh using "$output/Tables/table_IOP_quantiles_PCS_abs.tex", write replace

file write fh "\begin{tabular}{lccccccccc}" _n
file write fh "\hline" _n
file write fh "\textbf{Year} & Q10 & Q20 & Q30 & Q40 & Q50 & Q60 & Q70 & Q80 & Q90 \\" _n
file write fh "\hline" _n

forvalues i = 1/`=_N' {
    file write fh ///
        (year[`i']) " & " ///
        (out_q10_abs[`i']) " & " ///
        (out_q20_abs[`i']) " & " ///
        (out_q30_abs[`i']) " & " ///
        (out_q40_abs[`i']) " & " ///
        (out_q50_abs[`i']) " & " ///
        (out_q60_abs[`i']) " & " ///
        (out_q70_abs[`i']) " & " ///
        (out_q80_abs[`i']) " & " ///
        (out_q90_abs[`i']) " \\" _n
}

file write fh "\hline" _n
file write fh "\multicolumn{10}{l}{\footnotesize{Quantile-specific inequality of opportunity (R²).}}" _n
file write fh "\end{tabular}" _n

file close fh


* Relative IOp
file open fh using "$output/Tables/table_IOP_quantiles_PCS_rel.tex", write replace

file write fh "\begin{tabular}{lccccccccc}" _n
file write fh "\hline" _n
file write fh "\textbf{Year} & Q10 & Q20 & Q30 & Q40 & Q50 & Q60 & Q70 & Q80 & Q90 \\" _n
file write fh "\hline" _n

forvalues i = 1/`=_N' {
    file write fh ///
        (year[`i']) " & " ///
        (out_q10_rel[`i']) " & " ///
        (out_q20_rel[`i']) " & " ///
        (out_q30_rel[`i']) " & " ///
        (out_q40_rel[`i']) " & " ///
        (out_q50_rel[`i']) " & " ///
        (out_q60_rel[`i']) " & " ///
        (out_q70_rel[`i']) " & " ///
        (out_q80_rel[`i']) " & " ///
        (out_q90_rel[`i']) " \\" _n
}

file write fh "\hline" _n
file write fh "\multicolumn{10}{l}{\footnotesize{Quantile-specific inequality of opportunity (R²).}}" _n
file write fh "\end{tabular}" _n

file close fh



************
*** MCS 
************

use "$output/semipara_IOp_timeseries_neu.dta", clear

sort outcome year quantile
keep year quantile pt_rel_iop pt_abs_iop outcome
keep if outcome == "mcs"
sort year quantile

reshape wide pt_rel_iop pt_abs_iop, i(year) j(quantile)

foreach q in 10 20 30 40 50 60 70 80 90 {
	replace pt_abs_iop`q' = pt_abs_iop`q'* 100
    gen out_q`q'_abs = string(pt_abs_iop`q', "%9.3f")
	
	replace pt_rel_iop`q' = pt_rel_iop`q'* 100
    gen out_q`q'_rel = string(pt_rel_iop`q', "%9.3f")
	
}

* Absolute IOp
file open fh using "$output/Tables/table_IOP_quantiles_MCS_abs.tex", write replace

file write fh "\begin{tabular}{lccccccccc}" _n
file write fh "\hline" _n
file write fh "\textbf{Year} & Q10 & Q20 & Q30 & Q40 & Q50 & Q60 & Q70 & Q80 & Q90 \\" _n
file write fh "\hline" _n

forvalues i = 1/`=_N' {
    file write fh ///
        (year[`i']) " & " ///
        (out_q10_abs[`i']) " & " ///
        (out_q20_abs[`i']) " & " ///
        (out_q30_abs[`i']) " & " ///
        (out_q40_abs[`i']) " & " ///
        (out_q50_abs[`i']) " & " ///
        (out_q60_abs[`i']) " & " ///
        (out_q70_abs[`i']) " & " ///
        (out_q80_abs[`i']) " & " ///
        (out_q90_abs[`i']) " \\" _n
}

file write fh "\hline" _n
file write fh "\multicolumn{10}{l}{\footnotesize{Quantile-specific inequality of opportunity (R²).}}" _n
file write fh "\end{tabular}" _n

file close fh


* Relative IOp
file open fh using "$output/Tables/table_IOP_quantiles_MCS_rel.tex", write replace

file write fh "\begin{tabular}{lccccccccc}" _n
file write fh "\hline" _n
file write fh "\textbf{Year} & Q10 & Q20 & Q30 & Q40 & Q50 & Q60 & Q70 & Q80 & Q90 \\" _n
file write fh "\hline" _n

forvalues i = 1/`=_N' {
    file write fh ///
        (year[`i']) " & " ///
        (out_q10_rel[`i']) " & " ///
        (out_q20_rel[`i']) " & " ///
        (out_q30_rel[`i']) " & " ///
        (out_q40_rel[`i']) " & " ///
        (out_q50_rel[`i']) " & " ///
        (out_q60_rel[`i']) " & " ///
        (out_q70_rel[`i']) " & " ///
        (out_q80_rel[`i']) " & " ///
        (out_q90_rel[`i']) " \\" _n
}

file write fh "\hline" _n
file write fh "\multicolumn{10}{l}{\footnotesize{Quantile-specific inequality of opportunity (R²).}}" _n
file write fh "\end{tabular}" _n

file close fh