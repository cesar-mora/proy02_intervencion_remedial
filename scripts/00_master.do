/*------------------------------------------------------------------
  Construcción del indicador de necesidad de atención
-------------------------------------------------------------------*/

// Seleccionar acciones --------------------------------------------------------

	local limpiar_data				0 // Corre script de limpieza de datos
	local construir_data	      	0 // Corre script de construcción de base de datos
	local focalizacion				1 // Realiza la focalización
	local PxQ_remedial_tarl			1 // Exporta PxQ de intervención TaRL
	local PxQ_remedial_conectaideas	0 // Exporta PxQ de intervención ConectaIdeas

// Rutas de Usuario ------------------------------------------------------------
    dis        	"`c(username)'"
    global     	who "`c(username)'"
	
	*Minedu

	* Analista UP18		
	if "$who" == "analistaup18" {
	global proyecto "B:\OneDrive - Ministerio de Educación\unidad_B\2022\1. Estudios Data\proy02_intervencion_remedial"
	global github "C:\Users\ANALISTAUP18\Documents\GitHub\proy02_intervencion_remedial"
	}
	
	* Brandon PC
	if "$who" == "bran" {
	global proyecto "/Users/bran/Documents/GitHub/intervencion_remedial"
	global github "/Users/bran/Documents/GitHub/intervencion_remedial"
	}
	
// Globales de carpetas --------------------------------------------------------


	global scripts			"$github/scripts"
	global clean			"$proyecto/data/clean"
	global raw				"$proyecto/data/raw"
	global output			"$proyecto/output"
   
	set more off, permanent  	

// Elegir estrategias de focalización ------------------------------------------

	** Estrategias de refuerzo coordinadas con DIGBR
		
			**** Intervención 14_07
			global foc_digbr_eje03		1
	
		*** Estrategias focalizando al total de alumnos
		
			**** Intervención global
			global foc_digbr_global		0
			
			**** Intervención con indicador > 0.90
			global foc_digbr_90			0

	
		** Estrategia con techo MEF	
		global foc_estrategia_mef_12_09	0
		
// Correr código ---------------------------------------------------------------	

* Limpiar, unir bases de datos y crear variables de interés
if (`limpiar_data' == 1) {
	do "$scripts/01_cleandata.do"			
}

* Crear indicadores de necesidad de atención
if (`construir_data' == 1) {
	do "$scripts/02_construir_data.do"		
}

*------------------------------------------------------------------
* Generar focalización
if (`focalizacion' == 1) {
	do "$scripts/03_focalizacion.do"		
}

*------------------------------------------------------------------
* Generar PxQ - TaRL
if (`PxQ_remedial_tarl' == 1) {
	do "$scripts/04_PxQ_remedial_tarl.do"		
}

*------------------------------------------------------------------
* Generar PxQ - ConectaIdeas (en construcción)
if (`PxQ_remedial_conectaideas' == 1) {
	do "$scripts/05_PxQ_remedial_conectaideas.do"		
}

*-------------------------------------------------------------------*

* Generar imputación basado en distancia

* Se realiza en Python abriendo el archivo "$scripts/06_imputacion_ece.py"
