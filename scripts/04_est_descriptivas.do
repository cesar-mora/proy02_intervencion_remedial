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

* Mantenemos a IIEE focalizadas
keep if targeted1 == 1

* Generamos IIEE cubiertas por algún acompañamiento
gen cubiertas = 1 if acompanatic == 1 | acomp_pedagogico == 1 | targeted1 == 1

* Tabla resumen 1 cobertura)
*----------------------------------

* Generamos tabla resumen 1 (cobertura)
collapse 	(sum) n_ie  targeted1 acompanatic acomp_pedagogico cubiertas alumnos_focalizados ///
			(mean) indicador_atencion, by(d_niv_mod eib d_cod_car)
			
export excel "$output/tabla_resumen_1.xlsx", sheet ("tabla_resumen_1") replace firstrow(variables) locale(es)


* Generamos promedios de indicador de necesidad de atención
*use 	"$clean/data_focalizacion.dta", clear
*keep if d_niv_mod == "Primaria"

*keep if targeted1 == 1

* EIB
*sum indicador_atencion if eib == 0
*sum indicador_atencion if eib == 1 & d_cod_car == "Unidocente"
*sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Multigrado"
*sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Completo" & dareacenso == "Rural"
*sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Completo" & dareacenso == "Urbana"
*sum indicador_atencion if eib == 1 & d_cod_car == "No disponible"


* EIB
*sum indicador_atencion if eib == 0 & targeted1 == 1
*sum indicador_atencion if eib == 1 & d_cod_car == "Unidocente" & targeted1 == 1
*sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Multigrado" & targeted1 == 1
*sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Completo" & dareacenso == "Rural" & targeted1 == 1
*sum indicador_atencion if eib == 1 & d_cod_car == "Polidocente Completo" & dareacenso == "Urbana" & targeted1 == 1
*sum indicador_atencion if eib == 1 & d_cod_car == "No disponible" & targeted1 == 1
