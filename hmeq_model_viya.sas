/* inicio de sesion cas*/
cas casauto;
caslib _all_ assign;
/* generamos alias de libreria CAS por defecto CASUSER*/


filename hmeq url 'https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/data/hmeq.csv'; 

/* definimos macrovariables transversales*/
%let indata = hmeq;
%let target          = bad;
%let class_inputs    = reason job;
%let class_vars      = &target &class_inputs;
%let interval_inputs = clage clno debtinc loan mortdue value yoj ninq derog delinq;
%let all_inputs      = &interval_inputs &class_inputs;

/*nota: proc import intenta adivinar el formato y tipo de cada variable,cuando se importa desde un plano*/
/*para un mayor control del proceso de importación se puede usar infile en data step*/
proc import file=hmeq out=casuser.hmeq dbms=csv replace;
run;



proc casutil;
	PROMOTE CASDATA="HMEQ" OUTCASLIB="CASUSER" INCASLIB="CASUSER";
run;
/* notese que el procedimiento mdsummary en viya es similar 
	en sintaxis como en proposito al procedimiento summary de 9.4*/
proc mdsummary data = casuser.hmeq;
  var _numeric_;

  output out=casuser.hmeq_summary;
run;
proc print data=casuser.hmeq_summary;
run;


ods graphics;
proc sgplot data = casuser.hmeq_summary;
  vbar _column_ / response=_nmiss_;
run;

/* Algunos modelos pueden generar la partición dentro de su algoritmo,
	para desarrollo y comparación de varios modelos, puede ser eficiente
		computacionalmente, generar la particion al principio
			del proceso de modelado*/

%let part_data = hmeq_part;

ods noproctitle;

/* generamos particiones, por el momento train y test*/
proc partition data=casuser.HMEQ partind samppct=70;
	by BAD;
	output out=casuser.hmeq_partition;
run;


/* validamos la variable indicadora de la partición*/
	/* _PartInd_  = 0: Test, 1 = Train, 2 = Validation*/
proc freqtab data=casuser.hmeq_partition;
table _partind_;
run;


/* Modelos de arbol*/

/* alternativamente se puede usar proc tree p proc hpsplit
	 como alternativa en 9.4 y según licencia
	o proc dtree para decision tree*/
ods noproctitle;
proc treesplit data=casuser.HMEQ_PARTITION  maxdepth=10 numbin=20 maxbranch=2 
		minleafsize=6 plots=all;
	partition role=_PartInd_ (test='0' train='1');
	input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / 
		level=interval;
	input REASON JOB / level=nominal;
	target BAD / level=nominal;
	grow igr;
	prune costcomplexity;
	/* nota seleccionar el path desde ruta home, o cualquier ruta de server*/
	*code comment file="/home/fabian.cufino@bitechco.com.co/treeselect_score.sas";
	code out= casuser.hmeq_tree1_score_code;
	score out=casuser.hmeq_tree1_score copyvars=(BAD LOAN MORTDUE VALUE YOJ DEROG 
		DELINQ CLAGE NINQ CLNO DEBTINC REASON JOB) ;
	ods output VariableImportance=WORK.hmeq_tree_var_imp Modelinfo=work.hmeq_tree1_ModelInfo 
				TreePerformance = work.hmeq_tree1_performance;
run;


/*modelo Random Forest*/


/* notese la estructura a nivel de sintaxis similar con Arboles*/
/* inbagfraction: especifica el porcentaje de data usada para cada arbol*/
/* vars_to_try: especifica la cantidad de variables independientes a usar en cada arbol
	por defecto toma la raiz cuadrada del numero de inputs*/



proc forest data=casuser.HMEQ_PARTITION ntrees=200 maxdepth=10 inbagfraction=0.7 vars_to_try=3  seed=1234 
		numbin=20 vote=majority outmodel=casuser.hmeq_forest1_logic;
	partition role=_PartInd_ (test='0' train='1');
	target BAD / level=nominal;
	input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / 
		level=interval;
	input REASON JOB / level=nominal;
	grow entropy;
	ods output FitStatistics=Work._Forest_FitStats_ 
		VariableImportance=Work._Forest_VarImp_;
	score out=casuser.hmeq_forest1_scored copyvars=(BAD LOAN MORTDUE VALUE YOJ DEROG 
		DELINQ CLAGE NINQ CLNO DEBTINC REASON JOB);
	savestate rstore=casuser.hmeq_forest1_scoring_m;
	id LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC REASON JOB;
run;



proc sgplot data=Work._Forest_FitStats_;
	title3 'Misclassifications by Number of Trees';
	title4 'Out-of-Bag vs. Training';
	series x=Trees y=MiscTrain;
	series x=Trees y=MiscOob /lineattrs=(pattern=shortdash thickness=2);
	yaxis label='Misclassification Rate';
	label Trees='Number of Trees';
	label MiscTrain='Training';
	label MiscOob='OOB';
run;

title3;

proc sgplot data=Work._Forest_VarImp_;
	title3 'Variable Importance';
	hbar variable / response=importance nostatlabel categoryorder=respdesc;
run;


/*modelo Forest con tunning de parametros/hiperparametros*/


ods noproctitle;



/*gradient bossting*/

/* 100 arboles son suficientes?*/
/*learning rate= tasa de aprendizaje*/
/* como grafico tasa misclasification rate para train y test al tiempo*/
/*subsamplerate =
La idea detrás de la subsample rate es introducir un elemento de aleatoriedad 
durante el entrenamiento de cada árbol, lo que puede ayudar a reducir el 
sobreajuste y mejorar la generalización del modelo.*/

proc gradboost data=casuser.HMEQ_PARTITION ntrees=100 seed=1234 
		subsamplerate=0.51 learningrate=0.11 outmodel=casuser.hmeq_gboost1_model;
	partition role=_PartInd_ (test='0' train='1');
	target BAD / level=nominal;
	input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / 
		level=interval;
	input REASON JOB / level=nominal;
	ods output FitStatistics=work.Gradboost_fit 
		VariableImportance=Work._Gradboost_VarImp_;
	savestate rstore=casuser.hmeq_gboost1_scoring;
	id LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC REASON JOB;
run;


proc sgplot data=work.Gradboost_fit;
	title3 'Misclassifications by Number of Trees';
	title4 'Training';
	series x=Trees y=MiscTrain;
	yaxis label='Misclassification Rate';
	label Trees='Number of Trees';
	label MiscTrain='Training';
run;

proc sgplot data=Work._Gradboost_VarImp_;
	title3 'Variable Importance';
	hbar variable / response=importance nostatlabel categoryorder=respdesc;
run;
