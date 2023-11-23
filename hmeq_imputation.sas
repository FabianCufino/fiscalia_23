/*imputacion Multiple */

/* Procedimiento MI multiple imputation*/

/*El análisis comienza con datos observados, incompletos. 
La imputación múltiple crea varias versiones completas de los datos al reemplazar los valores faltantes por valores de datos plausibles. 
Estos valores plausibles se extraen de una distribución modelada específicamente para cada entrada faltante.*/

/*
El segundo paso es estimar los parámetros de interés de cada conjunto de datos imputado.

El último paso es juntar la m .Las estimaciones de los parámetros en una estimación,
 y para estimar su varianza.La varianza combina la varianza de muestreo convencional 
(varianza dentro de la imputación) y la varianza adicional causada por la varianza extra de los datos 
faltantes causada por los datos faltantes
 (varianza entre la imputación). Bajo las condiciones apropiadas, 
las estimaciones agrupadas son insesgadas y tienen las propiedades estadísticas correctas.
*/

/* reemplaza cada valor missing con valores plausible aleatorios (basado en distribución)
 o condicionado a las demas variables*/
*;

/* nimpute: numero de imputaciones(puede ser inferido por el algoritmo definiendo piso y tope)
/*fcs Metodo para variables continuas condicionadas*/
/* NBITER: numero de iteraciones, (donde cada valor imputado se multiplica por este valor*/
/* var variables del analisis*/


proc mi data=hmeq seed=13951639 nimpute=pctmissing(min=5 max=20) out=hmeq_mi;
FCS NBITER = 4 reg;
var YOJ DEROG VALUE CLAGE NINQ ;
run;
