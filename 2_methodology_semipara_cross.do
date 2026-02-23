********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 2_methodolody_semipara
***	   Description: Semi-Parametric methodology	- Cross Sectional Analysis 			                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************

* Conceptual Introduction to Semi-Parametric methodology 
	/* Opportunity set = F[Hit | Ci ] bzw. Q[Hit | Ci ]
	
	1. rifvar konstruiert RIF (berechnet dafür das Quantil & schätzt die Dichte an dieser Stelle mit einem einfachen Kernel-Estimator
	2. OLS regression schätzt ∂Q(H)/∂C
	
	*/
	
use $output/base.dta, clear 

* Initail corss-sectional analysis 
	count if syear == 2022	// 31,615
	keep if syear == 2022
	
*------------------------------------------------------------------------------
* MENTAL COMPONENT SCALE
*------------------------------------------------------------------------------

	local j = 1
	local qlist 10 20 30 40 50 60 70 80 90
	matrix R2_mcs = J(1,9,.)
	
	foreach q of local qlist {
		
	 * RIF für Quantil q	
	egen rif_mcs_q`q' = rifvar(mcs), q(`q') weight(w)
	// RIF only records whether an observation lies below or above the quantile. Therefore, RIF takes only two values. Using this I can in the next step
	// evaluate whether Ci systematically move people above or below the quantile.
	
	* RIF-Regression
	// estimating ∂Q(H)0.5/∂C
	reg rif_mcs_q`q' i.yearofbirth bodyheight i.migback gender 	///
	siblings i.fedu4 i.medu4 i.fprof5 i.mprof5 singleparent otherparent 	///
	i.birthregion i.urban [fw=w]
	
	// Interpretation: Ich erkläre nicht die individuelle Gesundheit, sondern den Beitrag zum Median (Quantil) als Funktion der Umstände. 
	// Die Regression sagt dir also: Wie stark verschiebt sich der unbedingte Median der Gesundheit ∂Q(H)0.5, wenn sich eine Circumstance-Variable ändert ∂C?

	matrix R2_mcs[1,`j'] = e(r2)
	local j = `j' + 1	
	}
	
	matrix list R2_mcs
	
	
*------------------------------------------------------------------------------
* PHYSICAL COMPONNET SCALE 
*------------------------------------------------------------------------------

	local j = 1
	local qlist 10 20 30 40 50 60 70 80 90
	matrix R2_pcs = J(1,9,.)
	
	* RIF für Quantil q	
	foreach q of local qlist {
	egen rif_pcs_q`q' = rifvar(pcs), q(`q') weight(w)
	
	* RIF-Regression
	reg rif_pcs_q`q' i.yearofbirth bodyheight i.migback gender 	///
	siblings i.fedu4 i.medu4 i.fprof5 i.mprof5 singleparent otherparent 	///
	i.birthregion i.urban [fw=w]
	
	matrix R2_pcs[1,`j'] = e(r2)
	local j = `j' + 1	
	}
	
	matrix list R2_pcs

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	