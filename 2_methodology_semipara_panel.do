********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 2_methodolody_semipara
***	   Description: Semi-Parametric methodology	- Panel Analysis 			                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************

clear all
use $output/base.dta, clear 

* Panel analysis 
local qlist 10 20 30 40 50 60 70 80 90

*------------------------------------------------------------------------------
* MENTAL COMPONENT SCALE
*------------------------------------------------------------------------------
tempfile results_rif_mcs

postfile pf ///
    year quantile R2_mcs_orig ///
    using `results_rif_mcs', replace
	
forvalues yr = 2002(2)2022 {
	preserve
	
	keep if syear == `yr'
	
	foreach q of local qlist {

        * RIF für Quantil q
        egen rif_mcs_q`q' = rifvar(mcs), q(`q') weight(w)

        * RIF-Regression
        reg rif_mcs_q`q' ///
		i.yearofbirth bodyheight i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
		otherparent i.birthregion i.urban [fw=w]

        local R2 = e(r2)

        * ---> in Ergebnistabelle 
        post pf (`yr') (`q') (`R2')

        drop rif_mcs_q`q'
    }

    restore
}
postclose pf

*------------------------------------------------------------------------------
* PHYSICAL COMPONNET SCALE 
*------------------------------------------------------------------------------
tempfile results_rif_pcs

postfile pf ///
    year quantile R2_pcs_orig ///
    using `results_rif_pcs', replace
	
forvalues yr = 2002(2)2022 {
	preserve
	
	keep if syear == `yr'
	
	foreach q of local qlist {

        * RIF für Quantil q
        egen rif_pcs_q`q' = rifvar(pcs), q(`q') weight(w)

        * RIF-Regression
        reg rif_pcs_q`q' ///
            i.yearofbirth bodyheight i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
		otherparent i.birthregion i.urban [fw=w]

        local R2 = e(r2)

        * ---> in Ergebnistabelle 
        post pf (`yr') (`q') (`R2')

        drop rif_pcs_q`q'
    }

    restore
}
postclose pf	

* load and results 
	use `results_rif_mcs', clear
	sort year quantile
	merge 1:1 year quantile using `results_rif_pcs', nogen 
	save "$output/semipara_IOp_timeseries.dta", replace

* Graphs 	
use "$output/semipara_IOp_timeseries.dta", clear 

* Kurve über die Jahre pro Quantil
local qlist 10 20 30 40 50 60 70 80 90

foreach q of local qlist { 
	twoway ///
	(line R2_mcs_orig year if quantile == `q', lwidth(medthick)) ///
	(line R2_pcs_orig year if quantile == `q', lwidth(dot)), ///
	legend(order(1 "MCS" 2 "PCS") rows(1)) ///
    title("Explained Variance over Time, quantile = `q' ") ///
    ytitle("R-squared") ///
    xtitle("Year")

	graph export "$output/R2_`q'.png", replace
	list year R2_mcs_orig R2_pcs_orig if quantile ==  `q', clean 
}
	
	

* Kurve über die Verteilung (Quantile) pro Jahr 

forvalues yr = 2002(2)2022 { 
	twoway ///
	(line R2_mcs_orig quantile if year == `yr', lwidth(medthick)) ///
	(line R2_pcs_orig quantile if year == `yr', lwidth(dot)), ///
	legend(order(1 "MCS" 2 "PCS") rows(1)) ///
    title("Explained Variance over Time, year = `yr' ") ///
    ytitle("R-squared") ///
    xtitle("Year")

	graph export "$output/R2_`yr'.png", replace
	list quantile R2_mcs_orig R2_pcs_orig if year ==  `yr', clean 
}



	
	
	
	
