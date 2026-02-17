********************************************************************************
***    Authors: Paulina Mertinkat  						                             	  		
***    Last modified: 07.12.2025											
***    Do-file: 0_master 
***	   Description: Baseline do-file  				                                     	
***    Project: "IOP in helth in Germany" 
********************************************************************************


*-------------------------------------------------------------------------------
* SET GLOBALS 
*-------------------------------------------------------------------------------
global user "paulina"

if "${user}"=="paulina" {	
	global Data 		"C:\Users\merti\Documents\Data"
    global v40 = 		"$Data\Survey_data\soepdata"
	global v39 = 		"$Data\Survey_data\soepdatav39"
	global v40_raw = 	"$Data\Survey_data\soepdata/raw/"
	
	
	global data = "$Data\Survey_data\soepdata\"
	global output = "C:\Users\merti\OneDrive\Dokumente\Universität\FU\Masterarbeit\Output"
}


// Bootstrapping 
global B = 100

global SOEPyears 2002 2007 2012 2017

* Kleinere Anpassungen
version 14 						 
clear
set more off, permanently
set linesize 255
set seed 987654321 				    


*-------------------------------------------------------------------------------
* INSTALLATION FILES 
*-------------------------------------------------------------------------------
global install=0
 
if ${install}==1 {
	
	ssc install iop
	ssc install rif
	ssc install ineqdeco
	// This routine implements different methodologies to compute ex-ante inequality of opportunity for binary, ordered and continuous variables. 
}

*** Ado-files 
* dm88_1/renvars.ado  for the function runvars
* st0438/xtrifreg.ado



 
*-------------------------------------------------------------------------------
* RUN DO FILES 
*-------------------------------------------------------------------------------

* I. Data preparation
	do "${do_files}1_importcleaning.do" 

* II. Methodology
	* Parametric Analysis 
	do "${do_files}2_methodology_para_cross.do" 
	do "${do_files}2_methodology_para_panel.do" 
	
	* Semi-Parametric Analysis 
	do "${do_files}2_methodology_semipara_cross.do" 
	do "${do_files}2_methodology_semipara_panel.do" 
	
	* Non-Parametric Analysis 
	*do "${do_files}2_methodology_nonpara.do" 


* III. Graphs and tables
	
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
