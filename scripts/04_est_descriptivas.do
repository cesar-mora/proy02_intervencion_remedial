********************************************************************************
* 04: Estadisticas descriptivas
* Objetivo: El do-file 

* INPUT
* Datos con focalizacion			"$clean/data_focalizacion.dta"
* OUTPUT
* Tablas excel
********************************************************************************

use 	"$clean/data_focalizacion.dta", clear


* Mantener y generar IIEE cubiertas
*----------------------------------

* Mantenemos primaria
*keep if d_niv_mod == "Primaria"

tab area_21 targeted1, missing


* Generamos IIEE cubiertas por algún acompañamiento
gen cubiertas = 1 if acompanatic == 1 | acomp_pedagogico == 1 | targeted1 == 1


* Tabla resumen 1 cobertura)
*----------------------------------

* Generamos tabla resumen 1 (cobertura)
collapse 	(sum) n_ie  targeted1 acompanatic acomp_pedagogico cubiertas ///
			(mean) indicador_atencion, by(d_niv_mod eib d_cod_car)
			
export excel "$output/tabla_resumen_1.xlsx", sheet ("tabla_resumen_1") replace firstrow(variables) locale(es)


* Generamos promedios de indicador de necesidad de atención
use 	"$clean/data_focalizacion.dta", clear
keep if d_niv_mod == "Primaria"

* EIB
sum indicador_atencion if eib == 0
sum indicador_atencion if eib == 1 & d_cod_car == "Unidocente"
sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Multigrado"
sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Completo" & dareacenso == "Rural"
sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Completo" & dareacenso == "Urbana"
sum indicador_atencion if eib == 1 & d_cod_car == "No disponible"


* EIB
sum indicador_atencion if eib == 0 & targeted1 == 1
sum indicador_atencion if eib == 1 & d_cod_car == "Unidocente" & targeted1 == 1
sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Multigrado" & targeted1 == 1
sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Completo" & dareacenso == "Rural" & targeted1 == 1
sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Completo" & dareacenso == "Urbana" & targeted1 == 1
sum indicador_atencion if eib == 1 & d_cod_car == "No disponible" & targeted1 == 1


* Tabla resumen 2 (estadisticas descriptivas)
*----------------------------------

use 	"$clean/data_focalizacion.dta", clear
keep if d_niv_mod == "Primaria"
keep if targeted1 == 1

collapse 	(sum)   alumnos_focalizados docente_remedial, by(dareacenso eib d_cod_car)


* Colapsar a nivel UE
*collapse 	(sum) n_ie  n_mentor docentes_total recup_prim_tercero ///
*			(mean) indicador_atencion, by(dareacenso  eib d_cod_car)

*export excel "$output/tabla_resumen_2.xlsx", sheet ("tabla_resumen_2") replace firstrow(variables) locale(es)




* Tabla resumen 2 (estadisticas descriptivas)
*----------------------------------
*use 	"$clean/data_focalizacion.dta", clear

*keep if d_niv_mod == "Primaria"
*keep if targeted1 == 1

* Colapsar a nivel UGEL - Contratación de mentores se realiza a nivel UGEL
*collapse 	(sum) n_ie docentes_total recup_prim_tercero ///
*			(mean) indicador_atencion, by(codooii)

*gen n_mentor = ceil(docentes_total/4) // Mentor

		
* Estadisticos de cobertura para targeted 1 (en proceso)
*use 	"$clean/data_focalizacion.dta", clear
*keep if d_niv_mod == "Primaria"
*
*collapse 	(sum) n_ie targeted1 recibe_acomp  ///
*			(mean) indicador_atencion, by(eib d_cod_car )
