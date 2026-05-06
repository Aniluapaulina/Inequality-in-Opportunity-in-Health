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


***** test anfang (für die Outcomematrix)
preserve

keep if syear == 2022

shapowen (c.age c.age#c.age) i.migback gender siblings ///
                i.msedu i.fsedu i.fprofstat i.mprofstat ///
                singleparent otherparent ///
                i.birthregion i.urban, ///
                scalar(e(r2)) : ///
    regress pcs_cfa50 @ [aw=w]
	
	// absolute Shapley value
    matrix M = r(ShapOw)
	return list
	matrix list M
	
	matrix M = r(relShapOw)
	return list 
	matrix list M
	
restore
***** test ende 


local qlist 10 20 30 40 50 60 70 80 90

tempfile shapley_results
tempname memhold

postfile `memhold' ///
    year quantile healthoutcome ///
    shap_age relshap_age ///
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


foreach outcome in pcs_cfa50 mcs_cfa50 {

    forvalues yr = 2002(2)2022 {

        preserve
        keep if syear == `yr'

        foreach q of local qlist {

            capture drop rif_`outcome'
            egen rif_`outcome' = rifvar(`outcome'), q(`q') weight(w)

            shapowen (c.age c.age#c.age) i.migback gender siblings ///
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
                (M[5,1]) (R[5,1]) ///
                (M[6,1]) (R[6,1]) ///
                (M[7,1]) (R[7,1]) ///
                (M[8,1]) (R[8,1]) ///
                (M[9,1]) (R[9,1]) ///
                (M[10,1]) (R[10,1]) ///
                (M[11,1]) (R[11,1]) ///
                (M[12,1]) (R[12,1]) ///
                (M[13,1]) (R[13,1]) ///
                (M[14,1]) (R[14,1]) ///
                (M[15,1]) (R[15,1])

            drop rif_`outcome'
        }

        restore
    }
}

postclose `memhold'

use `shapley_results', clear
save "$output/shapley_beyondmean.dta", replace



/*------------------------------------------------------------------------------
* Graphs über alle Jahre 
*-----------------------------------------------------------------------------
use "$output/Daniel/rif_shapley_all.dta", clear

*** für die var einzeln 
local vars c.age c.age#c.age i.migback gender i.msedu i.fsedu i.fprof7 i.mprof7 ///
siblings singleparent i.otherparent i.birthregion i.urban

foreach o in 1 2 {
foreach v of local vars {
	
	twoway /// 
		(scatter rel_contrib q if varname=="`v'" & outcome_id == `o') ///
		(lowess rel_contrib q if varname=="`v'" & outcome_id == `o'), ///
		xlabel(10 25 50 75 90) ///
		ytitle("relative contribution") ///
		title("`o' `v'") 
		
		local cleanname = subinstr("`v'", ".", "_", .)
		graph export "$output/shapley_beyondmean_allyears_`o'_`cleanname'.png", replace
}
}


*** für die var einzeln aber mit farblicher markierung 
foreach o in 1 2 {
	foreach v in rel_contrib abs_contrib {
	
* yearofbirth
twoway ///
    (scatter `v' q if varname=="i.yearofbirth" & outcome_id==`o', mcolor("150 150 150%40") msymbol(circle)) ///
    (lowess `v' q if varname=="i.yearofbirth" & outcome_id==`o', lcolor("150 150 150")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' i.yearofbirth")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_i_yearofbirth.png", replace

* migback
twoway ///
    (scatter `v' q if varname=="i.migback" & outcome_id==`o', mcolor("55 126 184%40") msymbol(circle)) ///
    (lowess `v' q if varname=="i.migback" & outcome_id==`o', lcolor("55 126 184")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' i.migback")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_i_migback.png", replace

* gender
twoway ///
    (scatter `v' q if varname=="gender" & outcome_id==`o', mcolor("107 174 214%40") msymbol(circle)) ///
    (lowess `v' q if varname=="gender" & outcome_id==`o', lcolor("107 174 214")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' gender")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_gender.png", replace

* i.msedu
twoway ///
    (scatter `v' q if varname=="i.msedu" & outcome_id==`o', mcolor("165 0 38%40") msymbol(circle)) ///
    (lowess `v' q if varname=="i.msedu" & outcome_id==`o', lcolor("165 0 38")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' i.msedu")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_i_msedu.png", replace

* i.fsedu
twoway ///
    (scatter `v' q if varname=="i.fsedu" & outcome_id==`o', mcolor("215 48 39%40") msymbol(circle)) ///
    (lowess `v' q if varname=="i.fsedu" & outcome_id==`o', lcolor("215 48 39")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' i.fsedu")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_i_fsedu.png", replace

* i.fprof7
twoway ///
    (scatter `v' q if varname=="i.fprof7" & outcome_id==`o', mcolor("244 109 67%40") msymbol(circle)) ///
    (lowess `v' q if varname=="i.fprof7" & outcome_id==`o', lcolor("244 109 67")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' i.fprof7")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_i_fprof7.png", replace

* i.mprof7
twoway ///
    (scatter `v' q if varname=="i.mprof7" & outcome_id==`o', mcolor("253 190 152%40") msymbol(circle)) ///
    (lowess `v' q if varname=="i.mprof7" & outcome_id==`o', lcolor("253 190 152")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' i.mprof7")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_i_mprof7.png", replace

* siblings
twoway ///
    (scatter `v' q if varname=="siblings" & outcome_id==`o', mcolor("116 196 118%40") msymbol(circle)) ///
    (lowess `v' q if varname=="siblings" & outcome_id==`o', lcolor("116 196 118")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' siblings")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_siblings.png", replace

* singleparent
twoway ///
    (scatter `v' q if varname=="singleparent" & outcome_id==`o', mcolor("35 139 69%40") msymbol(circle)) ///
    (lowess `v' q if varname=="singleparent" & outcome_id==`o', lcolor("35 139 69")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("Relative Shapley contribution") ///
    title("`o' singleparent")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_singleparent.png", replace

* i.otherparent
twoway ///
    (scatter `v' q if varname=="i.otherparent" & outcome_id==`o', mcolor("166 219 160%40") msymbol(circle)) ///
    (lowess `v' q if varname=="i.otherparent" & outcome_id==`o', lcolor("166 219 160")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' i.otherparent")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_i_otherparent.png", replace

* i.birthregion
twoway ///
    (scatter `v' q if varname=="i.birthregion" & outcome_id==`o', mcolor("117 107 177%40") msymbol(circle)) ///
    (lowess `v' q if varname=="i.birthregion" & outcome_id==`o', lcolor("117 107 177")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' i.birthregion")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_i_birthregion.png", replace

* i.urban
twoway ///
    (scatter `v' q if varname=="i.urban" & outcome_id==`o', mcolor("188 189 220%40") msymbol(circle)) ///
    (lowess `v' q if varname=="i.urban" & outcome_id==`o', lcolor("188 189 220")), ///
    xlabel(10 25 50 75 90) ///
    ytitle("`v' contribution") ///
    title("`o' i.urban")
graph export "$output/shapley_beyondmean_allyears_`o'_`v'_i_urban.png", replace

}
}


*** alles vars in einem plot mit farblicher markierung
foreach o in 1 2 {
	foreach v in rel_contrib abs_contrib {
		
		twoway ///
			(scatter `v' q if varname=="i.yearofbirth" & outcome_id==`o', mcolor("150 150 150%40")) ///
			(lowess `v' q if varname=="i.yearofbirth" & outcome_id==`o', lcolor("150 150 150")) ///
			(scatter `v' q if varname=="i.migback" & outcome_id==`o', mcolor("55 126 184%40")) ///
			(lowess `v' q if varname=="i.migback" & outcome_id==`o', lcolor("55 126 184")) ///
			(scatter `v' q if varname=="gender" & outcome_id==`o', mcolor("107 174 214%40")) ///
			(lowess `v' q if varname=="gender" & outcome_id==`o', lcolor("107 174 214")) ///
			(scatter `v' q if varname=="i.msedu" & outcome_id==`o', mcolor("165 0 38%40")) ///
			(lowess `v' q if varname=="i.msedu" & outcome_id==`o', lcolor("165 0 38")) ///
			(scatter `v' q if varname=="i.fsedu" & outcome_id==`o', mcolor("215 48 39%40")) ///
			(lowess `v' q if varname=="i.fsedu" & outcome_id==`o', lcolor("215 48 39")), ///
			xlabel(10 25 50 75 90) ///
			xtitle("Health quantiles") ///
			ytitle("Relative Shapley contribution") ///
			legend(off) ///
			title("`v', all years for `o'")
			
			graph export "$output/shapley_beyondmean_allyears_`v'_`o'.png", replace
											}
					}

/*	
*------------------------------------------------------------------------------
* Graphs über die Jahre einzeln
*-----------------------------------------------------------------------------
	
use "$output/Daniel/rif_shapley_all.dta", clear

replace rel_contrib = rel_contrib*100
recode stat_id (3=10) (4=25) (5=50) (6=75) (7=90)
rename stat_id q

local vars gender height i.birthregion i.fprof7 i.fsedu i.migback ///
           i.mprof7 i.msedu i.otherparent i.urban i.yearofbirth ///
           siblings singleparent

local colors red blue forest_green orange purple teal maroon olive navy cranberry sienna gold brown
local years 2002 2004 2006 2008 2010 2012 2014 2016 2018 2020 2022

foreach o in 1 2 {

    foreach y of local years {

        local plot ""
        local i = 1

       foreach v of local vars {

            local col : word `i' of `colors'

            local plot `plot' ///
            (connected rel_contrib q if varname=="`v'" & year==`y' & outcome_id==`o', ///
            sort mcolor(`col') msize(vsmall) lcolor(`col'))

            local ++i
        }

        twoway `plot', ///
        xlabel(10 25 50 75 90) ///
        xtitle("Health quantiles") ///
        ytitle("Relative Shapley contribution") ///
        title("Shapley contributions — Year `y'") ///
        legend(off)

        if `o' == 1 local name "MCS"
        if `o' == 2 local name "PCS"

        graph export "$output/shapley_`name'_`y'.png", replace
    }
}

*/

	

	
	
	
	