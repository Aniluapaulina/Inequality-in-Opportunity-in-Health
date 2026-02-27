********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 1_sample_selection
***	   Description: Include sample restrictions	--> final sample selection			                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************

* use $output/base.dta, clear
use $output/base_withbw.dta , clear 

* Balance panel - keep only adults with successfull interviews 
	tab netto 
	keep if netto <= 19 & netto != -3
	drop netto

* Consider only private households (mit deutschem und ausländischem HV)
	label list pop
	tab pop
	keep if pop == 1 | pop == 2
	drop pop
	
* Sample restrictions for Health
	keep if valid == 1 // Observations every 2 years from 2002
	drop if (mcs < 0 & pcs <0 ) | (mcs <0 & pcs>0) | (mcs >0 & pcs <0 )	// 1 observation where mcs < 0 and pcs > 0
	
	* Rekonstruierung Zeitachse für IAB-Stichproben bei Sondererhebungen
	gen syear_adj = syear
	replace syear_adj = syear - 1 if inlist(syear, 2017, 2019, 2021, 2023)
	
	duplicates tag pid syear_adj, gen(dup)
	tab dup	
	drop if dup > 0 & syear_adj != syear // keeping the observations from regular sampling 
	drop syear
	rename syear_adj syear

* Sample restrictions for Circumstances 
	drop if yearofbirth == -1
	drop if gender < 0
	drop if birthregion == -2 // [trifft nicht zu]
		
	// Ci 
	tab migback, mi 					// 0
	tab siblings, mi 					// 10,213
		tab syear if siblings == . 		// ... davon 3,1921 (31%) in 2022 und 2,487 (24%) in 2002 
	tab msedu, mi						// 8,867
		tab syear  if msedu == .		// ... davon 3,903 (44%) in 2022 
	tab fsedu, mi						//  9,452
		tab syear  if fsedu == .		// ... davon 4,109 (43%) in 2022
	tab mprofstat, mi 					// 88,074
		tab syear  if mprofstat == .	// ... davon 14,417 (16%) in 2022, zwischen 7% und 16% über Jahre
	tab fprofstat, mi 					// 74,421 
		tab syear  if fprofstat == .	// ... davon 14,483 (19%) in 2022, zwischen 3% und 19% über Jahre
	tab singleparent, mi				//  86,583
		tab syear  if singleparent == .	// ... davon 10,924 (12%) in 2022 und 11,692 (13%) in 2002 
	tab otherparent, mi					//  86,683
		tab syear  if otherparent == .	// ... davon 10,922 (12%) in 2022 und 11,712 (13%) in 2002 
	tab birthregion_ew, mi 				// 0
	tab birthregion, mi					// 0 
	tab urban, mi						// 4,353  
		tab syear  if urban == .		// ... davon 2,831 (65%) in 2022

	drop if missing(siblings, msedu, fsedu, mprofstat, fprofstat, otherparent, singleparent)
	
	di _N
	tab syear
	/*			
              syear |      Freq.     Percent        Cum.
		------------+-----------------------------------
			   2002 |      8,757        6.61        6.61
			   2004 |      9,321        7.04       13.65
			   2006 |     10,218        7.72       21.37
			   2008 |      9,599        7.25       28.62
			   2010 |      9,818        7.41       36.03
			   2012 |     12,737        9.62       45.65
			   2014 |     14,299       10.80       56.45
			   2016 |     12,923        9.76       66.20
			   2018 |     15,003       11.33       77.53
			   2020 |     15,303       11.56       89.09
			   2022 |     14,449       10.91      100.00
		------------+-----------------------------------
			  Total |    132,427      100.00

	- loss of obersations in 2022 largely driven by the variables *profstat, *sedu, aber auch otherparent und singleparent
	- see 2_descriptivestatistics 
 */
 
 ** Keep the variables relevant for C_i
	keep pid syear phrf pbleib w psample mcs pcs pcs_cfa50 mcs_cfa50 ///
	yearofbirth migback_binary migback gender ///
	siblings msedu fsedu fprof7 mprof7 fprofstat mprofstat singleparent otherparent ///
	birthregion_ew birthregion urban age age2
	
	
	save $output/final.dta, replace
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	