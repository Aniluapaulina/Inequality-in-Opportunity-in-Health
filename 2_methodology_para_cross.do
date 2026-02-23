********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 2_methodolody_para
***	   Description: Parametric methodology - Cross Sectional Analysis 			                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************

* Conceptual Introduction to Parametric methodology * 

	/* Opportunity set = E[Hit | Ci ]
	
	1. Isolate variation in health Hit that is due to circumstances Ci using OLS 
		Hit = Ci ψt + εit
		
	2. Compute expected health conditional on circumstances
		E [Hit | Ci ] = ˆHit = Ci ˆψt
		
	3. Apply inequality measure to this conditional expectation (absolute IOp) and divide by the same inequality measure on observed health (relative IOp)
		δa = I ( ˆHit )
		δr = I ( ˆHit ) / I (Hit )
		
	*/
	
use $output/base.dta, clear 

* Initial corss-sectional analysis 
	count if syear == 2022	
	keep if syear == 2022
	di _N

*------------------------------------------------------------------------------
* MENTAL COMPONENT SCALE
*------------------------------------------------------------------------------
	
*** Inequality Measure = R^2 (translation invariant)
	
	** Outcome = SOEP MCS based on all weights from EFA 
	reg mcs i.yearofbirth i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	scalar R2_mcs = e(r2)
	di "Relative IOp in MCS= " R2_mcs
		
	** Outcome = MCS based on CFA 
	reg mcs_cfa50 i.yearofbirth i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	scalar R2_mcs = e(r2)
	di "Relative IOp in MCS= " R2_mcs
	
	
*** Inequality Measure = Gini (as a translation variant measure )
	
	** Outcome = SOEP MCS based on all weights from EFA  
	preserve
	reg mcs i.yearofbirth  i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	predict mcs_hat, xb
	
	ineqdeco mcs_hat
	scalar I_mcs_hat = $S_gini
	ineqdeco mcs
	scalar I_mcs_obs = $S_gini
	scalar rel_IOp_mcs = I_mcs_hat / I_mcs_obs

	di "Absolute IOp in MCS = " I_mcs_hat
	di "Relative IOp in MCS= " rel_IOp_mcs
		// Absolute IOp in MCS = .03802735
		// Relative IOp in MCS = .32884761
	restore 
	
	** Outcome = MCS based on CFA 	
	preserve 
	reg mcs_cfa50 i.yearofbirth i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	predict mcs_hat, xb
	
	ineqdeco mcs_hat
	scalar I_mcs_hat = $S_gini
	ineqdeco mcs
	scalar I_mcs_obs = $S_gini
	scalar rel_IOp_mcs = I_mcs_hat / I_mcs_obs

	di "Absolute IOp in MCS = " I_mcs_hat
	di "Relative IOp in MCS= " rel_IOp_mcs
		// Absolute IOp in MCS = .03085903
		// Relative IOp in MCS = .26685834
	restore 
		
		
		
		
*------------------------------------------------------------------------------
* PHYSICAL COMPONNET SCALE 
*------------------------------------------------------------------------------

*** Inequality Measure = R^2 (translation invariant)
	
	** Outcome = SOEP PCS based on all weights from EFA 
	reg pcs i.yearofbirth  i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	scalar R2_pcs = e(r2)
	di "Relative IOp in PCS= " R2_pcs
	// Relative IOp in PCS= .26015916
	
	** Outcome = PCS based on CFA 
	reg pcs_cfa50  i.yearofbirth  i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	scalar R2_pcs = e(r2)
	di "Relative IOp in PCS= " R2_pcs
	// Relative IOp in PCS= .19934991


*** Inequality Measure = Gini (as a translation variant measure )
	
	** Outcome = SOEP PCS based on all weights from EFA  
	preserve
	reg pcs i.yearofbirth  i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	predict pcs_hat, xb
	
	ineqdeco pcs_hat
	scalar I_pcs_hat = $S_gini
	ineqdeco pcs
	scalar I_pcs_obs = $S_gini
	scalar rel_IOp_pcs = I_pcs_hat / I_pcs_obs

	di "Absolute IOp in PCS = " I_pcs_hat
	di "Relative IOp in PCS= " rel_IOp_pcs
		// Absolute IOp in PCS = .05828146
		// Relative IOp in PCS = .52520557
	restore 
	
	
	** Outcome = PCS based on CFA 	
	preserve 
	reg pcs_cfa50 i.yearofbirth  i.migback gender siblings i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
	otherparent i.birthregion i.urban [fw=w]
	predict pcs_hat, xb
	
	ineqdeco pcs_hat
	scalar I_pcs_hat = $S_gini
	ineqdeco pcs
	scalar I_pcs_obs = $S_gini
	scalar rel_IOp_pcs = I_pcs_hat / I_pcs_obs

	di "Absolute IOp in PCS = " I_pcs_hat
	di "Relative IOp in PCS= " rel_IOp_pcs
		// Absolute IOp in PCS = .04870508
		// Relative IOp in PCS = .43890762
	restore 

 


