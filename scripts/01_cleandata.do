********************************************************************************
* 01: Clean data
* Objetivo: El do-file combina las bases de datos requeridas para generar el
* indicador de necesidad de atención.

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

********************************************************************************

*01) COMBINAR BASES DE DATOS
*-----------------------------

* Importar Padrón de IIEE a mayo de 2021 (fuente: escale)
*----------------------
*import dbase "$raw/Padron_web.dbf" , clear
*clear
*unicode analyze "Padron_web.dta"
*unicode encoding set "latin1"
*unicode translate "Padron_web.dta"
*save "$raw/Padron_web.dta" , replace

use "$raw/Padron_web.dta", replace
rename COD_MOD cod_mod
rename ANEXO anexo
keep cod_mod anexo CODLOCAL D_ESTADO D_FORMA D_TIPSSEXO CODCCPP CODCP_INEI CODGEO D_DPTO D_PROV D_DIST D_REGION D_GESTION D_GES_DEP DAREACENSO CODOOII D_DREUGEL D_COD_CAR NLAT_IE NLONG_IE D_NIV_MOD D_GESTION TDOCENTE

preserve

*** Importar padrones de acompañamientos PxQ
*----------------------

* EIB
import excel "$raw/padron_acompanatic_eib.xlsx", sheet("eib") firstrow clear
rename Anexo anexo
keep	cod_mod anexo
gen 	acompanamiento_eib_2022 = 1
tempfile eib
save 	`eib'

* Acompanatic
import	excel "$raw/padron_acompanatic_eib.xlsx", sheet("acompanatic") firstrow clear
rename Anexo anexo
keep	cod_mod anexo
gen 	acompanatic_2022 = 1
tempfile acompanatic
save 	`acompanatic'

* Multigrado
import excel "$raw/padron_multigrado.xlsx", sheet("Padrón_IIEE") firstrow clear
keep 	cod_mod anexo
gen		acompanamiento_multigrado_2022 = 1
tempfile multigrado
save 	`multigrado'

* Polidocente
import excel "$raw/padron_polidocente.xls", sheet(Sheet1) firstrow clear
rename Anexo anexo
rename CodMod cod_mod
tostring cod_mod, replace
replace cod_mod =  "0"*(7-length(cod_mod))+cod_mod
keep cod_mod anexo
gen acompanamiento_polidocente_2022 = 1
tempfile polidocente
save `polidocente'

* Realizamos merge de los acompañamientos con el padrón de IIEE

restore

merge 1:1 cod_mod anexo using `eib', nogen

*    Result                           # of obs.
*    -----------------------------------------
*    not matched                       168,950
*        from master                   168,950  
*        from using                          0  
*
*    matched                             3,251  
*    -----------------------------------------

merge 1:1 cod_mod anexo using `acompanatic', nogen


*    Result                           # of obs.
*    -----------------------------------------
*    not matched                       147,906
*        from master                   147,906  
*        from using                          0  
*
*    matched                            24,295  
*    -----------------------------------------


merge 1:1 cod_mod anexo using `multigrado', nogen


*    Result                           # of obs.
*    -----------------------------------------
*    not matched                       169,735
*        from master                   169,735  
*        from using                          0  
*
*    matched                             2,466  
*    -----------------------------------------


merge 1:1 cod_mod anexo using `polidocente', nogen

*    Result                           # of obs.
*    -----------------------------------------
*    not matched                       170,004
*        from master                   170,004  
*        from using                          0  
*
*    matched                             2,197  
*    -----------------------------------------
preserve

* Realizamos merge con Siagie 2021 - contiene variable de promoción guiada a nivel de IE 
*----------------------

use 	"$raw/siagie_grado.dta", clear
replace DSC_GRADO=trim(DSC_GRADO)

keep COD_MOD ANEXO  MAT_TOTAL MAT_RECUPERACION  DSC_GRADO AREA_21
reshape wide MAT_TOTAL MAT_RECUPERACION, i(COD_MOD ANEXO) j(DSC_GRADO) string

rename *, lower
order *, alphabetic

rename mat_totalcuarto 			mat_total_cuarto
rename mat_recuperacioncuarto 	mat_recup_cuarto
rename mat_totalprimero 		mat_total_primero
rename mat_recuperacionprimero 	mat_recup_primero
rename mat_totalquinto 			mat_total_quinto
rename mat_recuperacionquinto 	mat_recup_quinto
rename mat_totalsegundo 		mat_total_segundo
rename mat_recuperacionsegundo 	mat_recup_segundo
rename mat_totalsexto 			mat_total_sexto
rename mat_recuperacionsexto 	mat_recup_sexto
rename mat_totaltercero 		mat_total_tercero
rename mat_recuperaciontercero	mat_recup_tercero

egen mat_recup =  rowtotal(mat_recup_primero mat_recup_segundo mat_recup_tercero mat_recup_cuarto mat_recup_quinto mat_recup_sexto), missing
egen mat_total = rowtotal(mat_total_primero mat_total_segundo mat_total_tercero mat_total_cuarto mat_total_quinto mat_total_sexto), missing

* Generamos variable de proporción de estudiantes que se encuentran en promoción guiada por IIEE
gen proporcion_guiada_ie = mat_recup/mat_total
keep cod_mod anexo mat* proporcion_guiada_ie
			
tempfile 	promocionguiada
save 		`promocionguiada'


use "$raw/siagie_grado.dta", clear
rename *, lower
collapse (first) area_21, by(cod_mod anexo)

tempfile 	ruralidad
save 		`ruralidad'



restore
merge 1:1 cod_mod anexo using `promocionguiada', nogen

*    Result                           # of obs.
*    -----------------------------------------
*    not matched                       132,634
*        from master                   132,634  
*        from using                          0  
*
*    matched                            39,567  
*    -----------------------------------------
* No todas las IIEE tienen el indicador de promoción guiada
*. sum acompanamiento_eib_2022 acompanatic_2022 acompanamiento_multigrado_2022 /// 
*acompanamiento_polidocente_2022 if MAT_RECUPERACION !=.
*
*    Variable |        Obs 
*-------------+------------
*acomp~b_2022 |      1,803
*acompanati~2 |     24,285
*acomp~o_2022 |      2,455 
*acomp~e_2022 |      1,859  

merge 1:1 cod_mod anexo using `ruralidad', nogen

preserve


* Match con base de datos integrada - contiene indicadores de la ECE 2018 y 2019
*----------------------
use "$raw/Padron2020VMJPT210615-brenda.dta", clear

tostring cod_mod, replace
tostring anexo, replace
replace cod_mod =  "0"*(7-length(cod_mod))+cod_mod

** Generar indicador de EIB

gen eib = 0
replace eib = 1 if (forma_eib == "EIB de fortalecimiento" | forma_eib == "EIB de revitalización" | forma_eib == "EIB en ámbitos urbanos")

** Generar variables de lectura y matemática ECE
egen lenguaje_inicio_ece_2018 = rowtotal(L18_1 L18_2), missing
egen mate_inicio_ece_2018 = rowtotal(M18_1 M18_2), missing

egen lenguaje_inicio_ece_2019 = rowtotal(grupo_l_0 grupo_l_1), missing
egen mate_inicio_ece_2019 = rowtotal(grupo_m_0 grupo_m_1), missing

** Generar indicador ECE
egen ind_lenguaje_ece_prim = rowlast(lenguaje_inicio_ece_2018 lenguaje_inicio_ece_2019) if d_niv_mod == "Primaria"
egen ind_mate_ece_prim = rowlast (mate_inicio_ece_2018 mate_inicio_ece_2019) if d_niv_mod == "Primaria"

egen ind_lenguaje_ece_sec = rowlast(lenguaje_inicio_ece_2018 lenguaje_inicio_ece_2019) if d_niv_mod == "Secundaria"
egen ind_mate_ece_sec = rowlast (mate_inicio_ece_2018 mate_inicio_ece_2019) if d_niv_mod == "Secundaria"

rename tipo_servicio tipo_servicio_qaliwarma

keep cod_mod anexo d_estado ind_lenguaje_ece_prim ind_mate_ece_prim ind_lenguaje_ece_sec ind_mate_ece_sec tipo_servicio_qaliwarma d_qaliwarma forma_eib eib nivel_ebr_noebr foc2020_tablets

tempfile base_integrada
save `base_integrada'

restore
merge 1:1 cod_mod anexo using `base_integrada', nogen


*    Result                           # of obs.
*    -----------------------------------------
*    not matched                       103,328
*        from master                   103,318  
*        from using                         10  
*
*    matched                            68,883  
*    -----------------------------------------
preserve

* Merge con BD Nexus - Contiene información de número de docentes
*----------------------
use "$raw/nexus_cod_mod.dta", replace

rename codmodce cod_mod

tempfile nexus
save `nexus'

restore
merge m:1 cod_mod using `nexus', nogen

*    Result                           # of obs.
*    -----------------------------------------
*    not matched                       131,984
*        from master                   131,878  
*        from using                        106  
*
*    matched                            40,333  
*    -----------------------------------------

preserve

* Merge con BD de ECE EIB - contiene información de la ECE 2015
*----------------------
import excel "$raw/IE 4P EIB ECE 15-18.xlsx", sheet("IE 4P EIB ECE 15-18") cellrange(A3:BZ2854) firstrow clear

* l1 = lengua originaria
* l2 = castellano como segunda lengua

rename CódigoModular cod_mod
rename Anexo anexo

rename AE alum_evaluados_l1_2016
rename AG alum_en_inicio_l1_2016
rename AH alum_en_proceso_l1_2016
rename AN alum_evaluados_l2_2016
rename AJ alum_en_inicio_l2_2016
rename AK alum_en_proceso_l2_2016
rename BA alum_evaluados_l1_2018
rename BC alum_en_inicio_l1_2018
rename BD alum_en_proceso_l1_2018
rename BK alum_evaluados_l2_2018
rename BM alum_en_inicio_l2_2018
rename BN alum_en_proceso_l2_2018


* 02) CONSTRUCCIÓN DE VARIABLES

** Generar indicadores de necesidad EIB
*----------------------

gen ind_eib_lengua1_2016 = (alum_en_inicio_l1_2016 + alum_en_proceso_l1_2016)/alum_evaluados_l1_2016
gen ind_eib_lengua2_2016 = (alum_en_inicio_l2_2016 + alum_en_proceso_l2_2016)/alum_evaluados_l2_2016


gen ind_eib_lengua1_2018 = (alum_en_inicio_l1_2018 + alum_en_proceso_l1_2018)/alum_evaluados_l1_2018
gen ind_eib_lengua2_2018 = (alum_en_inicio_l2_2018 + alum_en_proceso_l2_2018)/alum_evaluados_l2_2018


egen ind_eib_lengua1 = rowlast(ind_eib_lengua1_2016 ind_eib_lengua1_2018) 
egen ind_eib_lengua2 = rowlast(ind_eib_lengua1_2018 ind_eib_lengua2_2018) 


keep cod_mod anexo ind_eib_lengua1 ind_eib_lengua2

tempfile ece_eib
save `ece_eib'

restore
merge 1:1 cod_mod anexo using `ece_eib', nogen
*    Result                           # of obs.
*    -----------------------------------------
*    not matched                       169,472
*        from master                   169,469  
*        from using                          3  
*
*    matched                             2,848  
*    -----------------------------------------


*02) MANTENER OBSERVACIONES DE INTERÉS
*-----------------------------

* Mantenemos IIEE Activas según padrón Escale o que se encuentren en acompañamientos
keep if 	D_ESTADO == "Activa" | ///
			(acompanamiento_eib_2022 == 1 | acompanatic_2022 == 1 | acompanamiento_multigrado_2022 == 1 | acompanamiento_polidocente_2022 == 1)

* Mantenemos Primaria, Secundaria, Inicial cuna-jardin e Inicial Jardin
keep if 	D_NIV_MOD == "Primaria" | D_NIV_MOD == "Secundaria" | D_NIV_MOD == "Inicial - Cuna-jard¡n" | D_NIV_MOD == "Inicial - Jard¡n" | D_NIV_MOD == "Inicial - Cuna"

* Eliminamos IIEE de gestión privada
drop if 	D_GESTION == "Privada"

*generar identificador único
egen cod_mod_anexo = concat(cod_mod anexo)

* Guardamos data
save "$clean/data_clean.dta", replace
