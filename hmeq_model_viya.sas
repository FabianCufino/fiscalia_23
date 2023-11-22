/* inicio de sesion cas*/
cas casauto;
caslib _all_ assign;
/* generamos alias de libreria CAS por defecto CASUSER*/
libname mycas cas;

filename hmeq url 'https://raw.githubusercontent.com/FabianCufino/fiscalia_23/main/data/hmeq.csv'; 

/* definimos macrovariables transversales*/
%let indata = hmeq;
%let target          = bad;
%let class_inputs    = reason job;
%let class_vars      = &target &class_inputs;
%let interval_inputs = clage clno debtinc loan mortdue value yoj ninq derog delinq;
%let all_inputs      = &interval_inputs &class_inputs;


proc import file=hmeq out=mycas.hmeq dbms=csv replace;
run;

/* notese que el procedimiento mdsummary en viya es similar 
	en sintaxis como en proposito al procedimiento summary de 9.4*/
proc mdsummary data = mycas.&indata.;
  var _numeric_;
  output out=mycas.hmeq_summary;
run;
proc print data=mycas.hmeq_summary;
run;


ods graphics;
proc sgplot data = mycas.hmeq_summary;
  vbar _column_ / response=_nmiss_;
run;

/*procedimiento para imputación*/
proc varimpute data=mycas.&indata.;
  input clage       / ctech = mean;
  input delinq      / ctech = median;
  input ninq        / ctech = value cvalues=2;
  input debtinc yoj / ctech = value cvalues=35.0, 7;
  output out=mycas.hmeq_impute COPYVARS=(_all_);
run;

/* Algunos modelos pueden generar la partición dentro de su algoritmo,
	para desarrollo y comparación de varios modelos, puede ser eficiente
		computacionalmente, generar la particion al principio
			del proceso de modelado*/

%let part_data = hmeq_part;

ods noproctitle;

/* generamos particiones, por el momento train y test*/
proc partition data=MYCAS.HMEQ partind samppct=70;
	by BAD;
	output out=mycas.hmeq_partition;
run;


/* validamos la variable indicadora de la partición*/
	/* _PartInd_  = 0: Test, 1 = Train, 2 = Validation*/
proc freqtab data=mycas.hmeq_partition;
table _partind_;
run;


/* Modelos de arbol*/
ods noproctitle;
proc treesplit data=MYCAS.HMEQ_PARTITION maxdepth=10 numbin=20 maxbranch=2 
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
	code out= mycas.hmeq_tree1_score_code;
	score out=MYCAS.hmeq_tree1_score copyvars=(BAD LOAN MORTDUE VALUE YOJ DEROG 
		DELINQ CLAGE NINQ CLNO DEBTINC REASON JOB) ;
	ods output VariableImportance=WORK.hmeq_tree_var_imp Modelinfo=work.hmeq_tree1_ModelInfo 
				TreePerformance = work.hmeq_tree1_performance;
run;


/*modelo Random Forest*/


/* notese la estructura a nivel de sintaxis similar con Arboles*/
/* inbagfraction: especifica el porcentaje de data usada para cada arbol*/
/* vars_to_try: especifica la cantidad de variables independientes a usar en cada arbol
	por defecto toma la raiz cuadrada del numero de inputs*/



proc forest data=MYCAS.HMEQ_PARTITION maxdepth=10 inbagfraction=0.7 vars_to_try=3  seed=1234 
		numbin=20 vote=majority outmodel=mycas.hmeq_forest1_logic;
	partition role=_PartInd_ (test='0' train='1');
	target BAD / level=nominal;
	input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / 
		level=interval;
	input REASON JOB / level=nominal;
	grow entropy;
	ods output FitStatistics=Work._Forest_FitStats_ 
		VariableImportance=Work._Forest_VarImp_;
	score out=mycas.hmeq_forest1_scored copyvars=(BAD LOAN MORTDUE VALUE YOJ DEROG 
		DELINQ CLAGE NINQ CLNO DEBTINC REASON JOB);
	savestate rstore=mycas.hmeq_forest1_scoring_m;
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
