/*------------------------------------------------------------------
  Construcción del indicador de necesidad de atención
-------------------------------------------------------------------*/
	
* Definir Usuarios
* --------------------

*Número de usuario:
* PC Analista UP 18			1
* Brandon Casa 				2
* 						    3

*Establecer este valor para el usuario que actualmente usa el script
global user  1
	
* Definir Globales
* ---------------------

* Usuario 1
if $user == 1 {
       global proyecto 		"B:/OneDrive - Ministerio de Educación/unidad_B/2022/1. Estudios Data/proy02_intervencion_remedial"
}
* Usuario 2
if $user == 2 {
       global proyecto 		"/Users/bran/Documents/GitHub/intervencion_remedial"
}

	* Globales
	global scripts			"$proyecto/scripts"
	global clean			"$proyecto/data/clean"
	global raw				"$proyecto/data/raw"
	global output			"$proyecto/output"
   
	set more off, permanent  	

/*------------------------------------------------------------------
  Do-Files
-------------------------------------------------------------------*/


*------------------------------------------------------------------
* Limpiar, unir bases de datos y crear variables de interés

if (1) {
	do "$scripts/01_cleandata.do"			// Limpia bases de datos
}

* INPUT

* Padrón web de IIEE			"$raw/Padron_web.dta"
* Padrón de acompañamientos		"$raw/Base_padrones_2022.xlsx"
*								"$raw/Padron IIEE AP_2022_caracterización_12JULIO.xlsx"
*								"$raw/Padron_propuesto_polidocente.xls"
* Base SIAGIE					"$raw/prima_sec_promocionguiada.dta"
* Base integrada UPP			"$raw/Padron2020VMJPT210615-Tarde.dta"
* Base de datos Nexus			"$raw/Nexus por cod_mod.dta"
* Base de datos ECE EIB			"$raw/IE 4P EIB ECE 15-18.xlsx"

* OUTPUT

* Base de datos limpia			"$clean/data_clean.dta"
*-------------------------------------------------------------------*



*------------------------------------------------------------------
* Crear indicadores de necesidad de atención

if (1) {
	do "$scripts/02_construir_data.do"		
}

* INPUT

* Valores ECE imputados			"$raw/imputacion_ece_primaria.csv""
*								"$raw/imputacion_ece_secundaria.csv"
*								"$raw/imputacion_ece_eib.csv"

* OUTPUT

* Base construida				"$clean/data_construida.dta"
* Indicador de necesidad		"$output/indicador_atencion.dta"
*								"$output/indicador_atencion.xlsx"
*-------------------------------------------------------------------*


*------------------------------------------------------------------
* Generar focalización

if (1) {
	do "$scripts/03_focalizacion.do"		
}

*-------------------------------------------------------------------*


*------------------------------------------------------------------
* Generar estadisticas descriptivas

if (1) {
	do "$scripts/04_est_descriptivas.do"		
}

*-------------------------------------------------------------------*


*------------------------------------------------------------------
* Generar PxQ

if (1) {
	do "$scripts/05_PxQ_remedial_tarl.do"		
}

*-------------------------------------------------------------------*

* Generar imputación basado en distancia

* Se realiza en Python abriendo el archivo "$scripts/06_imputacion_ece.py"
