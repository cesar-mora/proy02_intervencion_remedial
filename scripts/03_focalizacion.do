********************************************************************************
* 03: Focalización
* Objetivo: El do-file realiza la focalización de TaRL.

* INPUT

* Datos con indicador necesidad		"$clean/data_construida.dta"

* OUTPUT

* Datos con focalizacion			"$clean/data_focalizacion.dta"

********************************************************************************

use 	"$clean/data_construida.dta", replace

** Generar indicador de necesidad de atención
*--------------------------------------------

* Generamos indicador de atención único - primaria y secundaria están divididas por cod_mod
egen indicador_atencion = rowlast(indicador_atencion_prim indicador_atencion_sec)

* Generamos indicador de ece lenguaje
egen ece_lenguaje = rowlast(ind_leng_ece_primaria ind_leng_ece_secundaria)

* Eliminamos indicadores de atención individuales
drop indicador_atencion_prim indicador_atencion_sec

** Generar focalización
*--------------------------------------------

* Escenario 1
gen targeted1=0
replace targeted1=1 if indicador_atencion>=0.61 & eib == 1

* Escenario 2
gen targeted2=0
replace targeted2=1 if indicador_atencion>=0.85 & eib == 1

* Escenario 3
gen targeted3=0
replace targeted3=1 if indicador_atencion>=0.90 & eib == 1


** Generar focalización de alumnos
*--------------------------------------------

* Focalización primero a tercero
*local	grado_focalizado_total 		mat_total_primero mat_total_segundo mat_total_tercero
*local	grado_focalizado_remedial 	mat_recup_primero mat_recup_segundo mat_recup_tercero

* Focalización cuarto a sexto
local	grado_focalizado_total 		mat_total_cuarto mat_total_quinto mat_total_sexto
local	grado_focalizado_remedial 	mat_recup_cuarto mat_recup_quinto mat_recup_sexto

* Focalización primero a sexto
*local	grado_focalizado_total 		mat_total_primero mat_total_segundo mat_total_tercero mat_total_cuarto mat_total_quinto mat_total_sexto
*local	grado_focalizado_remedial 	mat_recup_cuarto mat_recup_quinto mat_recup_sexto mat_recup_cuarto mat_recup_quinto mat_recup_sexto

* Generamos total de alumnos en grados seleccionados
egen alumno_grado_total = rowtotal(`grado_focalizado_total'), missing

* Generamos total de alumnos remediales en primero-tercero
egen alumno_grado_remedial = rowtotal(`grado_focalizado_remedial'), missing

* Generamos proporción guiada para alumnos en grados focalizados
gen proporcion_guiada_foc = alumno_grado_remedial/alumno_grado_total

* Generamos proporcion de alumnos que se encuentran bajos en ece_lenguaje
* y en IEE donde haya una proporción guiada menor a 0.15

gen alum_ece = ceil(ece_lenguaje*alumno_grado_total) if proporcion_guiada_foc < 0.15  

* Generamos número de alumos focalizados
egen alumnos_focalizados = rowmax(alum_ece alumno_grado_remedial)

** Generar número de docentes remediales requeridos
*--------------------------------------------
gen docente_remedial = ceil(alumnos_focalizados/20)

* Generamos 2 docentes para IIEEs polidocentes completas (solo en focalización primero a sexto)
*replace docente_remedial = 2 if docente_remedial==1 & d_cod_car == "Polidocente Completo"

* considerando los alumnos focalizados.
* en IIEE polidocente completo: (min 2 para 1ro a 6to)

** Eliminamos variables intermedias y agregamos label
*--------------------------------------------

drop alumno_grado_total alumno_grado_remedial proporcion_guiada_foc alum_ece
* Agregamos label a indicador
label variable indicador_atencion	"Indicador de necesidad de atención"
label variable targeted1			"Focalizacion Escenario 1"
label variable targeted2			"Focalizacion Escenario 2"
label variable targeted3			"Focalizacion Escenario 3"
label variable docente_remedial		"Número de docentes remediales requeridos"
label variable alumnos_focalizados	"Número de alumnos focalizados"

save 	"$clean/data_focalizacion.dta", replace
