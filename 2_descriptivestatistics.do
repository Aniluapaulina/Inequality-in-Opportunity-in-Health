********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 23.02.2025											
***    Do-file: 1_cleaning
***	   Description: Decriptive Statistics 			                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************

clear all
use $output/final.dta, clear 

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
		/* quietly summarize `var' if syear == `yr' */ // ungewichtet 

        post handle ///
            (`yr') ///
            ("`var'") ///
            (r(mean)) ///
            (r(sd)) ///
			(r(N)/1000000) // Angaben in Mio
			/* (r(N)) */
		
		hist `var' [fw=w] if syear == `yr'
		graph export "$output\Graphs\graph_`var'_`yr'.png", replace
			
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
	- migback: Anteil non-migback sinkt (nachvollziehbarer Weise) von 85% auf 75% 
	- fprofstat: Anteil bluecollar sinkt von 47% auf 36% 
	- fprofstat: Anteil nichtarbeitend sinkt von 49% auf 38% während Dienstleistungs- & einfache Angestellte von 18% auf 29% steigt
	- fsedu:Anteil Secondary steigt von 50% auf 62% während Upper secondary von 20 auf 12% sinkt
	- msedu: Anteil Secondary sinkt von 66% auf 50% während Upper secondary (und Intermediate) steigen von 6(14) auf 14(24)
	- otherparent: Anteil sinkt leicht von 4% auf 3% 
	- singleparent: Anteil steigt von 14%  auf 16% 
	- urban: vergleichbar 
	- siblings: vergleichbar 
	*/
	













