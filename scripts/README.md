# Código e indicador de necesidad de atención

## Lista de scripts utilizados

| Script | Descripción | Input | Output |
|--------|-------------|-------|--------|
| 00_master.do | Corre el código desde un script centralizado |  |  |
| 01_cleandata.do | Une las bases de datos y mantiene IIEE de interés | raw/Padron_web.dta <br> raw/Base_padrones_2022.xlsx <br> raw/Padron IIEE AP_2022_caracterización_12JULIO.xlsx <br> raw/Padron_propuesto_polidocente.xls <br> raw/prima_sec_promocionguiada.dta <br> raw/Padron2020VMJPT210615-Tarde.dta <br> raw/Nexus por cod_mod.dta <br> raw/IE 4P EIB ECE 15-18.xlsx | clean/data_clean.dta |
| 02_construir_data.do | Construye e inserta labels a variables | clean/data_clean.dta <br> raw/imputacion_ece_primaria.csv <br> raw/imputacion_ece_secundaria.csv | clean/data_construida.dta |
| 03_focalizacion.do | Identifica a IIEE focalizadas el 2022 | clean/data_construida.dta | clean/data_focalizacion.dta |
| 04_est_descriptivas.do | Genera estadísticas descriptivas | clean/data_focalizacion.dta | output/tabla_resumen_1.xlsx |
| 05_PxQ_remedial_tarl.do | Genera costeo para TaRL | clean/data_focalizacion.dta | output/PxQ_DREUGEL_TaRL.xlsx <br> output/PxQ_UE_TaRL.xlsx |
| 06_PxQ_remedial_conectaideas.do | Genera costeo para ConectaIdeas | clean/data_focalizacion.dta | output/PxQ_DREUGEL_ConectaIdeas.xlsx <br> output/PxQ_UE_ConectaIdeas.xlsx |
| 07_imputacion_ece.py | Genera valores imputados para IIEE que no participaron en ECE | clean/data_clean.dta | raw/imputacion_ece_primaria.csv <br> raw/imputacion_ece_secundaria.csv |

## Construcción del indicador de necesidad de atención

Dada la limitada disponibilidad de recursos, no es posible atender a toda la población objetivo al inicio de la estrategia. Sin embargo, si es posible iniciar con un proceso de focalización para iniciar la implementación del programa y dependiendo de los resultados, pensar en un escalamiento de la misma. Para realizar este procedimiento se utilizó información de SIAGIE y la Evaluación Censal de Estudiantes (ECE) y se formuló un indicador de necesidad de atención para identificar a las IIEE no EIB que requerirían atención más urgente, el código para replicar la construcción del indicador de necesidad de atención se encuentra en el script `02_construir_data.do`.

<img src=
"https://render.githubusercontent.com/render/math?math=%5Cdisplaystyle+I_i+%3D+%280.4%29X_%7B1i%7D%2B%280.4%29X_%7B2i%7D%2B%280.2%29X_%7B3i%7D%0A" 
alt="I_i = (0.4)X_{1i}+(0.4)X_{2i}+(0.2)X_{3i}
">

- x_1: % Estudiantes en niveles de logro “Previo al inicio, en inicio” en matemática. (EM 2019, ECE 2018)
- x_2: % Estudiantes en niveles de logro “Previo al inicio, en inicio” en lenguaje. (EM 2019, ECE 2018)
= x_3: % Proporción de estudiantes en Promoción Guíada por IIEE. (SIAGIE)

Luego de realizar la estimación del indicador de necesidad, se identifica un valor entre 0.5-0.7 como umbral de atención. En este marco, las IIEE con un indicador de atención mayor a 0.5, serían aquellas que estaríamos recomendando atender.

Para aquellas IIEE que no participaron en la Encuesta Muestral o Censal del 2018 o 2019, se emplea un algoritmo de Nearest Neighbor Matching identificando a la IIEE que sí participó e imputando este valor a la IIEE más cercana que no haya participado. El código para replicar el proceso de imputación se encuentra en el script `07_imputacion_ece.py`
