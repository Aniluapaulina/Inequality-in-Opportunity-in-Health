* Description: Decriptive Statistics 

clear all
use $output/base.dta, clear 

xtset pid syear
count

distinct pid 
// Anzahl der befragen Personen 

bys pid: egen n_waves = count(syear)
tab n_waves
// Anzahl der Beobachtungszeiträume (Wellen) für die Individuen 

*-------------------------------------------------------------------------------
*  Sample Decomposition 
*------------------------------------------------------------------------------

*** Unconditional Distribution of Health outcomes 
tempfile results
postfile handle int year str3 var double mean sd N using `results', replace

forvalues yr = 2002(2)2022 {
    foreach var in mcs pcs pcs_cfa50 mcs_cfa50 {

        quietly summarize `var' [fw=w] if syear == `yr'
		/* quietly summarize `var' if syear == `yr' */

        post handle ///
            (`yr') ///
            ("`var'") ///
            (r(mean)) ///
            (r(sd)) ///
			(r(N)/1000000) // Angaben in Mio
			/* (r(N)) */
    }
}

postclose handle
	preserve
	use `results', clear
	list
	restore 

	
*** Unconditional Distribution of Circumstances

forvalues yr = 2002(2)2022 {
    foreach var in migback birthregion birthregion_ew siblings age ///
                   migback_binary fsedu fprofstat singleparent ///
                   otherparent urban {

        preserve
        keep if syear == `yr'

        * Summe pro Kategorie
        collapse (sum) w, by(`var')

        * Gesamtsumme der Gewichte im Jahr
        egen total_w = total(w)

        * Populationsanteil
        gen share = w / total_w

        * Graph
        graph bar share, over(`var') ///
            ytitle("Population share") ///
            title("`var' – `yr'") ///
            blabel(bar, format(%4.2f))

        graph export "$output\Graphs\graph_`var'_`yr'.png", replace

        restore
    }
}

	/*
	- age: (bysort syear: su age) Durchschnittsalter sinkt von 70 Jahren in 2002 auf 50 Jahre in 2022
	- migback: Anteil non-migback sinkt (nachvollziehbarer Weise) von 85% in 2002 auf 75% in 2022
	- fprofstat und fsedu: 
	- otherparent: Anteil otherparent steigt von 6% in 2002 auf % in 2022 
	- singleparent: 
	
	
	
	*/
	

	
*** Conditional Distribution of Health outcomes 














* Numerical variables
estpost summarize  ///
    mcs pcs siblings [fw = w]
	
esttab using "$output/table1_numerical.tex", ///
    cells("mean(fmt(2)) sd(fmt(2))") ///
    label ///
    noobs ///
    replace ///
	tex
	

* Kategorical variables 
foreach v in gender msedu fsedu fprofstat mprofstat urban migback birthregion birthregion_ew migback singleparent otherparent {
    qui estpost tabulate `v' [fw = w]

    esttab using "$output/table1_`v'.tex", ///
        cells("pct(fmt(2))") ///
        label ///
        noobs ///
        nomtitles ///
        nonumber ///
        replace ///
        tex
}



	





















* Scales & age 
// Combining age, cohort and year effects 

twoway (scatter mcs age, mcolor(%30) msymbol(o) msize(small)) ///
       (lfit mcs age, lcolor(blue) lwidth(medthick)) 
		
twoway (scatter pcs age, mcolor(%30) msymbol(o) msize(small)) ///
       (lfit pcs age, lcolor(blue) lwidth(medthick)) 


* There differences in the magnitude of socioeconomic health inequalities across age groups
	* Further looking at HOW THOSE PATTERNS (Realtionship between health and age) differer by SES, measure of health, gender





