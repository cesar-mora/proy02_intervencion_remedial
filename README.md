# Repositorio del proyecto de intervención Remedial

Este repositorio contiene el código para replicar los cálculos de la focalización y costeo de la intervención remedial (Teaching at the Right Level - TaRL).

Si encuentras algún problema para correr el código o reproducir los resultados, por favor [crea un `Informe de problemas`](https://github.com/analistaup29/proy02_intervencion_remedial/issues/new) en este repositorio.

Requerimientos computacionales
------------------------------

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
7. La data utilizada se encuentra en el Disco B de MINEDU. Ve a `B:\OneDrive - Ministerio de Educación\unidad_B\2022\1. Estudios Data\proy02_intervencion_remedial` utilizando el VPN. Copia esta data en el folder `data/raw`.
8. En el folder `scripts` encontrarás un script llamado `master.do`.
9. Para correr el código abre `master.do` y copia la ruta del repositorio clonado en la fila 21 (usuario 0).
10. Los outputs se guardarán en la carpeta `output` y las tablas finales se puede ver en [Google Sheets](https://docs.google.com/spreadsheets/d/1GHUOIn-mRkvh-w5rlBTjIUvWrSOHmztyB4JQupqlpZs/edit?usp=sharing)
