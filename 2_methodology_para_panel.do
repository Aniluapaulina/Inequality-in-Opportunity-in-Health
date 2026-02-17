********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 2_methodolody_para
***	   Description: Parametric methodology- Panel Analysis 			                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************

clear all
use $output/base.dta, clear 
*use $output/basenomissings.dta , clear
tab syear


* Panel analysis 
tempfile results
postfile pf ///
    year ///
    R2_mcs_orig R2_mcs_cfa ///
    GiniAbs_mcs_orig GiniRel_mcs_orig GiniAbs_mcs_cfa GiniRel_mcs_cfa ///
    R2_pcs_orig R2_pcs_cfa ///
    GiniAbs_pcs_orig GiniRel_pcs_orig  GiniAbs_pcs_cfa GiniRel_pcs_cfa ///
	using `results', replace
	

* Main loop: 2002-2022
forvalues yr = 2002(2)2022 {
	preserve
	
	keep if syear == `yr'
	
*------------------------------------------------------------------------------
* MENTAL COMPONENT SCALE
*------------------------------------------------------------------------------
	* Outcome = SOEP MCS based on all weights from EFA 
	reg mcs i.yearofbirth bodyheight i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
    local R2_mcs_orig = e(r2)
	
    predict mcs_orig_hat, xb
    ineqdeco mcs_orig_hat
    local GiniAbs_mcs_orig = $S_gini
    ineqdeco mcs
    local Gobs_mcs = $S_gini
    local GiniRel_mcs_orig = `GiniAbs_mcs_orig' / `Gobs_mcs'
 
	
	** Outcome = MCS based on CFA 
	reg mcs_cfa50  ii.yearofbirth bodyheight i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	local R2_mcs_cfa = e(r2)

    predict mcs_cfa50_hat, xb
    ineqdeco mcs_cfa50_hat
    local GiniAbs_mcs_cfa = $S_gini
    ineqdeco mcs_cfa50
    local Gobs_mcs = $S_gini
    local GiniRel_mcs_cfa = `GiniAbs_mcs_cfa' / `Gobs_mcs'
	 
	 
*------------------------------------------------------------------------------
* PHYSICAL COMPONNET SCALE 
*------------------------------------------------------------------------------
	* Outcome = SOEP MCS based on all weights from EFA 
	reg pcs i.yearofbirth bodyheight i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
    local R2_pcs_orig = e(r2)

    predict pcs_orig_hat, xb
    ineqdeco pcs_orig_hat
    local GiniAbs_pcs_orig = $S_gini
    ineqdeco pcs
    local Gobs_pcs = $S_gini
    local GiniRel_pcs_orig = `GiniAbs_pcs_orig' / `Gobs_pcs' 
	
	
	** Outcome = MCS based on CFA 
	reg pcs_cfa50  i.yearofbirth bodyheight i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	local R2_pcs_cfa = e(r2)

    predict pcs_cfa50_hat, xb
    ineqdeco pcs_cfa50_hat
    local GiniAbs_pcs_cfa = $S_gini
    ineqdeco pcs_cfa50
    local Gobs_pcs = $S_gini
    local GiniRel_pcs_cfa = `GiniAbs_pcs_cfa' / `Gobs_pcs'

	post pf ///
    (`yr') ///
    (`R2_mcs_orig') (`R2_mcs_cfa') ///
    (`GiniAbs_mcs_orig') (`GiniRel_mcs_orig') ///
    (`GiniAbs_mcs_cfa') (`GiniRel_mcs_cfa') ///
    (`R2_pcs_orig') (`R2_pcs_cfa') ///
    (`GiniAbs_pcs_orig') (`GiniRel_pcs_orig') ///
    (`GiniAbs_pcs_cfa') (`GiniRel_pcs_cfa')
	
	restore 
		
}
	postclose pf

	
* load and results 
	use `results', clear
	order year, first
	sort year
	save "$output/para_IOp_timeseries.dta", replace

	
* Graphs 
use "$output/para_IOp_timeseries.dta", clear

* R^2 for MCS over time 
twoway ///
    (line R2_mcs_orig year, lwidth(medthick)) ///
    (line R2_mcs_cfa  year, lpattern(dot)), ///
    legend(order(1 "Original" 2 "CFA") rows(1)) ///
    title("Explained Variance over Time – MCS") ///
    ytitle("R-squared") ///
    xtitle("Year")

	graph export "$output/mcs_R2.png", replace
	
	list year R2_mcs_orig  R2_mcs_cfa, clean 
	/* Tabelle: 
	
	* Basis 1: 
	      year   R2_mcs~g   R2_mcs~a  
	  1.   2002    .048501   .0635536  
	  2.   2004   .0463161    .071822  
	  3.   2006   .0485972   .0741593  
	  4.   2008   .0490295   .0663406  
	  5.   2010   .0547731   .0685973  
	  6.   2012   .0429234   .0654685  
	  7.   2014   .0493058   .0614324  
	  8.   2016   .0482794   .0610217  
	  9.   2018   .0509018   .0565605  
	 10.   2020   .0505561   .0537402  
	 11.   2022   .0748914   .0690731  
	 
	 * Basis 2:
	 year   R2_mcs~g   R2_mcs~a  
	  1.   2002   .0585283   .0602857  
	  2.   2004   .0588483   .0732017  
	  3.   2006   .0499611   .0675578  
	  4.   2008   .0564865   .0636409  
	  5.   2010   .0637183   .0713855  
	  6.   2012   .0418536    .058445  
	  7.   2014   .0577465   .0602446  
	  8.   2016   .0518135   .0553752  
	  9.   2018   .0522191   .0519644  
	 10.   2020   .0525197   .0492212  
	 11.   2022   .0882791   .0780755  	 
	 */ 

	
* R^2 for PCS over time
twoway ///
    (line R2_pcs_orig year, lwidth(medthick)) ///
    (line R2_pcs_cfa  year, lpattern(dot)), ///
    legend(order(1 "Original" 2 "CFA") rows(1)) ///
    title("Explained Variance over Time – PCS") ///
    ytitle("R-squared") ///
    xtitle("Year")
    
	graph export "$output/pcs_R2.png", replace
	
	list year R2_pcs_orig  R2_pcs_cfa, clean 
	/* Tabelle
	       year   R2_pcs~g   R2_pcs~a  
	  1.   2002   .3264502   .2600369  
	  2.   2004   .3443164   .2783249  
	  3.   2006   .3221596   .2590041  
	  4.   2008   .3144495   .2523198  
	  5.   2010   .3197092   .2605531  
	  6.   2012   .2879776   .2397653  
	  7.   2014   .2844886   .2321061  
	  8.   2016   .2675492   .2187819  
	  9.   2018   .2670987   .2164074  
	 10.   2020   .2777926   .2212926  
	 11.   2022   .2754711    .221667 

	 * Basis 2:
	      year   R2_pcs~g   R2_pcs~a  
	  1.   2002   .3187534   .2512888  
	  2.   2004   .3357993   .2673462  
	  3.   2006     .31828   .2512288  
	  4.   2008   .3075119   .2450716  
	  5.   2010   .3317469   .2690023  
	  6.   2012   .2915272   .2406084  
	  7.   2014    .282726   .2267198  
	  8.   2016    .271497    .217056  
	  9.   2018    .265497   .2121276  
	 10.   2020   .2760923   .2175406  
	 11.   2022   .2791973    .223929  

	 
	 */
	
	

* Rel Gini MCS over time 
twoway ///
    (line GiniRel_mcs_orig year, lwidth(medthick)) ///
    (line GiniRel_mcs_cfa  year, lpattern(dot)), ///
    legend(order(1 "Original" 2  "CFA") rows(1)) ///
    title("Relative Inequality of Opportunity – MCS") ///
    ytitle("Relative Gini") ///
    xtitle("Year")
	
	graph export "$output/mcs_gini_relative.png", replace
	
	list year GiniRel_mcs_orig GiniRel_mcs_cfa, clean 
	/* Tabelle
	year   GiniRe..   GiniRe..   GiniRe..  
	  1.   2002   1.012035   1.022139    1.02274  
	  2.   2004   .8489206   .8281903   .8299328  
	  3.   2006   .4077875   .4164822   .4259401  
	  4.   2008    .650788   .6541075   .6511717  
	  5.   2010   .4086078   .4087949   .4133066  
	  6.   2012   .3402231   .3488737   .3568819  
	  7.   2014   .3221057   .3181309   .3198431  
	  8.   2016   .3695636    .390866   .4006688  
	  9.   2018   .3052913   .2859754   .2890687  
	 10.   2020   .2961433   .2906337   .2904762  
	 11.   2022   .3288476   .2848944   .2784316 */


* Rel Gini PCS over time 
 twoway ///
    (line GiniRel_pcs_orig year, lwidth(medthick)) ///
    (line GiniRel_pcs_cfa  year, lpattern(dot)), ///
    legend(order(1 "Original" 2 "CFA") rows(1)) ///
    title("Relative Inequality of Opportunity – PCS") ///
    ytitle("Relative Gini") ///
    xtitle("Year")
    
	graph export "$output/pcs_gini_relative.png", replace
	
	list year GiniRel_pcs_orig GiniRel_pcs_cfa, clean 
	/* Tabelle
	year   GiniRe..   GiniRe..   GiniRe..  
	  1.   2002   1.015956   1.028933   1.032208  
	  2.   2004   .8781236   .8672239   .8610547  
	  3.   2006   .5994539    .569973   .5670337  
	  4.   2008   .6803905   .6829324   .6767465  
	  5.   2010   .6617283   .6193746     .60897  
	  6.   2012   .5843655   .5562544   .5479887  
	  7.   2014   .5511376   .5121761   .5014103  
	  8.   2016   .5166356   .4981441   .4895478  
	  9.   2018   .5171011   .4722292   .4596927  
	 10.   2020   .5111746   .4760525   .4677677  
	 11.   2022   .5252056   .4644685   .4530844 */ 

