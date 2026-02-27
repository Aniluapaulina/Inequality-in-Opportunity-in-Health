********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  	
***    Last modified: 20.02.2026											
***    Do-file: 0_master 
***	   Description: End-to-end pipeline entry point 				                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************


*-------------------------------------------------------------------------------
* SET GLOBALS 
*-------------------------------------------------------------------------------

version 14 						 
clear
set more off, permanently
set linesize 255
set seed 987654321 

global user "paulina"

* Real SOEP source paths (available for configured users)
if "${user}"=="paulina" {	
	global Data 		"C:\Users\merti\Documents\Data"
    global v40 = 		"$Data\Survey_data\soepdata"
	global v39 = 		"$Data\Survey_data\soepdatav39"
	global v40_raw = 	"$Data\Survey_data\soepdata/raw/"
	
	
	global data = "$Data\Survey_data\soepdata\"
	global output = "C:\Users\merti\OneDrive\Dokumente\Universität\FU\Masterarbeit\Output"
}


if "`c(username)'" == "dgraeber" {
    global Data    "Q:\distribution\soep-core"
    global v40     "$Data\soep.v40.1\eu\Stata\soepdata"
    global v39     "$Data\soep.v39\eu\Stata_EN\soepdata"
    global v40_raw "${v40}/raw/"
    global do_files "V:\001_research\005_iop_health\"
    global output   "V:\001_research\005_iop_health\output"
    cap mkdir "${output}"
    cap mkdir "${output}\Graphs"
}

* Pipeline mode: 0 = real SOEP cleaning, 1 = synthetic data fallback
global use_simulated = 1  // If codex is in use, rely on simulated data

* Other globals
global B = 100
global seed "12345"
global SOEPyears 2002 2007 2012 2017
				    


*-------------------------------------------------------------------------------
* INSTALLATION FILES 
*-------------------------------------------------------------------------------
global install = 0

if ${install} == 1 {
    cap noi ssc install iop, replace
    cap noi ssc install rif, replace
    cap noi ssc install ineqdeco, replace
    cap noi ssc install shapowen, replace
    cap noi ssc install estout, replace
    cap noi ssc install distinct, replace
	cap noi ssc install cfa1, replace
}


 
*-------------------------------------------------------------------------------
* RUN DO FILES 
*-------------------------------------------------------------------------------

* I. Data preparation
if ${use_simulated} == 0 {
    do "${do_files}1_cleaning.do"
}
else {
    do "${do_files}simulate_data.do"
    use "${output}/base_sim.dta", clear
    save "${output}/base.dta", replace
} 

* II. Description
	do "${do_files}2_descriptivestatistics.do" 


* III. Methodology
	* Parametric Analysis 
	do "${do_files}2_methodology_para_cross.do" 
	do "${do_files}2_methodology_para_panel.do" 
	
	* Semi-Parametric Analysis 
	do "${do_files}2_methodology_semipara_cross.do" 
	do "${do_files}2_methodology_semipara_panel.do" 
	
	* Non-Parametric Analysis 
	*do "${do_files}2_methodology_nonpara.do" 


* III. Graphs and tables
	
 
 
 
di as res "Pipeline completed successfully."

 
 
 
 
 
 
 
 
 
 
 
 
 
 
