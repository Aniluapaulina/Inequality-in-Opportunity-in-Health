********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  	
***    Last modified: 20.02.2026											
***    Do-file: simulate_data 
***	   Description: Synthetic data fallback point 				                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************

* Input from ChatGPT: reproduce SOEP structure and joint distributions

clear all
set more off
set seed 12345

*******************************************************
* STEP 1: Define the number of observations per year
*******************************************************
* This ensures the dataset matches exactly the frequencies you provided.

input syear N
2002  9115
2004  9698
2006 10646
2008  9985
2010 10271
2012 13346
2014 16305
2016 14639
2018 16782
2020 15460
2022  9397
end

* Expand dataset to match the frequencies
expand N
drop N
sort syear

* Check frequencies
tab syear

*******************************************************
* STEP 2: Create synthetic individual IDs (pid)
*******************************************************
* Here we assume ~40,000 unique individuals, repeated across years.
* This creates a realistic unbalanced panel structure.

local maxpid = 40000
gen pid = ceil(runiform()*`maxpid')
sort pid syear

*******************************************************
* STEP 3: Generate time-invariant individual variables
*******************************************************

* Year of birth and age
bys pid: gen yearofbirth = floor(runiform()*50) + 1940
bys pid: replace yearofbirth = yearofbirth[1]
gen age = syear - yearofbirth
gen age2 = age^2

* Gender (1=Male, 0=Female)
bys pid: gen gender = (runiform() < 0.51)
bys pid: replace gender = gender[1]

* Migration background (binary)
bys pid: gen migback_binary = (runiform() < 0.25)
bys pid: replace migback_binary = migback_binary[1]

* Number of siblings
bys pid: gen siblings = rpoisson(1.5)
bys pid: replace siblings = min(siblings,6)

* Education of mother/father (1-6)
bys pid: gen msedu = ceil(runiform()*6)
bys pid: gen fsedu = ceil(runiform()*6)

* Profession of mother/father (1-12)
bys pid: gen mprofstat = ceil(runiform()*12)
bys pid: gen fprofstat = ceil(runiform()*12)

* Family structure
bys pid: gen singleparent = (runiform()<0.15)
bys pid: gen otherparent  = (runiform()<0.05)

* Birth region East/West (1=East, 0=West)
bys pid: gen birthregion_ew = (runiform()<0.8)

* Urbanicity (1-3)
bys pid: gen urban = ceil(runiform()*3)

*******************************************************
* STEP 4: Generate outcomes with individual heterogeneity
*******************************************************

* Individual random effect
gen u_i = rnormal(0,4)
bys pid: replace u_i = u_i[1]

* Outcome noise
gen eps = rnormal(0,8)

* Mental Component Score (MCS)
gen mcs = 50 ///
    - 0.04*age ///
    + 1.2*gender ///
    - 1.8*migback_binary ///
    - 0.3*siblings ///
    + 0.8*(msedu>=4) ///
    + 0.8*(fsedu>=4) ///
    - 1.2*singleparent ///
    + u_i + eps

* Physical Component Score (PCS)
gen pcs = 50 ///
    - 0.08*age ///
    + 0.5*gender ///
    - 1.0*migback_binary ///
    - 0.2*siblings ///
    + u_i + rnormal(0,8)

* Optional: binary outcomes
gen mcs_binary = mcs >= 50
gen pcs_binary = pcs >= 50

* Optional: add small noise for CFA simulations
gen mcs_cfa50 = mcs + rnormal(0,2)
gen pcs_cfa50 = pcs + rnormal(0,2)

*******************************************************
* STEP 5: Generate weights and bootstrap weights
*******************************************************
gen w = runiform()*1.5 + 0.5   // survey weight example

local B = 100
forvalues b=1/`B' {
    gen bweight_`b' = w*(1+rnormal(0,0.05))
}

*******************************************************
* STEP 6: Finalize dataset
*******************************************************
order pid syear
sort pid syear

* Save dataset
save "$output/base_sim.dta", replace

* Optional: Check summary
summarize
tab pid, sort
tab syear