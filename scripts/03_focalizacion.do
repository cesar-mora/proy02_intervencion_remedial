********************************************************************************
* 03: Focalización
* Objetivo: El do-file realiza la focalización de TaRL.

* INPUT
* Datos con indicador necesidad		"$clean/data_construida.dta"

* OUTPUT
* Datos con focalizacion			"$clean/data_focalizacion.dta"

********************************************************************************

use 	"$clean/data_construida.dta", replace

* Generamos indicador de ece lenguaje
 *egen ece_lenguaje = rowlast(ind_leng_ece_primaria ind_leng_ece_secundaria)

** Generar focalización
*--------------------------------------------

* Focalización TaRL (se eligen en master do file)
***********

if ( $foc_digbr_eje03 == 1) {
global foc foc_digbr_eje03
gen targeted1=0
* Target primaria
replace targeted1=1 if indicador_atencion>=0.81 & d_niv_mod == "Primaria" 
* Target secundaria
replace targeted1=1 if indicador_atencion>=0.898 & d_niv_mod == "Secundaria"
* Focalización intercalado segundo, cuarto y sexto.
local	grado_focalizado_total 	mat_total_segundo_prim mat_total_cuarto_prim mat_total_primero_sec mat_total_tercero_sec
local	grado_focalizado_recup 	mat_recup_segundo_prim mat_recup_cuarto_prim  mat_recup_primero_sec mat_recup_primero_sec 

}

if ( $foc_digbr_global == 1) {
global foc foc_digbr_global
* Escenario Total (2022)
gen targeted1=0
replace targeted1=1 if (d_niv_mod == "Primaria" | d_niv_mod == "Secundaria")
* Focalización intercalado segundo, cuarto y sexto.
local	grado_focalizado_total 	mat_total_segundo_prim mat_total_cuarto_prim mat_total_sexto_prim mat_total_segundo_sec mat_total_tercero_sec mat_total_quinto_sec
local	grado_focalizado_recup 	mat_recup_segundo_prim mat_recup_cuarto_prim mat_recup_sexto_prim mat_recup_segundo_sec mat_recup_tercero_sec mat_recup_quinto_sec

}

if ( $foc_digbr_90 == 1) {
global foc foc_digbr_90
* Escenario Total (2022)
gen targeted1=0
replace targeted1=1 if indicador_atencion>=0.9 & (d_niv_mod == "Primaria" | d_niv_mod == "Secundaria")
* Focalización intercalado segundo, cuarto y sexto.
local	grado_focalizado_total 	mat_total_segundo_prim mat_total_cuarto_prim mat_total_sexto_prim mat_total_segundo_sec mat_total_tercero_sec mat_total_quinto_sec
local	grado_focalizado_recup 	mat_recup_segundo_prim mat_recup_cuarto_prim mat_recup_sexto_prim mat_recup_segundo_sec mat_recup_tercero_sec mat_recup_quinto_sec
}


if ( $foc_estrategia_mef_12_09 == 1) {
global foc foc_estrategia_mef_12_09

* Escenario 1 (2022)
 gen targeted1=0
 replace targeted1=1 if indicador_atencion>=0.77 & eib != 1 & d_niv_mod == "Primaria" 
* Focalización en primero, segundo y tercero
local	grado_focalizado_total mat_total_primero mat_total_segundo mat_total_tercero
}

** Otros escenarios:

* Escenario 1 (2022)
* gen targeted1=0
* replace targeted1=1 if indicador_atencion>=0.77 & eib != 1 & d_niv_mod == "Primaria" 

* Target 2023 (todos los considerados el 2022 + 20% de IIEE
*gen targeted1=0
*replace targeted1=1 if indicador_atencion>=0.57 & eib == 0
*keep if targeted1== 1
* End Target 2023
	
* Target 2024 (promoción 2023)
*drop if eib == 1
*drop if indicador_atencion < 0.57
*drop if indicador_atencion > 0.61
*gen targeted1 = 1
* End target 2024
	
* Target 2024 (promoción 2024)
*drop if eib == 1
*drop if indicador_atencion >= 0.57
*drop if indicador_atencion < 0.42
*gen targeted1 = 1
* End target 2024 (promoción 2024)


** Generar focalización de alumnos
*--------------------------------------------

* Escenario 1 (2022)

* Generamos total de alumnos en grados seleccionados
egen alumno_grado_total = rowtotal(`grado_focalizado_total'), missing
egen alumno_grado_recup = rowtotal(`grado_focalizado_recup'), missing

*Generamos total de alumnos remediales grandos seleccionados
*egen alumno_grado_remedial = rowtotal(`grado_focalizado_remedial'), missing

* Generamos proporción guiada para alumnos en grados focalizados
*gen proporcion_guiada_foc = alumno_grado_remedial/alumno_grado_total

* Generamos proporcion de alumnos que se encuentran bajos en ece_lenguaje
* y en IEE donde haya una proporción guiada menor a 0.15
*gen alum_ece = ceil(ece_lenguaje*alumno_grado_total) if proporcion_guiada_foc < 0.15  

* Generamos número de alumos focalizados
*egen alumnos_focalizados = rowmax(alum_ece alumno_grado_remedial)

** Generar número de docentes remediales requeridos
*--------------------------------------------
gen docente_remedial = ceil(alumno_grado_total/15)

* Generamos 2 docentes para IIEEs polidocentes completas (solo en focalización primero a sexto)
*replace docente_remedial = 2 if docente_remedial==1 & d_cod_car == "Polidocente Completo"

* considerando los alumnos focalizados.
* en IIEE polidocente completo: (min 2 para 1ro a 6to)

** Eliminamos variables intermedias y agregamos label
*--------------------------------------------

*drop alumno_grado_total alumno_grado_remedial proporcion_guiada_foc alum_ece
* Agregamos label a indicador
label variable indicador_atencion	"Indicador de necesidad de atención"
label variable targeted1			"Focalizacion Escenario 1"
label variable docente_remedial		"Número de docentes remediales requeridos"
label variable alumno_grado_recup	"Número de alumnos focalizados (en recuperacion)"
label variable alumno_grado_total	"Número de alumnos focalizados (total)"

save 	"$clean/data_focalizacion_$foc.dta", replace

