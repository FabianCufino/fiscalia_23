cas auto;

caslib _all_ assign;

filename hmeq url "https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/data/hmeq.csv" ;

proc import file= hmeq out=mycas.hmeq dbms=csv replace;
run;

proc casutil sessref=auto;
promote casdata="hmeq" incaslib="casuser" outcaslib="casuser";
run;


/*generamos analisis descriptivo*/
proc mdsummary data = casuser.hmeq;
  var _numeric_;
  output out=casuser.hmeq_summary;
run;


/* imputacion con proc varimpute*/
proc varimpute data=casuser.hmeq;
  input clage       / ctech = mean;
  input delinq      / ctech = median;
  input ninq        / ctech = value cvalues=2;
  input debtinc yoj / ctech = value cvalues=35.0, 7;
  output out=casuser.hmeq_impute COPYVARS=(_all_);
run;


/* imputación por modelo no supervisado*/
/* K prototypes = k means, mas variabels nominales*/
proc kclus data=CASUSER.HMEQ2 impute=mean standardize=range distance=euclidean 
		imputenom=mode distancenom=binary 
		noc=abc(minclusters=2 ) maxclusters=6
		/* genera resultados de cluster*/
		outstat=MYCAS.hmeq_cluster_statistic;
	input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / 
		level=interval;
	input REASON JOB bad / level=nominal;
	/* genera tabal Score (data mas asiganción de cluster)*/
	score out=mycas.hmeq_cluster_score copyvars=(LOAN MORTDUE VALUE YOJ DEROG 
		DELINQ CLAGE NINQ CLNO DEBTINC REASON JOB bad);
	ods output IterStats= hmeq_cluster_iterstats;
run;


/* graficamos dispersion entre Value y Loan*/
proc sgplot data=CASUSER.HMEQ_CLUSTER_SCORE;
	scatter x=Value y=LOAN / group=_CLUSTER_ID_ markerattrs=(size=5) 
		transparency=0.5;
	xaxis grid;
	yaxis grid;
run;



/* con los estadisticos de los cluster mas tabla scoreada, cruzamos y podemos imputar
 la variable missing con el valor medio (interval) o moda (nominal) del cluster asociado a la variable*/

/*nota el algorimto en SAS requiere imputación para tomar la observación*/
/* por lo que debe en este caso se suman los errores de imputacion inicial*/






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
proc import file= hmeq out=hmeq dbms=csv replace; run;

proc mi data=hmeq seed=13951639 nimpute=pctmissing(min=5 max=20) out=hmeq_mi;
FCS NBITER = 4 reg;
var YOJ DEROG VALUE CLAGE NINQ ;
run;
