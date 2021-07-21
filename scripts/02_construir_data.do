********************************************************************************
* 02: Construir data
* Objetivo: El do-file combina la base de datos limpia con los valores imputados
* para la ECE y genera información el indicador de necesidad de atención.

* INPUT

* Valores ECE imputados			"$raw/imputacion_ece_primaria.csv""
*								"$raw/imputacion_ece_secundaria.csv"
*								"$raw/imputacion_ece_eib.csv"

* OUTPUT

* Base construida				"$clean/data_construida.dta"
* Indicador de necesidad		"$output/indicador_atencion.dta"
*								"$output/indicador_atencion.xlsx"

********************************************************************************

** Parte 1) Añadimos valores ECE imputados a base limpia

** Añadir indicador ECE imputado - generado con script 04.imputacion_ece.py
*----------------------

* Importamos ECE imputado a nivel primaria
import delimited "$raw/imputacion_ece_primaria.csv", clear 
drop v1
tostring cod_mod, replace
replace cod_mod =  "0"*(8-length(cod_mod))+cod_mod
tempfile 	imputacion_ece_primaria
save 		`imputacion_ece_primaria'

* Importamos ECE imputado a nivel secundaria
import delimited "$raw/imputacion_ece_secundaria.csv", clear 
drop v1
tostring cod_mod, replace
replace cod_mod =  "0"*(8-length(cod_mod))+cod_mod
tempfile 	imputacion_ece_secundaria
save 		`imputacion_ece_secundaria'

* Importamos ECE imputado a nivel EIB (no se considera por ser pocas observaciones)
*import delimited "$raw/imputacion_ece_eib.csv", clear 
*drop v1
*tostring cod_mod, replace
*replace cod_mod =  "0"*(7-length(cod_mod))+cod_mod
*bysort cod_mod: gen anexo = _n - 1
*tostring anexo, replace
*tempfile 	imputacion_ece_eib
*save 		`imputacion_ece_eib'


use "$clean/data_clean.dta", replace

merge 1:1 cod_mod_anexo  using `imputacion_ece_primaria', nogen


*    Result                           # of obs.
*    -----------------------------------------
*    not matched                        48,895
*        from master                    48,895  
*        from using                          0  
*
*    matched                            15,742  
*    -----------------------------------------


merge 1:1 cod_mod_anexo  using `imputacion_ece_secundaria', nogen


*    Result                           # of obs.
*    -----------------------------------------
*    not matched                        63,987
*        from master                    63,987  
*        from using                          0  
*
*    matched                               650  
*    -----------------------------------------

** Parte 2) Generamos Indicadores de necesidad de atención

** Generar indicadores de necesidad de atención
*----------------------

* Combinamos indicadores lenguaje y matematica imputados en una sola variable
egen ind_leng_ece_primaria = rowlast(ind_lenguaje_ece_prim ind_leng_prim_imp) 
egen ind_mat_ece_primaria = rowlast (ind_mate_ece_prim ind_mate_prim_imp)

egen ind_leng_ece_secundaria = rowlast(ind_lenguaje_ece_sec ind_leng_sec_imp) 
egen ind_mat_ece_secundaria = rowlast (ind_mate_ece_sec ind_mate_sec_imp)

* Generamos indicador de necesidad de atención primaria
gen indicador_atencion_prim = ind_leng_ece_primaria*0.4 + ind_mat_ece_primaria*0.4 + proporcion_guiada_ie*0.2 

* Generamos indicador de necesidad de atención secundaria
gen indicador_atencion_sec = ind_leng_ece_secundaria*0.4 + ind_mat_ece_secundaria*0.4 + proporcion_guiada_ie*0.2 


** Generar indicadores de necesidad EIB
*----------------------

* Combinamos indicadores imputados en una sola variable
*egen indi_eib_lengua1 = rowlast(ind_eib_lengua1 ind_eib_lengua1_imputado)
*egen indi_eib_lengua2 = rowlast(ind_eib_lengua2 ind_eib_lengua2_imputado)

* Ponderamos indicador de necesidad de atención eib
gen indicador_atencion_eib = ind_eib_lengua1*0.4 + ind_eib_lengua2*0.4 + proporcion_guiada_ie*0.2


* Generamos indicador de ie

gen n_ie = 1

* Gen indicador de acompanamiento pedagogico

gen acomp_pedagogico = 1 if acompanamiento_eib_2022 == 1 | ///
						acompanamiento_multigrado_2022 == 1 | ///
						acompanamiento_polidocente_2022 == 1
						

** Parte 3) Cambiamos nombres a variables, incluimos labels, etc.

* Eliminamos variable d_estado - Variable se repite con otra base
drop D_ESTADO
* Se cambian variables en minuscula
rename *, lower

* Mantenemos variables de interés
keep cod_mod anexo codlocal d_niv_mod d_forma d_cod_car d_tipssexo d_gestion d_ges_dep dareacenso codooii d_dreugel d_estado d_qaliwarma tipo_servicio_qaliwarma acompanamiento_eib_2022 acompanatic_2022 acompanamiento_multigrado_2022 acompanamiento_polidocente_2022 proporcion_guiada_ie ind_eib_lengua1 ind_eib_lengua2  docentes_total ece_imputado ind_leng_ece_primaria ind_mat_ece_primaria ind_leng_ece_secundaria ind_mat_ece_secundaria indicador_atencion_prim indicador_atencion_sec indicador_atencion_eib forma_eib  d_gestion nivel_ebr_noebr mat_total eib mat_recup_cuarto mat_recup_primero mat_recup_quinto mat_recup_segundo mat_recup_sexto mat_recup_tercero mat_total_cuarto mat_total_primero mat_total_quinto mat_total_segundo mat_total_sexto mat_total_tercero mat_recup mat_total n_ie acomp_pedagogico d_region area_21 foc2020_tablets

* Realizamos label de las variables
label variable cod_mod   						"Codigo modular que brindan servicio en el local educativo" 
label variable anexo   							"Anexo" 
label variable d_niv_mod   						"Nivel / Modalidad" 
label variable d_cod_car   						"Detalle de caracteristica (Censo educativo 2020)" 
label variable d_estado   						"Detalle de estado del servicio educativo" 
label variable acompanamiento_eib_2022   		"Recibe acompañamiento EIB" 
label variable acompanatic_2022   				"Recibe acompañatic" 
label variable acompanamiento_multigrado_2022   "Recibe acompañamiento multigrado" 
label variable acompanamiento_polidocente_2022  "Recibe acompañamiento polidocente" 
label variable proporcion_guiada_ie   			"Proporción de estudiantes en promoción guiada" 
label variable docentes_total   				"Número total de docentes (nexus)" 
label variable ece_imputado   					"Valor imputado de la ECE" 
label variable ind_leng_ece_primaria   			"Indicador ECE - lenguaje primaria" 
label variable ind_mat_ece_primaria   			"Indicador ECE - matematica primaria"
label variable ind_leng_ece_secundaria   		"Indicador ECE - lenguaje secundaria" 
label variable ind_mat_ece_secundaria   		"Indicador ECE - matematica secundaria" 
label variable indicador_atencion_prim   		"Indicador de necesidad de atención primaria" 
label variable indicador_atencion_sec   		"Indicador de necesidad de atención secundaria" 
label variable ind_eib_lengua1   				"Indicador ECE EIB - lengua 1" 
label variable ind_eib_lengua2   				"Indicador ECE EIB - lengua 2" 
label variable indicador_atencion_eib   		"Indicador de necesidad de atención EIB" 
label variable forma_eib				   		"Tipo EIB" 
label variable d_gestion						"Gestión"
*label variable directivos_total				"Número de directivos"
*label variable docentes_nomb					"Número de docentes nombrados"
*label variable docentes_cont_nomb				"Número total de docentes contratados y nombrados"
*label variable cont_mas10h						"Número total de docentes contratados más de"
label variable eib				"EIB/NOEIB"
label variable codlocal			"Código de local educativo"
label variable d_forma 			"Forma de atención"
label variable d_tipssexo 		"Género de los alumnos"
label variable d_ges_dep		"Gestión / Dependencia"
label variable dareacenso 		"Detalle del área geográfica (2000 Habitantes)"
label variable codooii 			"Código de DRE o UGEL que supervisa el servicio educativo"
label variable d_dreugel		"Nombre de la DRE o UGEL que supervisa el servicio educativo"
label variable mat_recup_primero	"Estudiantes en prom guiada primer grado" 
label variable mat_recup_segundo	"Estudiantes en prom guiada segundo grado" 
label variable mat_recup_tercero 	"Estudiantes en prom guiada tercer grado" 
label variable mat_recup_cuarto 	"Estudiantes en prom guiada cuarto grado" 
label variable mat_recup_quinto 	"Estudiantes en prom guiada quinto grado" 
label variable mat_recup_sexto 		"Estudiantes en prom guiada sexto grado" 
label variable mat_total_primero 	"Estudiantes matriculados primer grado" 
label variable mat_total_segundo 	"Estudiantes matriculados segundo grado" 
label variable mat_total_tercero 	"Estudiantes matriculados tercer grado" 
label variable mat_total_cuarto 	"Estudiantes matriculados cuuarto grado" 
label variable mat_total_quinto 	"Estudiantes matriculados quinto grado" 
label variable mat_total_sexto		"Estudiantes matriculados sexto grado"  
label variable mat_recup 			"Total estudiantes en promoción guiada" 
label variable mat_total			"Total estudiantes matriculados" 
label variable acomp_pedagogico			"Recibe acompañamiento pedagogico"
label variable d_region				"Dre Region"

* Ordenamos datos
order cod_mod anexo codlocal d_niv_mod d_cod_car d_estado forma_eib eib d_gestion   d_forma d_tipssexo d_ges_dep dareacenso d_region codooii d_dreugel nivel_ebr_noebr n_ie d_qaliwarma tipo_servicio_qaliwarma acompanamiento_eib_2022 acompanatic_2022 acompanamiento_multigrado_2022 acompanamiento_polidocente_2022 acomp_pedagogico indicador_atencion_prim indicador_atencion_sec indicador_atencion_eib ind_leng_ece_primaria ind_mat_ece_primaria ind_leng_ece_secundaria ind_mat_ece_secundaria ind_eib_lengua1 ind_eib_lengua2  eib  mat_recup_primero mat_recup_segundo mat_recup_tercero mat_recup_cuarto mat_recup_quinto mat_recup_sexto mat_total_primero  mat_total_segundo mat_total_tercero mat_total_cuarto mat_total_quinto mat_total_sexto  mat_recup mat_total area_21 foc2020_tablets

** Guardar data final
save "$clean/data_construida.dta", replace
