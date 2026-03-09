********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 23.02.2025											
***    Do-file: 4_beyondmean_shapley
***	   Description: Shapley decomposition for parametric analysis 		                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************
* Goal: Ascribing covariate contributions to a regression's R2


clear all
use $output/final.dta, clear 

local qlist 10 20 30 40 50 60 70 80 90

tempfile shapley_results
tempname memhold

postfile `memhold' ///
    year quantile str3 healthoutcome ///
    shap_yearofbirth relshap_yearofbirth ///
    shap_migback relshap_migback ///
    shap_gender relshap_gender ///
    shap_siblings relshap_siblings ///
    shap_msedu relshap_msedu ///
    shap_fsedu relshap_fsedu ///
    shap_fprofstat relshap_fprofstat ///
    shap_mprofstat relshap_mprofstat ///
    shap_singleparent relshap_singleparent ///
    shap_otherparent relshap_otherparent ///
    shap_birthregion relshap_birthregion ///
    shap_urban relshap_urban ///
    using `shapley_results', replace


foreach outcome in pcs mcs {

    forvalues yr = 2002(2)2022 {

        preserve
        keep if syear == `yr'

        foreach q of local qlist {

            capture drop rif_`outcome'
            egen rif_`outcome' = rifvar(`outcome'), q(`q') weight(w)

            shapowen i.yearofbirth i.migback gender siblings ///
                i.msedu i.fsedu i.fprofstat i.mprofstat ///
                singleparent otherparent ///
                i.birthregion i.urban, ///
                scalar(e(r2)) : ///
                regress rif_`outcome' @ [aw=w]

            matrix M = r(ShapOw)
            matrix R = r(relShapOw)

            post `memhold' ///
                (`yr') (`q') ("`outcome'") ///
                (M[2,1]) (R[2,1]) ///
                (M[3,1]) (R[3,1]) ///
                (M[4,1]) (R[4,1]) ///
                (M[5,1]) (R[5,1]) ///
                (M[6,1]) (R[6,1]) ///
                (M[7,1]) (R[7,1]) ///
                (M[8,1]) (R[8,1]) ///
                (M[9,1]) (R[9,1]) ///
                (M[10,1]) (R[10,1]) ///
                (M[11,1]) (R[11,1]) ///
                (M[12,1]) (R[12,1]) ///
                (M[13,1]) (R[13,1])

            drop rif_`outcome'
        }

        restore
    }
}

postclose `memhold'

use `shapley_results', clear
save "$output/shapley_beyondmean.dta", replace
	
	
	
	