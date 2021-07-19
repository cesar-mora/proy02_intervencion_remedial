* ********************************************************************* *
* Área:			Unidad de Planificación y Presupuesto - Equipo Regiones
* Objetivos: 	Costear TaRL
* ********************************************************************* *
* ********************************************************************* *

       ** OUTLINE:      *ETAPA 0: Preparar globales y definir globales
                        *ETAPA 1: Definir tiempo y CAS
						*ETAPA 2: Generar Padrón SRE
						*ETAPA 3: Cálculo del PxQ

* ******************************************************************** *
*     ETAPA 0:  PREPARANDO FOLDER Y DEFINIENDO GLOBALES
* ******************************************************************** *

	use 	"$clean/data_focalizacion.dta", clear
	
	
	* Target 2022
	keep if targeted1 == 1
	* End Target 2022
	
	* Target 2023
	*gen targeted1_2023=0
	*replace targeted1_2023=1 if indicador_focalizacion>=0.72 & eib ==0
	*keep if targeted1_2023 == 1
	* End Target 2023
	
	* Target 2024 (promoción 2023)
	*drop if eib == 1
	*drop if indicador_focalizacion < 0.72
	*drop if indicador_focalizacion >= 0.75
	*gen targeted1_2024 = 1
	* End target 2024
	
	* Target 2024 (promoción 2024)
	*drop if eib == 1
	*drop if indicador_focalizacion >= 0.72
	*drop if indicador_focalizacion < 0.62
	*gen targeted1_2024 = 1
	* End target 2024 (promoción 2024)
	
	keep if d_niv_mod == "Primaria"
	
	* Renombrar variables
	
	rename docente_remedial n_docente
	rename alumnos_focalizados n_estu_total
	rename d_region nom_pliego
	rename codooii cod_ugel
	
	* Exportar Padrón de IIEE Focalizadas
	
	export excel "$output/Padrón_TaRL.xlsx", sheet ("Padrón_TaRL") replace firstrow(variables) locale(es)
				
* ******************************************************************** *
*     ETAPA 1:  DEFINIR VARIABLES PARA REMUNERACIÓN Y MENSUALIZACIÓN
* ******************************************************************** *

	* local agrupar "ene feb mar abr may jun jul ago sep oct nov dic t"
	local meses_total "ene feb mar abr may jun jul ago sep oct nov dic"

	* Remuneraciones
	local remu_mentor 4000 // Mentores
	local remu_docente 320 // Remuneración adicional docentes

	* Meses activos e inactivos
	local meses_ano6 6 // meses de cas para mentores y adicional docentes
	local meses_activo6 "abr may jun jul ago sep" // Mentores y docentes
	local meses_inactivo6 "ene feb mar oct nov dic"

	* Aguinaldo
	local monto_agui 300 // aguinaldo
	local meses_agui "jul"
	local meses_sinagui "ene feb mar abr may jun ago sep oct nov dic"

	* Essalud - UIT
	local UIT_2022 4400
	local UIT_porc 0.55

	 *Visitas/traslado mentores
	 local meses_visi_activo "abr may jun jul ago sep"
	 local visit_visi_inactivo "ene feb mar oct nov dic"
	 local meses_visi 6 // meses de visitas
	 local frec_mentor 20 // debido a que son 20 dias de visitas mensuales

	local costo_tras 120 // este es el costo de traslado
	
* ******************************************************************** *
*     ETAPA 2:  CÁLCULO DE METAS 
* ******************************************************************** *

	* Cálculo de pago fijo a docentes (adicional)
	* ---------------------
	
	gen adicional_docente = n_docente*`remu_docente'
	gen adicional_docente_total=n_docente*`remu_docente'*`meses_ano6'
	
	foreach mes in `meses_activo6' {
	gen adicional_docente_`mes'=n_docente*`remu_docente'
	}
	foreach mes in `meses_inactivo6' {
	gen adicional_docente_`mes'=0
	}
	
	* Cálculo de contratación mentores
	* ---------------------
	
	* Colapsar a nivel UGEL - Contratación de mentores se realiza a nivel UGEL
	collapse 	(first) d_dreugel nom_pliego ///
				(sum) n_ie n_docente n_estu_total ///
				adicional_docente adicional_docente_total adicional_docente_mar adicional_docente_abr adicional_docente_may adicional_docente_jun adicional_docente_jul adicional_docente_ago adicional_docente_ene adicional_docente_feb adicional_docente_sep adicional_docente_oct adicional_docente_nov adicional_docente_dic, by(cod_ugel)

	*Determinacion de contratacion de personal CAS
	
	gen n_mentor = ceil(n_docente/4) // Mentor

	*1. Mentor - 6 meses x 4000 soles

	gen cas_mentor_total=n_mentor*`remu_mentor'*`meses_ano6'
	gen agui_mentor_total=n_mentor*`monto_agui'

	foreach mes in `meses_activo6' {
	gen cas_mentor_`mes'=n_mentor*`remu_mentor'
	}
	foreach mes in `meses_inactivo6' {
	gen cas_mentor_`mes'=0
	}
	foreach mes in `meses_agui' {
	gen agui_mentor_`mes'=n_mentor*`monto_agui'
	}
	foreach mes in `meses_sinagui' {
	gen agui_mentor_`mes'=0
	}
	
	* ESSALUD banda: 9% * (RMV - 55%UIT)
	* ---------------------
	
	gen tope_essalud=ceil(0.09*(`UIT_porc'*`UIT_2022'))

	* Aporte a Essalud individual
	gen essalud_mentor=ceil(0.09*`remu_mentor')

	foreach var of varlist essalud_*{
	replace `var'=tope_essalud if `var'>tope_essalud
	}
	
	drop tope_essalud

	* mentor = 6 meses
	gen essalud_mentor_total=n_mentor*essalud_mentor*`meses_ano6'

	foreach mes in `meses_activo6'{
	gen essalud_mentor_`mes'=n_mentor*essalud_mentor
	}
	
	foreach mes in `meses_inactivo6'{
	gen essalud_mentor_`mes'=0 
	}
	
	* Determinación de costos de traslado
	* ---------------------
	
	** Mentor
	
	*Movilidad
	gen mov_visi_mentor_anual= `costo_tras' * n_mentor * `frec_mentor' * `meses_visi'

	foreach mes in `meses_visi_activo'{
	gen mov_visi_mentor_`mes'= `costo_tras' * n_mentor * `frec_mentor'
	 }
	foreach mes in `meses_visi_inactivo'{
	gen mov_visi_mentor_`mes'= 0
	}
	
	
	* Metas fisicas para el PXQ
	* ---------------------
	
	*preserve
	*keep nom_pliego cod_mod n_docente n_estu_recuperacion n_estu_total n_docente_remedial
	*gen n_ie = 1
	*collapse (first) cod_mod (rawsum) n_estu_recuperacion n_estu_total n_docente_remedial (sum) ie=n_ie , by(nom_pliego)
	*export excel "$output/TaRL_2022_metas_fisicas.xlsx", firstrow(variables) replace 
	*restore
	
	
	* Cálculo de otros gastos
	* ---------------------
	
	* Entrega de materiales educativos al inicio a alumnos
	gen material_educativo = 5*n_estu_total
	
	* Evaluación diagnóstica a alumnos
	gen evaluacion_diagnostica = 2*n_estu_total
	
	* Evaluación de seguimiento a alumnos
	gen evaluacion_seguimiento = 2*n_estu_total
	
	* Capacitación a mentores
	gen capacitacion_mentores = 40*n_mentor
	
	* Capacitación a docentes
	gen capacitacion_docentes = 40*n_docente
	
	
	* Montos totales
	* ---------------------

	*Para CAS
	gen costo_cas_total_anual=cas_mentor_total
	foreach mes in `meses_total'{
	gen costo_cas_total_`mes'=cas_mentor_`mes'
	}

	*Para Essalud:
	gen costo_essalud_total_anual=essalud_mentor_total
	foreach mes in `meses_total'{
	gen costo_essalud_total_`mes'=essalud_mentor_`mes'
	}

	*Para aguinaldos:
	gen costo_agui_total_anual=agui_mentor_total
	foreach mes in `meses_total'{
	gen costo_agui_total_`mes'=agui_mentor_`mes'
	}
	

	tempfile total
	save `total'
	
	* Exportar PxQ DREUGEL
	* ---------------------
	use `total', clear
	
	keep nom_pliego cod_ugel ///
	n_ie n_docente n_estu_total n_mentor ///
	cas_mentor_total essalud_mentor_total agui_mentor_total mov_visi_mentor_anual ///
	adicional_docente_total ///
	material_educativo evaluacion_diagnostica evaluacion_seguimiento capacitacion_mentores capacitacion_docentes
	
	export excel "$output/PxQ_DREUGEL_TaRL.xlsx", sheet ("PXQ_DREUGEL_TaRL") replace firstrow(variables) locale(es)

	* Exportar PxQ UE
	* ---------------------
	use `total', clear
	
	collapse (sum) n_ie n_docente n_estu_total n_mentor  ///
	cas_mentor_total essalud_mentor_total agui_mentor_total mov_visi_mentor_anual ///
	adicional_docente_total ///
	material_educativo evaluacion_diagnostica evaluacion_seguimiento capacitacion_mentores capacitacion_docentes, by(nom_pliego)
		
	export excel "$output/PxQ_UE_TaRL.xlsx", sheet ("PXQ_UE_TaRL") replace firstrow(variables) locale(es)

	
	
	
