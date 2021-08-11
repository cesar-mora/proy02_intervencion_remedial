# Repositorio de la estrategia de Educación Remedial

Este repositorio contiene el código para replicar los cálculos de la focalización y costeo de la intervención remedial Teaching at the Right Level - TaRL y ConectaIdeas.

## Contenido del repositorio
- [Código e indicador de focalización](https://github.com/analistaup29/proy02_intervencion_remedial/tree/main/scripts)
- [PxQ intervenciones](https://github.com/analistaup29/proy02_intervencion_remedial/tree/main/output)
- [Policy brief](https://github.com/analistaup29/proy02_intervencion_remedial/tree/main/documentacion)

## Reproducción de resultados

Si encuentras algún problema para correr el código o reproducir los resultados, por favor [crea un `Informe de problemas`](https://github.com/analistaup29/proy02_intervencion_remedial/issues/new) en este repositorio.

### Requerimientos de software

- Stata (código se corrió con la versión 15)
- Python 3.8.1  (código se corrió en IDE Spyder versión 4.1.5)

### Requerimientos de memoria y tiempo de ejecución

- El código de corrió en la PC de Minedu con **Windows 10 y 16GB de RAM**
- El código en Stata toma aproximadamente 2 minutos en correr.
- El código en Python toma aproximadamente 6 horas en correr.

Instrucciones para replicar
---------------------------

### En una PC personal

1. Ya tienes una cuenta en GitHub.com? Si no, [ve a GitHub.com](https://github.com/join)  e inscríbete.
2. Descarga e instala [GitHub Desktop](https://desktop.github.com) en tu PC.
3. Inicia sesión en GitHub Desktop con tu usuario Github.
5. Haz click en el botón verde `Code` que se muestra arriba de la lista de archivos en este repositorio, haz click en la opción `Open with GitHub Desktop`.
6. Abre la ruta del repositorio clonado y navega a `data/raw`.
7. La data utilizada se encuentra en la Unidad B del Onedrive de Minedu. Ve a `B:\OneDrive - Ministerio de Educación\unidad_B\2022\1. Estudios Data\proy02_intervencion_remedial\data\raw` utilizando el VPN. Copia esta data en el folder `data/raw` del repositorio clonado. Si eres parte de Minedu y no tienes acceso a la Unidad B, puedes contactarte con el Equipo de Analítica de Datos de la Unidad de Planificación y Presupuesto.
8. En el folder `scripts` encontrarás un script llamado `00_master.do`.
9. Para correr el código abre `master.do` y copia la ruta del repositorio clonado, así como el `username` de tu PC en la sección Rutas de Usuario.
10. Los outputs se guardarán en la carpeta `output` y las tablas finales se puede ver en [Google Sheets](https://docs.google.com/spreadsheets/d/1GHUOIn-mRkvh-w5rlBTjIUvWrSOHmztyB4JQupqlpZs/edit?usp=sharing)

Scripts
---------------------------

| Script | Descripción | Input | Output |
|--------|-------------|-------|--------|
| 00_master.do | Corre el código desde un script centralizado |  |  |
| 01_cleandata.do | Une las bases de datos y mantiene IIEE de interés | raw/Padron_web.dta <br> raw/Base_padrones_2022.xlsx <br> raw/Padron IIEE AP_2022_caracterización_12JULIO.xlsx <br> raw/Padron_propuesto_polidocente.xls <br> raw/prima_sec_promocionguiada.dta <br> raw/Padron2020VMJPT210615-Tarde.dta <br> raw/Nexus por cod_mod.dta <br> raw/IE 4P EIB ECE 15-18.xlsx | clean/data_clean.dta |
| 02_construir_data.do | Construye e inserta labels a variables | clean/data_clean.dta <br> raw/imputacion_ece_primaria.csv <br> raw/imputacion_ece_secundaria.csv | clean/data_construida.dta |
| 03_focalizacion.do | Identifica a IIEE focalizadas el 2022 | clean/data_construida.dta | clean/data_focalizacion.dta |
| 04_est_descriptivas.do | Genera estadísticas descriptivas | clean/data_focalizacion.dta | output/tabla_resumen_1.xlsx |
| 05_PxQ_remedial_tarl.do | Genera costeo para TaRL | clean/data_focalizacion.dta | output/PxQ_DREUGEL_TaRL.xlsx <br> output/PxQ_UE_TaRL.xlsx |
| 06_imputacion_ece.py | Genera valores imputados para IIEE que no participaron en ECE | clean/data_clean.dta | raw/imputacion_ece_primaria.csv <br> raw/imputacion_ece_secundaria.csv |
