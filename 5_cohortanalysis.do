********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 19.03.2025											
***    Do-file: 5_cohortanalysis
***	   Description: Cohort analysis ....	                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************
* Motivation: The Shapley decomposition prescribed yearofbirth a large part in IOp (~50% for MCS and over 70% for PCS). 

* Grundproblem APC (what is due to age, period and cohort?) with age = period - cohort (siehe http://www.hoepflinger.com/fhtop/Alter-Kohorten-Periode.pdf)
	* alterseffekte als sozio-biologische Veränderungen im Laufe eines Lebens; wear and tear
	* periodeneffekte für alle menschen zu einem bestimmten zeitpunkt (z.b. covid, finanzkrise); Beobachtungsjahr
	* cohorteneffekte für nur eine bestimmte geburtskohorte relevant
	
* Idee: Ich betrahte nur Menschen im Alter von 30-40, d.h. ich halte den Alterseffekt konstant und schaue dann über mehrere Kohorten. Warum 30-40 Jahre? Weil sich der Effekt von circumstances physiologisch erst ab ~30 manifestiert, aber noch bevor der biologische Alterungsprozess dominiert (ab ~50).

* Frage: Ist der große YOB-Effekt aus der Baseline-Analyse ein Alterseffekt oder ein Kohorteneffekt?


clear all
use $output/final.dta, clear 

* Stichprobenanpassung
keep if age >= 30 & age <= 40 // insgesamt noch 22.000 Observationen 

* Was für Kohorten habe ich jetzt? 
tab syear

	gen cohort = .
	replace cohort = 1 if yearofbirth >= 1960 & yearofbirth <= 1969
	replace cohort = 2 if yearofbirth >= 1970 & yearofbirth <= 1979
	replace cohort = 3 if yearofbirth >= 1980 & yearofbirth <= 1989
	replace cohort = 4 if yearofbirth >= 1990 & yearofbirth <= 1999

	label define cohortlabel 1 "1960-69" 2 "1970-79" 3 "1980-89" 4 "1990-99"
	label values cohort cohortlabel

* Wie viele Beobachtungen pro Kohorte und Welle?
tab cohort syear

* Wie verteilt sich Alter innerhalb der Kohorten?
tabstat age, by(cohort) stats(mean sd min max n)
 
	// 1960-69 --> 2002-2008 beobachtet 
	// 1970-79 --> 2002-2016 beobachtet     
	// 1980-89 --> 2010-2022 beobachtet
	

* Analyse kopiert aus 3_meanbased_shapley.do 
*------------------------------------------------------------------------------
* panel baseline
*------------------------------------------------------------------------------

tempfile shapley_results
tempname memhold

postfile `memhold' ///
    year str3 healthoutcome ///
    shap_yearofbirth relshap_yearofbirth ///  
    shap_migback relshap_migback ///
    shap_gender relshap_gender  ///
    shap_siblings relshap_siblings ///
    shap_msedu relshap_msedu ///
    shap_fsedu relshap_fsedu ///
    shap_fprofstat relshap_fprofstat ///
    shap_mprofstat relshap_mprofstat ///
    shap_singleparent relshap_singleparent ///
    shap_otherparent relshap_otherparent ///
    shap_birthregion relshap_birthregion ///
    shap_urban relshap_urban ///
    using `shapley_results'
	

foreach outcome in pcs_cfa50 mcs_cfa50 {
	forvalues yr = 2002(2)2022 {

    preserve
    keep if syear == `yr'
	
    shapowen i.yearofbirth i.migback gender siblings i.msedu i.fsedu ///
	i.fprofstat i.mprofstat singleparent otherparent ///
    i.birthregion i.urban, scalar(e(r2)) : ///
    regress `outcome' @ [aw=w]
	
	// absolute Shapley value
    matrix M = r(ShapOw)
	
    scalar s1  = M[2,1]
    scalar s2  = M[3,1]
    scalar s3  = M[4,1]
    scalar s4  = M[5,1]
    scalar s5  = M[6,1]
    scalar s6  = M[7,1]
    scalar s7  = M[8,1]
    scalar s8  = M[9,1]
    scalar s9  = M[10,1]
    scalar s10 = M[11,1]
    scalar s11 = M[12,1]
    scalar s12 = M[13,1]
	
	// relative Shapley value
	matrix M = r(relShapOw)
	
    scalar a1  = M[2,1]
    scalar a2  = M[3,1]
    scalar a3  = M[4,1]
    scalar a4  = M[5,1]
    scalar a5  = M[6,1]
    scalar a6  = M[7,1]
    scalar a7  = M[8,1]
    scalar a8  = M[9,1]
    scalar a9  = M[10,1]
    scalar a10 = M[11,1]
    scalar a11 = M[12,1]
    scalar a12 = M[13,1]

    post `memhold' ///
        (`yr') ("`outcome'") ///
        (s1) (a1) (s2) (a2) (s3) (a3) ///
        (s4) (a4) (s5) (a5) (s6) (a6) ///
		(s7) (a7) (s8) (a8) (s9) (a9) ///
		(s10) (a10) (s11) (a11) (s12) (a12)

    restore
	}	
}

postclose `memhold'

use `shapley_results', clear
save "$output/shapley_para_cohortanalysis.dta", replace


*------------------------------------------------------------------------------
* graphs
*------------------------------------------------------------------------------
use "$output/shapley_para_cohortanalysis.dta", clear 

*** Shapley Decomposition nur Anteile - Gestapelte Balken über alle Jahre
foreach var in pcs mcs {
	
	graph bar (asis) ///
        shap_* ///
        if healthoutcome=="`var'", ///
        over(year) ///
        stack ///
        bar(1,  color("150 150 150")) bar(2,  color("55 126 184")) ///
        bar(3,  color("107 174 214")) bar(4,  color("189 215 231")) ///
        bar(5,  color("165 0 38"))    bar(6,  color("215 48 39"))  ///
        bar(7,  color("244 109 67"))  bar(8,  color("253 190 152")) ///
        bar(9,  color("35 139 69"))   bar(10, color("116 196 118")) ///
        bar(11, color("117 107 177")) bar(12, color("188 189 220")) ///
        title("Shapley decomposition `var', absolute") ///
        ytitle("% contribution to IOp", size(small)) ///
        legend(cols(4) size(small) region(lwidth(none)) ///
            order(1 "yearofbirth" 2 "migback" 3 "gender" 4 "siblings" ///
                  5 "msedu" 6 "fsedu" 7 "fprofstat" 8 "mprofstat" ///
                  9 "singleparent" 10 "otherparent" ///
                  11 "birthregion" 12 "urban"))
	
	graph export "$output/`var'_cfa50_mean_shapley_absolute_ca.png", replace
}

	
*** Shapley Decomposition mit gestapelte Balken über alle Jahre --> relative Anteile an 1
foreach var in pcs mcs {
	
	graph bar /* hbar */ (asis) ///
    relshap_* ///
    if healthoutcome=="`var'", ///
    over(year) ///
    stack ///
	bar(1,  color("150 150 150")) bar(2,  color("55 126 184")) ///
        bar(3,  color("107 174 214")) bar(4,  color("189 215 231")) ///
        bar(5,  color("165 0 38"))    bar(6,  color("215 48 39"))  ///
        bar(7,  color("244 109 67"))  bar(8,  color("253 190 152")) ///
        bar(9,  color("35 139 69"))   bar(10, color("116 196 118")) ///
        bar(11, color("117 107 177")) bar(12, color("188 189 220")) ///
    title("Shapley decomposition `var', relative") ///
    ytitle("% contribution to IOp", size(small)) ///
    legend(cols(4) size(small) region(lwidth(none)) ///
	order(1 "yearofbirth" 2 "migback" 3 "gender" 4 "siblings" 5 "msedu" 6 "fsedu" 7 "fprofstat" ///
		  8 "mprofstat" 9 "singleparent" 10 "otherparent" 11 "birthregion" 12 "urban"))
	
	graph export "$output/`var'_cfa50_mean_shapley_relative_ca.png", replace
	
}




