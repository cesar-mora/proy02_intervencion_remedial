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

	*** Focalización

	if ($foc_digbr_ugel == 1) {
	use 	"$clean/data_focalizacion_$foc.dta", clear
	* Mantenemos a IIEE focalizadas
	keep if targeted1 == 1
	* Mantenemos IIEE priorizadas
	keep if (d_niv_mod == "Primaria"	| d_niv_mod == "Secundaria")
	}	
	
	if ($foc_digbr_iiee == 1) {
	use 	"$clean/data_focalizacion_$foc.dta", clear
	* Mantenemos a IIEE focalizadas
	keep if targeted1 == 1
	* Mantenemos IIEE priorizadas
	keep if (d_niv_mod == "Primaria"	| d_niv_mod == "Secundaria")
	}	
	
	if ($foc_digbr_global == 1) {
	use 	"$clean/data_focalizacion_$foc.dta", clear
	* Mantenemos a IIEE focalizadas
	keep if targeted1 == 1
	* Mantenemos IIEE priorizadas
	keep if (d_niv_mod == "Primaria"	| d_niv_mod == "Secundaria")
	}		
	
	if ($foc_digbr_90 == 1) {
	use 	"$clean/data_focalizacion_$foc.dta", clear
	* Mantenemos a IIEE focalizadas
	keep if targeted1 == 1
	* Mantenemos IIEE priorizadas
	keep if (d_niv_mod == "Primaria"	| d_niv_mod == "Secundaria")
	}		

	* Renombrar variables
	rename docente_remedial n_docente 
	rename alumno_grado_total n_estu_total
	rename d_region nom_pliego
	rename codooii cod_ugel
	
	* Guardar archivo temporal - después se utiliza para padrón de IIEE
	
	tempfile bd_remedial
	save `bd_remedial'
					
* ******************************************************************** *
*     ETAPA 1:  DEFINIR VARIABLES PARA REMUNERACIÓN Y MENSUALIZACIÓN
* ******************************************************************** *

	* local agrupar "ene feb mar abr may jun jul ago sep oct nov dic t"
	local meses_total "ene feb mar abr may jun jul ago sep oct nov dic"

	* Remuneraciones
	local remu_mentor 4000 // Mentores
	local remu_docente 400 // Remuneración adicional docentes (20*5*4)

	* Meses activos e inactivos
	local meses_ano8 8 // meses de cas para mentores y adicional docentes
	local meses_activo8 "abr may jun jul ago sep oct nov" // Mentores y docentes
	local meses_inactivo4 "ene feb mar dic"

	* Aguinaldo
	local monto_agui 300 // aguinaldo
	local meses_agui "jul"
	local meses_sinagui "ene feb mar abr may jun ago sep oct nov dic"

	* Essalud - UIT
	local UIT_2022 4500
	local UIT_porc 0.55

	 *Visitas/traslado mentores
	 local viatico_ccpp 60 // Costo de viaticos
	 local n_acompanamiento 8 // Número de acompañamientos (1 por mes)
	 
	 
	 *local meses_visi_activo "abr may jun jul ago sep oct nov"
	 *local visit_visi_inactivo "ene feb mar dic"
	 *local meses_visi 8 // meses de visitas
	 *local frec_mentor 10 // debido a que son 10 dias de visitas mensuales

	 *local costo_tras 120 // este es el costo de traslado
	
* ******************************************************************** *
*     ETAPA 2:  CÁLCULO DE METAS 
* ******************************************************************** *

	* Cálculo de contratación mentores
	* ---------------------
	
	* Generamos indicador de rural para el cálculo de contratación de mentores
	gen rural1 = 1 if area_21 == "Rural 1"
	gen rural2 = 1 if area_21 == "Rural 2"
	gen rural3 = 1 if area_21 == "Rural 3"
	gen urbano = 1 if area_21 == "Urbano"
	
	* Colapsar a nivel UGEL - Contratación de mentores se realiza a nivel UGEL
	collapse 	(first) d_dreugel nom_pliego ///
				(sum) n_ie n_docente n_estu_total rural1 rural2 rural3 urbano, by(cod_ugel)

	*Determinacion de contratacion de personal CAS
	gen proporcion_rural = (rural1 + rural2 + rural3)/(rural1 + rural2 + rural3 + urbano)
	
	gen n_mentor = ceil(n_docente/8) if proporcion_rural>= 0.8 // Número de mentores en zonas más rurales
	replace n_mentor = ceil(n_docente/10) if proporcion_rural< 0.8 // Número de mentores en zonas urbanas
	
	* Eliminación de UGELES con menos de 8 docentes
	* ---------------------
	
	* Se eliminan UGELES con bajo número de docentes
	drop if n_docente < 8
	
	* Guardamos temporalmente
	tempfile ugel
	save `ugel'
	
	use `bd_remedial', clear
	merge m:1 cod_ugel using `ugel', keep(match) keepusing(cod_ugel)
	
	* Padrón de Intervención
	* ---------------------	
	save "$output/Padrón_TaRL_$foc.dta", replace
	
	tempfile padron
	save `padron'
	
	export excel "$output/Padrón_TaRL_$foc.xlsx", sheet ("Padrón_TaRL") replace firstrow(variables) locale(es)


	* Cálculo de contratación mentores
	* ---------------------

	use `ugel', clear

	*1. Mentor - 8 meses x 4000 soles

	gen cas_mentor_total=n_mentor*`remu_mentor'*`meses_ano8'
	gen agui_mentor_total=n_mentor*`monto_agui'

	foreach mes in `meses_activo8' {
	gen cas_mentor_`mes'=n_mentor*`remu_mentor'
	}
	foreach mes in `meses_inactivo4' {
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

	* mentor = 8 meses
	gen essalud_mentor_total=n_mentor*essalud_mentor*`meses_ano8'

	foreach mes in `meses_activo8'{
	gen essalud_mentor_`mes'=n_mentor*essalud_mentor
	}
	
	foreach mes in `meses_inactivo4'{
	gen essalud_mentor_`mes'=0 
	}

	* Cálculo de pago fijo a docentes (adicional)
	* ---------------------
	
	gen adicional_docente = n_docente*`remu_docente'
	gen adicional_docente_total=n_docente*`remu_docente'*`meses_ano8'
	
	foreach mes in `meses_activo8' {
	gen adicional_docente_`mes'=n_docente*`remu_docente'
	}
	foreach mes in `meses_inactivo4' {
	gen adicional_docente_`mes'=0
	}
	
	* Cálculo de otros gastos (no se consideran gastos adicionales en el escenario)
	* ---------------------
	
	* Entrega de materiales educativos al inicio a alumnos (5)
	gen material_educativo = 0*n_estu_total
	
	* Evaluación diagnóstica a alumnos (2)
	gen evaluacion_diagnostica = 0*n_estu_total
	
	* Evaluación de seguimiento a alumnos (2)
	gen evaluacion_seguimiento = 0*n_estu_total
	
	* Capacitación a mentores (40)
	gen capacitacion_mentores = 0*n_mentor
	
	* Capacitación a docentes (40)
	gen capacitacion_docentes = 0*n_docente
	
	
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
	
* ******************************************************************** *
*     ETAPA 3:  DETERMINACIÓN DE COSTOS DE TRASLADO
* ******************************************************************** *	
	
	use `padron', clear
	
*use "$output/Padrón_TaRL_foc_digbr_eje03.dta", clear
rename n_docente docente_remedial
rename d_niv_mod nivel
rename cod_ugel codooii

collapse (first) codcp_inei codgeo (sum) docente_remedial, by (codooii nivel)
rename codgeo Ubigeo
destring Ubigeo, replace

merge m:1 codooii using "$raw/base_ue_ugel_ubigeo_2022"

keep if _m==3
drop _m

*Importamos la base de viáticos de traslados a distrito y volvemos formato dta.
preserve
*Importar base de tiempo, movilidad, pasajes, viaticos: Region - Distrito (De qué parte de la región la capital de la provincia)
tempfile traslado_distrito //Creamos la base como temporal para no ocupar espacio
import excel "$raw/movilidad_viaticos_distrito.xlsx", cellrange( A1:N1876 ) firstrow clear sheet("Tabla_Viaticos")
*Creamos las etiquetas de las variables que usaremos
	
	label var	mov_local			"Costo traslado de la capital de provincia a capital de distrito (S/.)"
	label var	traslado_prov_reg	"Costo traslado de la capital de región a la capital de provincia (S/.)"
	label var	tiempo_prov_dist	"Tiempo de traslado de capital de provincia a capital de distrito (horas)"
	label var	dic_viat_prov_reg	"Recibe viaticos de traslado de region a provincia (1: Si - 0: No)"
	label var	viat_prov_reg		"Costo de viaticos de traslado de region a provincia(S/.)"
	label var	dic_viat_prov_dis	"Recibe viaticos de traslado de provincia a distrito (1: Si - 0: No)"
	label var 	viat_prov_dis		"Costo de viaticos de traslado de provincia a distrito (S/.)"
	label var	dic_viat_dis_reg	"Recibe viaticos de traslado de region a distrito (1: Si - 0: No)"
	label var	viat_dis_reg		"Costo de viaticos de traslado de region a distrito (S/.)"
	
destring Ubigeo, replace //Volvemos la variable a formato numérico para poder hacer merge con otras bases
drop Departamento Provincia Distrito //Nos deshacemos de las varibales que no necesitamos.

save `traslado_distrito', replace //Salvamos la base

*Importar base de tiempo, movilidad, pasajes, viaticos: Distrito - CCPP
tempfile traslado_ccpp //Creamos la base como temporal para no ocupar espacio
import excel "$raw/movilidad_viaticos_ccpp.xlsx", cellrange(a2:q23725) firstrow clear
keep tiempo_en_hr dic_viat_dist_ccpp tras_dist_ccpp codcp_inei error //Por qué aqui nos quedamos por la variable error<------------
*Asignamos etiquetas a las variables
label var	codcp_inei		"Código de centro poblado" //Las primeras 6 cifras coinciden con el ubigeo del INEI
label var	tiempo_en_hr	"Tiempo de traslado en horas de la capital del distrito al centro poblados"
label var	tras_dist_ccpp	"Costo traslado de la capital de distrito al CCPP (S/.)"
label var	dic_viat_dist_ccpp	"Recibe viaticos de traslado de distrito a CCPP (1: Si - 0: No)" //El monto del viático está definido en los locales

save `traslado_ccpp', replace //Salvamos la base en formato temporal

restore

*Realizamos el merge de ambas bases
merge m:1 Ubigeo using `traslado_distrito' , keep(match master) nogen //Solo los que han hecho match del archivo master (base)
merge m:1  codcp_inei using `traslado_ccpp'  //Por qué aquí si nos quedamos con todos los datos de ccpp de Perú y en el otro no? (Código proveniente de Do para periodo 2021)





*Modificamos la variable UBIGEO de Long a String (donde a los que tienen 5 cifras se le agrega el cero correspondeinte adelante,
*para en total ser un código de 6 cifras.
tostring Ubigeo, replace
forval j=1/6 {
	replace Ubigeo = "0"+ Ubigeo if length(Ubigeo)<`j'& Ubigeo!="."
}

*Generamos la variable ubigeo de los ccpp, obteniendo los 6 primeros dígitos del CCPP para que sean reemplazados
*en aquellas observaciones que no tienen valor de UBIGEO
gen Ubigeo_ccpp= substr(codcp_inei,1,6)
 *Se vuelve string por el método visto línea arriba
 tostring Ubigeo_ccpp, replace
forval j=1/6 {
	replace Ubigeo_ccpp = "0"+ Ubigeo_ccpp if length(Ubigeo_ccpp)<`j' & Ubigeo_ccpp!=""
}

***Para aquellas observaciones que no tienen UBIGEO se obtenien de lo creado en la variable anterior, y se reemplaza
replace Ubigeo=Ubigeo_ccpp if Ubigeo=="."

* Hacemos correciones Adhoc de los traslados en Lima Metropolitana (Pliego 10)
replace tras_dist_ccpp = 0 if cod_pliego==10
replace tiempo_en_hr = 0 if cod_pliego==10


**** Objetivo: obtener información aproximada para el traslado a nivel de centro poblado, para aquellos que no hacen merge
	replace tras_dist_ccpp=. if error==1 //qué es lo que significa?<----------------------------------------------<<<<<<<<
	*Imputa por metodología de hotdeck los valores de traslado de distrito a ccpp aquellos ccpp que no tienen info.
	*La imputación se realiza tomando el valor promedio del costo de traslado dentro del distrito (UBIGEO)
	bys Ubigeo: egen tras_dist_ccpp2=mean(tras_dist_ccpp) if tras_dist_ccpp!=0
	replace tras_dist_ccpp=tras_dist_ccpp2 if tras_dist_ccpp==.
	
	*El mismo ejercicio se realiza con el tiempo en horas
	bys Ubigeo: egen tiempo_en_hr2=mean(tiempo_en_hr) if tiempo_en_hr!=0
	replace tiempo_en_hr=tiempo_en_hr2 if tiempo_en_hr==.
		
	*Se genera el código de provincia
	gen cod_provincia= substr(Ubigeo,1,4)
	*Imputa por metodología de hotdeck los valores de traslado de distrito a ccpp de aquellos ccpp que no tienen info.
	*La imputación se realiza tomando el valor promedio del costo de traslado dentro de la provincia (cod_provincia). Lo mismo ocurre con las horas
	bys cod_provincia: egen tras_dist_ccpp3=mean(tras_dist_ccpp) if tras_dist_ccpp!=0
	replace tras_dist_ccpp=tras_dist_ccpp3 if tras_dist_ccpp==.
	
	bys cod_provincia: egen tiempo_en_hr3=mean(tiempo_en_hr) if tiempo_en_hr!=0
	replace tiempo_en_hr=tiempo_en_hr3 if tiempo_en_hr==.
	gen cod_region= substr(Ubigeo,1,2)
	
	*Imputa por metodología de hotdeck los valores de traslado de capital de distrito accpp de aquellos ccpp que no tienen info.
	*La imputación se realiza tomando el valor promedio del costo de traslado dentro de la región(cod_region). Lo mismo ocurre con las horas

	bys cod_region: egen tras_dist_ccpp4=mean(tras_dist_ccpp) if tras_dist_ccpp!=0
	replace tras_dist_ccpp=tras_dist_ccpp4 if tras_dist_ccpp==.
	
	bys cod_region: egen tiempo_en_hr4=mean(tiempo_en_hr) if tiempo_en_hr!=0
	replace tiempo_en_hr=tiempo_en_hr4 if tiempo_en_hr==.
	
	drop tras_dist_ccpp2 tiempo_en_hr2 tras_dist_ccpp3 tiempo_en_hr3 tras_dist_ccpp4 tiempo_en_hr4

	drop if _merge==2 //borramos las observaciones que no hicieron match de la base using (de donde se sacaron los datos de costo y horas de traslado)
	*Así solo nos quedamos con los datos del padrón. 
	drop _merge

	*Los valores missing de las siguientes variables son reemplazados por cero
		foreach v in mov_local traslado_prov_reg traslado_dis_Reg dic_viat_prov_reg ///
			viat_prov_reg dic_viat_prov_dis viat_prov_dis dic_viat_dis_reg viat_dis_reg ///
			dic_viat_dist_ccpp tras_dist_ccpp tiempo_en_hr{
		replace `v'=0 if `v'==.
		}	
		

		
* Se incluye de forma adhoc valor cero a las IIEE que son capital de provincia
* de viáticos y movilidad /pasajes de provincia a distrito y region a distrito
replace mov_local=0 if substr(Ubigeo,5,2)=="01" // Limpieza a los distritos capital de provincia que no deben tener traslado de prov a distrito porque es el mismo lugar
replace viat_prov_dis=0 if substr(Ubigeo,5,2)=="01" // Limpieza a los distritos capital de provincia que no deben tener traslado de prov a distrito porque es el mismo lugar

*Traslado de provincia capital de región a provincia??
replace traslado_prov_reg=0 if substr(Ubigeo,3,2)=="01" // Limpieza a los distritos capital de provincia que no deben tener traslado de prov a distrito porque es el mismo lugar
replace viat_prov_reg=0 if substr(Ubigeo,3,2)=="01" // Limpieza a los distritos capital de provincia que no deben tener traslado de prov a distrito porque es el mismo lugar

*Se crea variable auxiliar para aquellos que no tienen código de ccpp.
*Aparentemente sirve solamente para no mezclar estas IIEE de diferetnes centros poblados (desconocidos y con codigo acutal "")
*dentro del collpase del próximocomando
bys cod_pliego cod_ue codooii: gen gg=_n 
tostring gg, replace 
replace codcp_inei=gg if codcp_inei=="" 

*Se colapsa todo a nivel de código de centro poblado y por nivel
collapse(rawsum) docente_remedial (mean) mov_local tras_dist_ccpp traslado_prov_reg viat_prov_dis viat_prov_reg tiempo_en_hr tiempo_prov_dist, by(cod_pliego cod_ue codooii codcp_inei nivel)
*Nota: comprobar como se calcula la conectividad (segun MTC a nivel centro poblado)

*Se calcula si los centro poblados son beneficiarios de viáticos o no, para ello la cantidad de horas de traslado
*de la capital de provincia al centro poblado deben de ser de al menos 2 horas
egen t_total= rowtotal (tiempo_en_hr tiempo_prov_dist)  //Se halla el total de horas
gen dic_ugel_ccpp=1 if t_total>=2 // Se crea la variable si el tralsado lleva al menos 2 horas
replace dic_ugel_ccpp=0 if dic_ugel_ccpp==.

*Se asigna un viático de 60 soles (determinado arriba) para aquellos que necesitan viático de acuerdo a la regla anterior
gen viat_cp=`viatico_ccpp' if (viat_prov_dis==.|viat_prov_dis==0) & dic_ugel_ccpp==1
replace viat_cp=0 if viat_cp==.

***Se realiza el cálculo de visistas necesario para cada grupo de docentes
*(Sin/Con Conectividad) de acuerdo a la cantidad de docentes de cada tipo 
*por UGEL. Estos parámetros están detallados en los criterios de programación
*del Programa tabletas



*Repetimos el mismo proceso para los docentes con y sin conectividad



/* existen hasta 31 docentes sin conectividad como maximo por codigo ccpp
gen dias_visita = 2 if docente_remedial <= 2
replace dias_visita = 3 if docente_remedial >= 3 & docente_remedial <= 6
replace dias_visita = 4 if docente_remedial >= 7 & docente_remedial <= 8
replace dias_visita = 6 if docente_remedial >= 9 & docente_remedial <= 12
replace dias_visita = 8 if docente_remedial >= 13 & docente_remedial <= 16
replace dias_visita = 10 if docente_remedial >= 17 & docente_remedial <= 20
replace dias_visita = 12 if docente_remedial >= 21 & docente_remedial <= 24
replace dias_visita = 14 if docente_remedial >= 25 & docente_remedial <= 28
replace dias_visita = 16 if docente_remedial >= 29 & docente_remedial <= 32
*/

*Generalización:


gen dias_visita_2=ceil(docente_remedial/2)
	*Se conserva que de 3 a 6 se toma 3 días
	replace dias_visita = 0 if docente_remedial == 0 | docente_remedial ==. 	
	replace dias_visita=2 if docente_remedial <=2 & docente_remedial>0
	replace dias_visita = 3 if docente_remedial >= 3 & docente_remedial <= 6
	*Se generaliza
	replace dias_visita=dias_visita+1 if (dias_visita)/2 != ceil(dias_visita/2) & dias_visita!=3



*******Semanas efectivas en las que se realizan las visitas (máximo se puede ocupar 4 días de visita x semana)
/*gen dias_mentores = 1 if dias_visita == 2 | dias_visita==3 |dias_visita == 4 
replace dias_mentores = 2 if dias_visita == 6 | dias_visita == 8
replace dias_mentores = 3 if dias_visita == 10 | dias_visita == 12 
replace dias_mentores = 4 if dias_visita == 14 | dias_visita == 16 
*/
gen dias_mentores_2=ceil(dias_visita/4)
* importante
replace dias_mentores = 0 if dias_visita == 0


* VISITAS 
*****************
*este cambio se hace ede manera manual a pedido de las direcciones para el periodo 2021=Si tenías menos de 600 docentes se iba a contratar a través de la DRE

*gen dic_dre = "no"
*replace dic_dre = "si" if codooii== 40000 | codooii==110000 | codooii==170000 | codooii==230000 | codooii== 240000  | codooii==200000 | codooii==130000
*replace traslado_prov_reg = 0 if dic_dre =="no" 
*replace viat_prov_reg = 0 if dic_dre =="no"

*Se hallan las variables de pasajes, movilidad y viáticos:


*Movilidad (PARA LOS QUE NO RECIBEN VIATICOS)
* Inicial
*gen mov_visit_inic= (traslado_prov_reg + mov_local + tras_dist_ccpp)*2*dias_visita if dic_ugel_ccpp==0 & nivel=="Inicial"
*replace mov_visit_inic= 0 if mov_visit_inic==.
* primaria
gen mov_visit_prim= (traslado_prov_reg + mov_local + tras_dist_ccpp)*2*dias_visita if dic_ugel_ccpp==0 & nivel=="Primaria"
replace mov_visit_prim= 0 if mov_visit_prim==.
* secundaria
gen mov_visit_secu= (traslado_prov_reg + mov_local + tras_dist_ccpp)*2*dias_visita if dic_ugel_ccpp==0 & nivel=="Secundaria"
replace mov_visit_secu= 0 if mov_visit_secu==.


*Pasajes (PARA LOS QUE SE QUEDAN)
* Inicial
*gen pas_visit_inic= (traslado_prov_reg + mov_local + tras_dist_ccpp)*2*dias_mentores if dic_ugel_ccpp==1 & nivel=="Inicial"
*replace pas_visit_inic= 0 if pas_visit_inic==.
* primaria
gen pas_visit_prim= (traslado_prov_reg + mov_local + tras_dist_ccpp)*2*dias_mentores if dic_ugel_ccpp==1 & nivel=="Primaria"
replace pas_visit_prim= 0 if pas_visit_prim==.
* secundaria
gen pas_visit_secu= (traslado_prov_reg + mov_local + tras_dist_ccpp)*2*dias_mentores if dic_ugel_ccpp==1 & nivel=="Secundaria"
replace pas_visit_secu= 0 if pas_visit_secu==.


*Viaticos
* Inicial						->(viáticos)<-		Por Hospedaje   Por día de viaje (ida y vuelta)  
*gen viat_visit_inic= (viat_prov_dis + viat_cp)*(dias_visita + 2*dias_mentores) if dic_ugel_ccpp==1 & nivel=="Inicial"
*replace viat_visit_inic= 0 if viat_visit_inic==.
* Primaria						->(viáticos)<-		Por Hospedaje   Por día de viaje (ida y vuelta)  
gen viat_visit_prim= (viat_prov_dis + viat_cp)*(dias_visita + 2*dias_mentores) if dic_ugel_ccpp==1 & nivel=="Primaria"
replace viat_visit_prim= 0 if viat_visit_prim==.
* secundaria
gen viat_visit_secu= (viat_prov_dis + viat_cp)*(dias_visita + 2*dias_mentores) if dic_ugel_ccpp==1 & nivel=="Secundaria"
replace viat_visit_secu= 0 if viat_visit_secu==.

*Se colapse a nivel de codooii(UGEL)

collapse(sum) mov_visit_* pas_visit_* viat_visit_* , by(cod_pliego cod_ue codooii nivel)

tostring codooii, replace
gen largo=length(codooii)
replace codooii= "0" + codooii if largo==5

*Se cambio los nombres de acuerdo a las categorias, nivel y tipo de conectividad
local categoria "mov pas viat"
local nivel "prim secu"

foreach cat of local categoria {
	foreach niv of local nivel{
			replace `cat'_visit_`niv'= ceil(`cat'_visit_`niv')
		}
	}
		
egen total= rowtotal(mov* pas* via*)

	
	** Cambiamos nombres para hacer merge
	rename codooii cod_ugel
	
	** Generamos totales de primaria y secundaria
	egen mov_visi_mentor_anual =  rowtotal(mov_visit_prim mov_visit_secu)
	replace mov_visi_mentor_anual = `n_acompanamiento'*mov_visi_mentor_anual
	
	egen pas_visi_mentor_anual = rowtotal(pas_visit_prim pas_visit_secu)
	replace pas_visi_mentor_anual = `n_acompanamiento'*pas_visi_mentor_anual
	
	egen viat_visi_mentor_anual = rowtotal(viat_visit_prim viat_visit_secu)
	replace viat_visi_mentor_anual = `n_acompanamiento'*viat_visi_mentor_anual
	
	** Colapsamos a nivel de codooii
	collapse (sum) mov_visi_mentor_anual pas_visi_mentor_anual viat_visi_mentor_anual, by(cod_ugel)
	
	tempfile traslado_codooii
	save `traslado_codooii'
	
* ******************************************************************** *
*     ETAPA 4:  EXPORTAR PxQ
* ******************************************************************** *	

	* Realizamos merge de costo de traslado y metas
	
	use `total', clear
	merge 1:1 cod_ugel using `traslado_codooii'
	
	* Exportar PxQ DREUGEL
	* ---------------------
	
	keep nom_pliego cod_ugel ///
	n_ie n_docente n_estu_total n_mentor ///
	cas_mentor_total essalud_mentor_total agui_mentor_total mov_visi_mentor_anual pas_visi_mentor_anual viat_visi_mentor_anual ///
	adicional_docente_total ///
	material_educativo evaluacion_diagnostica evaluacion_seguimiento capacitacion_mentores capacitacion_docentes
	
	export excel "$output/PxQ_DREUGEL_TaRL_$foc.xlsx", sheet ("PXQ_DREUGEL_TaRL") replace firstrow(variables) locale(es)
