cas auto;

caslib _all_ assign;
libname mycas cas caslib="casuser";

filename hmeq url "https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/data/hmeq.csv" ;

proc import file= hmeq out=mycas.hmeq dbms=csv replace;
run;


/*generamos variable bad como nominal, para analisis no supervisado*/
data mycas.hmeq2 (drop=temp);
set mycas.hmeq(rename= (bad = temp));
bad = put(temp,2.);
run;

/*generamos analisis descriptivo*/
proc mdsummary data = mycas.hmeq2;
  var _numeric_;
  output out=mycas.hmeq_summary;
run;


/* imputacion con proc varimpute*/
proc varimpute data=mycas.hmeq2;
  input clage       / ctech = mean;
  input delinq      / ctech = median;
  input ninq        / ctech = value cvalues=2;
  input debtinc yoj / ctech = value cvalues=35.0, 7;
  output out=mycas.hmeq_impute COPYVARS=(_all_);
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


