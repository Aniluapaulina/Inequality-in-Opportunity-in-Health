********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 05.05.2025											
***    Do-file: 5_cohortanalysis
***	   Description: Cohort analysis 	                                     	
***    Project: "IOP in health in Germany" 
********************************************************************************
* Motivation: The Shapley decomposition prescribed yearofbirth a large part in IOp (~50% for MCS and over 70% for PCS). 

* Grundproblem APC (what is due to age, period and cohort?) with age = period - cohort (siehe http://www.hoepflinger.com/fhtop/Alter-Kohorten-Periode.pdf)
	* alterseffekte als sozio-biologische Veränderungen im Laufe eines Lebens; wear and tear
	* periodeneffekte für alle menschen zu einem bestimmten zeitpunkt (z.b. covid, finanzkrise); Beobachtungsjahr
	* cohorteneffekte für nur eine bestimmte geburtskohorte relevant

* Frage: Ist der große YOB-Effekt aus der Baseline-Analyse ein Alterseffekt oder ein Kohorteneffekt?
* Idee: KOhortenanalse für MEnsche in Altersspanne von 31-40, die jeweils in die ANalyse nur einmal einbezogen werden. D.h. konkreter., die Kohorten wurden so gewählt, dass zum Beobaachtungszeitraum (3) die Person in der Altersspanne lag. 6 Jahrgänge pro Kohorte und 6 Jahre Abstand in Beobachtungsjahren. 
* Kohorte 1: geb. 1966-1971
* Kohorte 2: 1972-1977  
* Kohorte 3: 1978-1983
* Kohorte 4: 1984-1989



/* Isabelle Brainstorm
	gen c = . 
	replace c = 1 if (2006 - yearofbirth) >= 33 & (2002 - yearofbirth) <= 37 
	replace c = 2 if (2010 - yearofbirth) >= 33 & (2006 - yearofbirth) <= 37
	replace c = 3 if (2014 - yearofbirth) >= 33 & (2010 - yearofbirth) <= 37
	replace c = 4 if (2020 - yearofbirth) >= 33 & (2014 - yearofbirth) <= 37
	....
	
	gen ankeryear = .
	replace ankeryear == 2003 if c = 1
	replace ankeryear == 2003 if c = 1
	...

	gen delta = (ankeryear - yearofbirth)
	bysort delta: gen cnt =_n
	keep if cnt == 1
	*/
	
	* SurveyWellen: 2002 bis 2022 alle 2 Jahre 
	* Ziel: Alter 33-37 im Ankerjahr --> Geburtsjahr = Ankerjahr-38 bis Ankerjahr-33; alle sind zum Beobachtungszeitraum zwischen 33 und 38 jahre alt


	
	

********************************************************************************
* Mean based analysis decomposition 
********************************************************************************
clear all
use $output/final.dta, clear 

gen c = .
replace c = 1 if inrange(yearofbirth, 1966, 1971)
replace c = 2 if inrange(yearofbirth, 1972, 1977)
replace c = 3 if inrange(yearofbirth, 1978, 1983)
replace c = 4 if inrange(yearofbirth, 1984, 1989)

keep if !missing(c)

* Welche Surveyjahre gehören zu welcher Kohorte
keep if (c == 1 & inrange(syear, 2002, 2006)) | ///
        (c == 2 & inrange(syear, 2008, 2012)) | ///
        (c == 3 & inrange(syear, 2014, 2018)) | ///
        (c == 4 & inrange(syear, 2020, 2022))

* nur eine observation pro person (bei mehren beobachtungszeitpunktne, wird sie der älteren beobachtungszeitpunkt zugeteilt)
bysort pid (syear): keep if _n == 1

* Check: Alter wirklich 31–40?
gen age_at_survey = syear - yearofbirth
tabstat age_at_survey, by(c) stats(min max mean)
tab syear c // 1,209      1,242      2,022      2,459 |     6,932 

	* descriptive statistics ... !!!!
	
	
* Tempfile für Haupresultate 
tempfile results
postfile pf ///
    cohort ankeryear boot_b ///
	IOP_mcs_cfa ///
	IOP_pcs_cfa ///
    R2_mcs_cfa /// 	
	R2_pcs_cfa ///	 
	var_mcs_cfa ///
	var_pcs_cfa ///
    using `results', replace

	local B 10
	
*------------------------------------------------------------------------------
* Doppelter Loop: Kohorte (äußer) × Bootstrap-Gewichte (innen)
*------------------------------------------------------------------------------
  
 forvalues k = 1/4 {
		
    preserve
    keep if c == `k'
        
    * Ankerjahr für post
    sum ankeryear
    local ayr = r(mean)

    forvalues b = 0/`B' {
		
	local curweight bweight_`b'
	
	* Gesamtvarianz
	qui sum mcs_cfa50 [aw=`curweight']
	local var_mcs_cfa = r(Var)

	qui sum pcs_cfa50 [aw=`curweight']
	local var_pcs_cfa = r(Var)

        *----------------------------------------------------------------------
        * MENTAL COMPONENT SCALE – CFA
        *----------------------------------------------------------------------
		 reg mcs_cfa50 c.age c.age#c.age i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [aw=`curweight']
		
		* absolute IOp
		capture drop mcs_cfa_hat
		predict mcs_cfa_hat , xb
		quietly summarize mcs_cfa_hat [aw=`curweight'] // @paulina 
		local IOP_mcs_cfa = r(Var)

		* relative IOp
        local R2_mcs_cfa = e(r2)
		
        *----------------------------------------------------------------------
        * PHYSICAL COMPONENT SCALE – CFA
        *----------------------------------------------------------------------
       reg pcs_cfa50 c.age c.age#c.age i.migback gender siblings ///
            i.msedu i.fsedu i.fprofstat i.mprofstat singleparent ///
            otherparent i.birthregion i.urban [aw=`curweight']
	
		* absolute IOp
		capture drop pcs_cfa_hat
		predict pcs_cfa_hat, xb
		quietly summarize pcs_cfa_hat [aw=`curweight'] // @paulina 
		local IOP_pcs_cfa = r(Var)

		* relative IOp
        local R2_pcs_cfa = e(r2)

        * Ergebnisse posten
       post pf ///
			(`k') (`ayr') (`b') ///
			(`IOP_mcs_cfa') ///
			(`IOP_pcs_cfa') ///
		    (`R2_mcs_cfa') ///
		    (`R2_pcs_cfa') ///
			(`var_mcs_cfa') ///
			(`var_pcs_cfa')	
			

    } 
    restore
} 

postclose pf

*------------------------------------------------------------------------------
* Rohergebnisse laden und speichern
*------------------------------------------------------------------------------
use `results', clear
order cohort boot_b, first
sort cohort boot_b

* Konsitenzprüfung
gen R2_check_mcs_cfa = IOP_mcs_cfa / var_mcs_cfa
gen R2_check_pcs_cfa = IOP_pcs_cfa / var_pcs_cfa
br R2_check_pcs_cfa R2_check_mcs_cfa R2_mcs_cfa R2_pcs_cfa 

save "$output/para_IOp_cohort_raw.dta", replace

*------------------------------------------------------------------------------
* CI berechnen: Perzentile aus Bootstrap-Iterationen (b>=1)
* Punktschätzer aus b=0 (Originalgewicht)
*------------------------------------------------------------------------------
use "$output/para_IOp_cohort_raw.dta", clear

* local varlist R2_mcs_orig R2_mcs_cfa R2_pcs_orig R2_pcs_cfa
local varlist var_mcs_cfa var_pcs_cfa ///
              IOP_mcs_cfa IOP_pcs_cfa ///
              R2_mcs_cfa R2_pcs_cfa
			  
*** Punktschätzer (b=0)
*preserve
    keep if boot_b == 0
    keep cohort `varlist'
    foreach v of local varlist {
        rename `v' pt_`v'
    }
    tempfile point_estimates
    save `point_estimates'
*restore

*/*** CI aus Bootstrap-Iterationen (b=1..B) – SOEP-Methode: SE-basiert
keep if boot_b >= 1

* Punktschätzer dazumergen für Abweichungsberechnung, genauer gesagt um die quadratische Abweichung der Punktschätzer von den anderen bootrapping-estimates zu berechen. aus dieses abweichungen wird dann der mittelwert (mit collapse) berechnet, die damit die varianz der Bootstrap-Iterationen ergibt 
merge m:1 cohort using `point_estimates', nogen

foreach v of local varlist {
    gen sq_dev_`v' = (`v' - pt_`v')^2
}

collapse (mean) sq_dev_* pt_* , by(cohort)

foreach v of local varlist {
    gen se_`v'    = sqrt(sq_dev_`v')
   
    gen ci_lo_`v' = pt_`v' - 1.96 * se_`v'
    gen ci_hi_`v' = pt_`v' + 1.96 * se_`v'
    drop sq_dev_`v'
}

* Wert + standard error für latex tabelle später für total variance und absolute iop 
foreach v in var_pcs_cfa var_mcs_cfa IOP_mcs_cfa IOP_pcs_cfa {
    gen out_`v' = ///
        string(pt_`v', "%9.3f") + ///
        " (" + string(se_`v', "%9.3f") + ")"
}

*/

* Wert für latex tabelle später für relative iop 
gen rel_IOP_mcs_cfa = pt_IOP_mcs_cfa/pt_var_mcs_cfa
gen rel_IOP_pcs_cfa = pt_IOP_pcs_cfa/pt_var_pcs_cfa

replace rel_IOP_mcs_cfa = rel_IOP_mcs_cfa*100
replace rel_IOP_pcs_cfa = rel_IOP_pcs_cfa*100

gen out_rel_mcs_cfa = string(rel_IOP_mcs_cfa, "%9.3f")
gen out_rel_pcs_cfa = string(rel_IOP_pcs_cfa, "%9.3f") 

sort cohort
save "$output/para_IOp_cohort.dta", replace

/* Vorbereitung für shapley decomposition: year x healthoutcome 
use "$output/para_IOp_timeseries.dta", clear
	reshape long pt_R2_, i(year) j(healthoutcome) string
	replace healthoutcome = "mcs" if healthoutcome == "mcs_orig"
	replace healthoutcome = "pcs" if healthoutcome == "pcs_orig"
save "$output/para_pt_IOp_timeseries.dta", replace
*/

*------------------------------------------------------------------------------
* Grafik 
*------------------------------------------------------------------------------
use "$output/para_IOp_cohort.dta", clear

*  R2 für PCS_CFA und MCS_CFA 
twoway ///
    (line pt_R2_mcs_cfa cohort, lpattern(line) lcolor(navy)) ///
    (line pt_R2_pcs_cfa  cohort, lpattern(line)    lcolor(maroon)), ///
    legend(order(1 "MCS" 2 "PCS") rows(1)) ///
    title("Explained Variance over Time, e.g., relative IOp") ///
    ytitle("R-squared") xtitle("Year") ///
	yscale(range(0 0.25)) ///
    ylabel(0(0.05)0.25)
	
*graph export "$output/mcs_pcs_R2.png", replace

*------------------------------------------------------------------------------
* Tabellenexport für Overleaf nur mit Punktschätzern 
*------------------------------------------------------------------------------
use $output/final_cohort.dta, clear 
rename c cohort 

* Tempfile mit Anzahl der Observationen pro Jahr für Tabelle später 
tempfile freq
	preserve
	keep cohort
	contract cohort  
	rename _freq N
	save `freq'
	restore
	
use "$output/para_IOp_cohort.dta", clear
	merge 1:1 cohort using `freq', nogen 

tsset cohort

preserve

* Datei öffnen
file open fh using "$output/Tables/table_meanbased_cohortanalysis.tex", write replace

* Header
file write fh "\begin{tabular}{lcccc}" _n
file write fh "\hline" _n
file write fh "\textbf{Cohort} & \textbf{MCS} & \textbf{PCS} & \textbf{Sample size} \\" _n
file write fh "\hline" _n

* Zeilen schreiben
forvalues i = 1/`=_N' {
    file write fh ///
        (cohort[`i']) " & " ///
		(out_rel_mcs_cfa[`i']) " & " ///
		(out_rel_pcs_cfa[`i']) " & " ///
        (N[`i']) " \\" _n
}

* Footer
file write fh "\hline" _n
file write fh "\end{tabular}" _n
file close fh

restore


********************************************************************************
* Shapley decomposition 
********************************************************************************

clear all
use $output/final_cohort.dta, clear 

/***** test anfang (für die Outcomematrix)
preserve

keep if c == 1

shapowen (c.age c.age#c.age)   i.migback gender siblings i.msedu i.fsedu ///					
	i.fprofstat i.mprofstat singleparent otherparent ///
    i.birthregion i.urban, scalar(e(r2)) : ///
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
	/*	    	r(stats) : "e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2) e(r2).."
              r(items) : "(c.age c.age#c.age)   i.migback gender siblings i.msedu i.fsedu         i.fprofstat i.mprofstat singleparent otherparen.."
                r(cmd) : "regress pcs_cfa50 @ [aw=w]"
             r(item15) : "i.urban"
             r(item14) : "i.birthregion"
             r(item13) : "otherparent"
             r(item12) : "singleparent"
             r(item11) : "i.mprofstat"
             r(item10) : "i.fprofstat"
              r(item9) : "i.fsedu"
              r(item8) : "i.msedu"
              r(item7) : "siblings"
              r(item6) : "gender"
              r(item5) : "i.migback"
              r(item4) : "c.age#c.age"
              r(item3) : "c.age"
              r(item2) : "c.age c.age#c.age"
              r(item1) : "(c.age c.age#c.age)   i.migback gender siblings i.msedu i.fsedu         i.fprofstat i.mprofstat singleparent otherparen.."	  */


*/
		  
*** loop
tempfile shapley_results
tempname memhold

postfile `memhold' ///
    cohort ankeryear healthoutcome /// 
    shap_age relshap_age ///  
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
    forvalues k = 1/4 {
        preserve
        
        keep if c == `k'
        
     * Ankerjahr für post
     sum ankeryear
     local ayr = r(mean)
	
    shapowen (c.age c.age#c.age) i.migback gender siblings i.msedu i.fsedu ///					
	i.fprofstat i.mprofstat singleparent otherparent ///
    i.birthregion i.urban, scalar(e(r2)) : ///
    regress `outcome' @ [aw=w]
	
	// absolute Shapley value
    matrix M = r(ShapOw)
	
    scalar s1  = M[2,1]   // age (group)
	scalar s2  = M[5,1]   // migback
	scalar s3  = M[6,1]   // gender
	scalar s4  = M[7,1]   // siblings
	scalar s5  = M[8,1]   // msedu
	scalar s6  = M[9,1]   // fsedu
	scalar s7  = M[10,1]  // fprofstat
	scalar s8  = M[11,1]  // mprofstat
	scalar s9  = M[12,1]  // singleparent
	scalar s10 = M[13,1]  // otherparent
	scalar s11 = M[14,1]  // birthregion
	scalar s12 = M[15,1]  // urban
	
	// relative Shapley value
	matrix M = r(relShapOw)
	
    scalar a1  = M[2,1]
    scalar a2  = M[5,1]
    scalar a3  = M[6,1]
    scalar a4  = M[7,1]
    scalar a5  = M[8,1]
    scalar a6  = M[9,1]
    scalar a7  = M[10,1]
    scalar a8  = M[11,1]
    scalar a9  = M[12,1]
    scalar a10 = M[13,1]
    scalar a11 = M[14,1]
    scalar a12 = M[15,1]

    post `memhold' ///
        (`k') (`ayr') ("`outcome'") ///
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

* Ankerjahr-Label für x-Achse
label define ayr 2004 "Kohorte 1 (1966-71)" 2010 "Kohorte 2 (1972-77)" ///
                 2016 "Kohorte 3 (1978-83)" 2022 "Kohorte 4 (1984-89)"
label values ankeryear ayr

graph bar (asis) ///
    shap_age ///
    shap_migback shap_gender shap_siblings ///
    shap_msedu shap_fsedu shap_fprofstat shap_mprofstat ///
    shap_singleparent shap_otherparent shap_birthregion shap_urban ///
    if healthoutcome == "pcs", ///
    over(ankeryear, label(angle(0) labsize(small))) ///
    stack ///
    horizontal ///
        bar(1,  color("150 150 150")) bar(2,  color("55 126 184")) ///
        bar(3,  color("107 174 214")) bar(4,  color("189 215 231")) ///
        bar(5,  color("165 0 38"))    bar(6,  color("215 48 39"))  ///
        bar(7,  color("244 109 67"))  bar(8,  color("253 190 152")) ///
        bar(9,  color("35 139 69"))   bar(10, color("116 196 118")) ///
        bar(11, color("117 107 177")) bar(12, color("188 189 220")) ///
        title("Shapley decomposition PCS") ///
        ytitle("% contribution to IOp", size(small)) ///
        legend(cols(4) size(small) region(lwidth(none)) ///
            order(1 "age" 2 "migback" 3 "gender" 4 "siblings" ///
                  5 "msedu" 6 "fsedu" 7 "fprofstat" 8 "mprofstat" ///
                  9 "singleparent" 10 "otherparent" ///
                  11 "birthregion" 12 "urban"))
    graph export "$output/Graphs/pcs_shapley_cohort.png", replace

	
graph bar (asis) ///
    shap_age ///
    shap_migback shap_gender shap_siblings ///
    shap_msedu shap_fsedu shap_fprofstat shap_mprofstat ///
    shap_singleparent shap_otherparent shap_birthregion shap_urban ///
    if healthoutcome == "mcs", ///
    over(ankeryear, label(angle(0) labsize(small))) ///
    stack ///
    horizontal ///
        bar(1,  color("150 150 150")) bar(2,  color("55 126 184")) ///
        bar(3,  color("107 174 214")) bar(4,  color("189 215 231")) ///
        bar(5,  color("165 0 38"))    bar(6,  color("215 48 39"))  ///
        bar(7,  color("244 109 67"))  bar(8,  color("253 190 152")) ///
        bar(9,  color("35 139 69"))   bar(10, color("116 196 118")) ///
        bar(11, color("117 107 177")) bar(12, color("188 189 220")) ///
        title("Shapley decomposition MCS") ///
        ytitle("% contribution to IOp", size(small)) ///
        legend(cols(4) size(small) region(lwidth(none)) ///
            order(1 "age" 2 "migback" 3 "gender" 4 "siblings" ///
                  5 "msedu" 6 "fsedu" 7 "fprofstat" 8 "mprofstat" ///
                  9 "singleparent" 10 "otherparent" ///
                  11 "birthregion" 12 "urban"))
 
	graph export "$output/Graphs/mcs_shapley_cohort.png", replace
	
	
	
	